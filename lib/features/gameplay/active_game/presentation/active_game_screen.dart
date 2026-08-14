import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:five_minus/features/gameplay/active_game/presentation/cubit/match_cubit.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/widgets/back_card_widget.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/widgets/front_card_widget.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/widgets/player_timer_widget.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_power.dart';
import 'package:five_minus/features/gameplay/model/active_game_params.dart';
import 'package:five_minus/features/gameplay/model/game_constants.dart';
import 'package:five_minus/features/gameplay/model/card_model.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:five_minus/resource/asset_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/component/template/screen_template_view.dart';
import '../../../../core/utility/loading_overlay_utility.dart';
import 'active_game_controller.dart';
import 'widgets/discard_pile_widget.dart';
import 'widgets/draw_card_flight.dart';
import 'widgets/game_overlay.dart';
import 'widgets/player_hands_widget.dart';

class ActiveGameScreen extends StatefulWidget {
  final ActiveGameController controller;
  final ActiveGameParams activeGameParams;
  const ActiveGameScreen({super.key, required this.controller, required this.activeGameParams});

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> {
  bool isLoading = false;
  bool isHost = false;
  StreamSubscription<GameModel?>? _gameSubscription;
  int? userIndex;
  Timer? _heartbeat;
  Timer? _reconnectCheck;
  bool _resultShown = false;

  /// Local-only opening peek of leftmost cards.
  Set<int> _peekedIndexes = {};
  bool _peekDone = false;

  /// Local queen reveal: playerIndex → handIndex.
  int? _queenRevealPlayer;
  int? _queenRevealIndex;

  /// Jack multi-select: "playerIndex:handIndex"
  final Set<String> _jackPicks = {};

  String? _statusMessage;

  final GlobalKey _discardPileKey = GlobalKey();
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _drawnSlotKey = GlobalKey();
  Offset _drawnCardDragAnchor = Offset.zero;
  bool _drawnCardOverPile = false;
  CardModel? _pendingDiscardCard;
  CardModel? _drawFlightCard;
  bool _drawFlightReveal = false;
  bool _sawGameState = false;
  bool _hadDrawnCard = false;

  CardModel? _eliminateFlightCard;
  int? _eliminatePlayerIndex;
  int? _eliminateHandIndex;
  bool _eliminateCardRemoved = false;
  bool _eliminateCollapsing = false;
  Timer? _eliminateCollapseTimer;
  final Map<String, GlobalKey> _handCardKeys = {};
  List<List<CardModel>> _lastHands = [];
  CardModel? _lastDrawnCard;

  CardModel? _replaceIncomingCard;
  CardModel? _replaceOutgoingCard;
  int? _replacePlayerIndex;
  int? _replaceHandIndex;
  CardFlightFace _replaceIncomingFace = CardFlightFace.hidden;
  bool _replaceAwaitingCommit = false;
  CardModel? _replaceFrozenPileTop;
  bool _replaceIncomingReady = false;
  bool _replaceOutgoingReady = false;
  bool _replaceHideDrawnSlot = false;
  Timer? _replaceDrawnHoldTimer;

  CardModel? _sabotageFlightCard;
  int? _sabotagePlayerIndex;
  int? _sabotageHandIndex;

  static const Size _drawnCardSize = Size(40, 60);
  static const double _drawnCardTilt = 0.18;

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _heartbeat?.cancel();
    _reconnectCheck?.cancel();
    _eliminateCollapseTimer?.cancel();
    _replaceDrawnHoldTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => isLoading = true);
      final matchCubit = context.read<MatchCubit>();

      await matchCubit.initalize(widget.activeGameParams.gameCode);
      isHost = matchCubit.isHost();

      if (!mounted) return;
      _gameSubscription = widget.controller.listenToChanges(context);
      userIndex = matchCubit.getUserIndex();

      _startOpeningPeek();
      _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
        matchCubit.heartbeat();
      });
      _reconnectCheck = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (matchCubit.opponentTimedOut() && !matchCubit.isMatchOver) {
          await matchCubit.forfeitWinForRemainingPlayer();
        }
      });

      setState(() => isLoading = false);
    });

    super.initState();
  }

  void _startOpeningPeek() {
    if (_peekDone || userIndex == null) return;
    setState(() {
      _peekedIndexes = {
        for (var i = 0; i < GameConstants.openingPeekCount; i++) i,
      };
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _peekedIndexes = {};
        _peekDone = true;
      });
    });
  }

  Offset _drawnCardAnchorStrategy(Draggable<Object> _, BuildContext context, Offset position) {
    final box = context.findRenderObject()! as RenderBox;
    _drawnCardDragAnchor = box.globalToLocal(position);
    return _drawnCardDragAnchor;
  }

  Rect _rotatedDrawnCardRect(Offset topLeft) {
    final center = topLeft + Offset(_drawnCardSize.width / 2, _drawnCardSize.height / 2);
    final hw = _drawnCardSize.width / 2;
    final hh = _drawnCardSize.height / 2;
    final cosA = math.cos(_drawnCardTilt);
    final sinA = math.sin(_drawnCardTilt);
    final corners = <Offset>[
      Offset(-hw, -hh),
      Offset(hw, -hh),
      Offset(hw, hh),
      Offset(-hw, hh),
    ];
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final corner in corners) {
      final rotated = Offset(
            corner.dx * cosA - corner.dy * sinA,
            corner.dx * sinA + corner.dy * cosA,
          ) +
          center;
      minX = math.min(minX, rotated.dx);
      minY = math.min(minY, rotated.dy);
      maxX = math.max(maxX, rotated.dx);
      maxY = math.max(maxY, rotated.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool _cardOverlapsDiscardPile(Offset cardTopLeft) {
    final pileBox = _discardPileKey.currentContext?.findRenderObject() as RenderBox?;
    if (pileBox == null || !pileBox.hasSize || !pileBox.attached) return false;

    final pileRect = pileBox.localToGlobal(Offset.zero) & pileBox.size;
    final cardRect = _rotatedDrawnCardRect(cardTopLeft);
    final center = pileRect.center;
    final radius = math.min(pileRect.width, pileRect.height) / 2;
    if (radius <= 0) return false;

    final closest = Offset(
      center.dx.clamp(cardRect.left, cardRect.right),
      center.dy.clamp(cardRect.top, cardRect.bottom),
    );
    return (closest - center).distance <= radius;
  }

  void _setDrawnCardOverPile(bool over) {
    if (_drawnCardOverPile == over) return;
    setState(() => _drawnCardOverPile = over);
  }

  void _onDrawnCardDragUpdate(DragUpdateDetails details) {
    _setDrawnCardOverPile(_cardOverlapsDiscardPile(details.globalPosition - _drawnCardDragAnchor));
  }

  void _onDrawnCardDragEnd(DraggableDetails details) {
    final over = _cardOverlapsDiscardPile(details.offset);
    if (over) {
      final card = context.read<MatchCubit>().state?.drawnCard;
      setState(() {
        _drawnCardOverPile = false;
        _pendingDiscardCard = card;
      });
      context.read<MatchCubit>().discardDrawnCard().whenComplete(() {
        if (mounted) setState(() => _pendingDiscardCard = null);
      });
      return;
    }
    _setDrawnCardOverPile(false);
  }

  HandInteractionMode _modeFor(MatchCubit cubit) {
    // Powers are only actionable on the active player's client.
    if (cubit.hasPendingPower && cubit.isMyTurn()) {
      final power = cubit.topDiscard?.cardPower;
      if (power == CardPower.look) return HandInteractionMode.queenLook;
      if (power == CardPower.swap) return HandInteractionMode.jackPick;
    }
    if (_replacePlayerIndex != null) return HandInteractionMode.none;
    // Single-tap = replace when a drawn card is pending. Eliminate is double-tap only.
    if (cubit.canDiscardOrReplace()) return HandInteractionMode.replace;
    return HandInteractionMode.none;
  }

  Future<void> _revealQueenLook(MatchCubit cubit, int playerIndex, int handIndex) async {
    setState(() {
      _queenRevealPlayer = playerIndex;
      _queenRevealIndex = handIndex;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _queenRevealPlayer = null;
      _queenRevealIndex = null;
    });
    await cubit.resolveQueenLook(handIndex: handIndex);
  }

  Future<void> _onOwnCardTap(MatchCubit cubit, int handIndex) async {
    final mode = _modeFor(cubit);
    if (mode == HandInteractionMode.queenLook) {
      await _revealQueenLook(cubit, userIndex!, handIndex);
      return;
    }
    if (mode == HandInteractionMode.replace) {
      await _startReplaceFlight(cubit, userIndex!, handIndex, concealIncoming: true);
      return;
    }
    if (mode == HandInteractionMode.jackPick) {
      _toggleJackPick(userIndex!, handIndex, cubit);
    }
  }

  GlobalKey _handCardKey(int playerIndex, int handIndex) {
    return _handCardKeys.putIfAbsent('$playerIndex:$handIndex', GlobalKey.new);
  }

  Future<void> _onOwnCardDoubleTap(MatchCubit cubit, int handIndex) async {
    if (!cubit.canEliminate() || _eliminatePlayerIndex != null || _replacePlayerIndex != null) return;
    final me = userIndex;
    if (me == null) return;
    final card = cubit.state?.players[me].playerHand?[handIndex];
    if (card == null) return;

    setState(() {
      _eliminateFlightCard = card;
      _eliminatePlayerIndex = me;
      _eliminateHandIndex = handIndex;
      _eliminateCardRemoved = false;
      _eliminateCollapsing = false;
    });

    final err = await cubit.eliminateCard(handIndex);
    if (!mounted) return;
    if (err != null) {
      _clearEliminateFlight(statusMessage: err);
      return;
    }
    if (_eliminateFlightCard != null) {
      setState(() {
        _eliminateCardRemoved = true;
        _statusMessage = null;
      });
    }
  }

  Future<void> _onOpponentCardTap(MatchCubit cubit, int handIndex) async {
    final mode = _modeFor(cubit);
    final opp = userIndex == 0 ? 1 : 0;
    if (mode == HandInteractionMode.queenLook) {
      await _revealQueenLook(cubit, opp, handIndex);
      return;
    }
    if (mode == HandInteractionMode.jackPick) {
      _toggleJackPick(opp, handIndex, cubit);
    }
  }

  Future<void> _toggleJackPick(int playerIndex, int handIndex, MatchCubit cubit) async {
    final key = '$playerIndex:$handIndex';
    setState(() {
      if (_jackPicks.contains(key)) {
        _jackPicks.remove(key);
      } else {
        if (_jackPicks.length >= 2) _jackPicks.clear();
        _jackPicks.add(key);
      }
    });
    if (_jackPicks.length == 2) {
      final parts = _jackPicks.map((e) => e.split(':')).toList();
      await cubit.resolveJackSwap(
        playerIndexA: int.parse(parts[0][0]),
        handIndexA: int.parse(parts[0][1]),
        playerIndexB: int.parse(parts[1][0]),
        handIndexB: int.parse(parts[1][1]),
      );
      setState(() => _jackPicks.clear());
    }
  }

  void _maybeStartDrawFlight(MatchCubit cubit, GameModel? state) {
    if (state == null) return;
    if (!_sawGameState) {
      _sawGameState = true;
      _hadDrawnCard = state.drawnCard != null;
      _lastDrawnCard = state.drawnCard;
      _lastHands = _handsOf(state);
      return;
    }
    final hasDrawn = state.drawnCard != null;
    if (!_hadDrawnCard && hasDrawn && _drawFlightCard == null) {
      setState(() {
        _drawFlightCard = state.drawnCard;
        _drawFlightReveal = cubit.isMyTurn();
      });
    }
    _maybeStartEliminateFlight(state);
    _maybeStartReplaceFlight(state);
    _maybeStartSabotageFlight(state);
    _hadDrawnCard = hasDrawn;
    if (state.drawnCard != null) _lastDrawnCard = state.drawnCard;
    _lastHands = _handsOf(state);
  }

  List<List<CardModel>> _handsOf(GameModel state) {
    return [
      for (final player in state.players) List<CardModel>.from(player.playerHand ?? const []),
    ];
  }

  int? _removedHandIndex(List<CardModel> previous, List<CardModel> next) {
    if (next.length != previous.length - 1) return null;
    for (var i = 0; i < previous.length; i++) {
      var j = 0;
      var matches = true;
      for (var k = 0; k < previous.length; k++) {
        if (k == i) continue;
        if (j >= next.length || previous[k] != next[j]) {
          matches = false;
          break;
        }
        j++;
      }
      if (matches) return i;
    }
    return 0;
  }

  void _maybeStartEliminateFlight(GameModel state) {
    if (_eliminatePlayerIndex != null || _replacePlayerIndex != null) return;
    final previousHands = _lastHands;
    if (previousHands.length != state.players.length) return;
    for (var i = 0; i < state.players.length; i++) {
      final previous = previousHands[i];
      final next = state.players[i].playerHand ?? const <CardModel>[];
      final index = _removedHandIndex(previous, next);
      if (index == null) continue;
      setState(() {
        _eliminateFlightCard = previous[index];
        _eliminatePlayerIndex = i;
        _eliminateHandIndex = index;
        _eliminateCardRemoved = true;
      });
      return;
    }
  }

  int? _addedHandIndex(List<CardModel> previous, List<CardModel> next) {
    if (next.length != previous.length + 1) return null;
    for (var i = 0; i < next.length; i++) {
      var j = 0;
      var matches = true;
      for (var k = 0; k < next.length; k++) {
        if (k == i) continue;
        if (j >= previous.length || next[k] != previous[j]) {
          matches = false;
          break;
        }
        j++;
      }
      if (matches) return i;
    }
    return 0;
  }

  void _maybeStartSabotageFlight(GameModel state) {
    if (_sabotagePlayerIndex != null) return;
    final pile = state.discardDeck?.cardDeck;
    if (pile == null || pile.isEmpty || pile.last.cardPower != CardPower.sabotage) return;
    final previousHands = _lastHands;
    if (previousHands.length != state.players.length) return;
    for (var i = 0; i < state.players.length; i++) {
      final previous = previousHands[i];
      final next = state.players[i].playerHand ?? const <CardModel>[];
      final index = _addedHandIndex(previous, next);
      if (index == null) continue;
      setState(() {
        _sabotageFlightCard = next[index];
        _sabotagePlayerIndex = i;
        _sabotageHandIndex = index;
      });
      return;
    }
  }

  int? _replacedHandIndex(List<CardModel> previous, List<CardModel> next) {
    if (previous.length != next.length) return null;
    int? replaced;
    for (var i = 0; i < previous.length; i++) {
      if (previous[i] != next[i]) {
        if (replaced != null) return null;
        replaced = i;
      }
    }
    return replaced;
  }

  void _maybeStartReplaceFlight(GameModel state) {
    if (_replacePlayerIndex != null || _eliminatePlayerIndex != null) return;
    if (!_hadDrawnCard || state.drawnCard != null) return;
    final previousDrawn = _lastDrawnCard;
    if (previousDrawn == null) return;
    final previousHands = _lastHands;
    if (previousHands.length != state.players.length) return;
    for (var i = 0; i < state.players.length; i++) {
      final previous = previousHands[i];
      final next = state.players[i].playerHand ?? const <CardModel>[];
      final index = _replacedHandIndex(previous, next);
      if (index == null) continue;
      final pile = state.discardDeck?.cardDeck ?? const <CardModel>[];
      _beginReplaceFlight(
        incoming: previousDrawn,
        outgoing: previous[index],
        playerIndex: i,
        handIndex: index,
        incomingFace: i == userIndex ? CardFlightFace.conceal : CardFlightFace.hidden,
        frozenPileTop: pile.length >= 2 ? pile[pile.length - 2] : null,
      );
      return;
    }
  }

  Future<void> _startReplaceFlight(
    MatchCubit cubit,
    int playerIndex,
    int handIndex, {
    required bool concealIncoming,
  }) async {
    if (_replacePlayerIndex != null || _eliminatePlayerIndex != null) return;
    final incoming = cubit.state?.drawnCard;
    final outgoing = cubit.state?.players[playerIndex].playerHand?[handIndex];
    if (incoming == null || outgoing == null) return;

    final pile = cubit.state?.discardDeck?.cardDeck ?? const <CardModel>[];
    _beginReplaceFlight(
      incoming: incoming,
      outgoing: outgoing,
      playerIndex: playerIndex,
      handIndex: handIndex,
      incomingFace: concealIncoming ? CardFlightFace.conceal : CardFlightFace.hidden,
      awaitingCommit: true,
      frozenPileTop: pile.isNotEmpty ? pile.last : null,
    );

    try {
      await cubit.replaceHandCard(handIndex);
      if (!mounted) return;
      setState(() {
        _statusMessage = null;
        _replaceAwaitingCommit = false;
      });
      _maybeClearReplaceFlight();
    } catch (_) {
      if (mounted) _clearReplaceFlight();
    }
  }

  void _beginReplaceFlight({
    required CardModel incoming,
    required CardModel outgoing,
    required int playerIndex,
    required int handIndex,
    required CardFlightFace incomingFace,
    bool awaitingCommit = false,
    CardModel? frozenPileTop,
  }) {
    setState(() {
      _replaceIncomingCard = incoming;
      _replaceOutgoingCard = outgoing;
      _replacePlayerIndex = playerIndex;
      _replaceHandIndex = handIndex;
      _replaceIncomingFace = incomingFace;
      _replaceAwaitingCommit = awaitingCommit;
      _replaceFrozenPileTop = frozenPileTop;
      _replaceIncomingReady = false;
      _replaceOutgoingReady = false;
      _replaceHideDrawnSlot = false;
    });
    _replaceDrawnHoldTimer?.cancel();
    _replaceDrawnHoldTimer = null;
  }

  void _onReplaceIncomingCompleted() {
    if (!mounted) return;
    setState(() => _replaceIncomingCard = null);
    _maybeClearReplaceFlight();
  }

  void _onReplaceOutgoingCompleted() {
    if (!mounted) return;
    setState(() => _replaceOutgoingCard = null);
    _maybeClearReplaceFlight();
  }

  void _maybeClearReplaceFlight() {
    if (_replaceIncomingCard != null || _replaceOutgoingCard != null) return;
    if (_replaceAwaitingCommit) return;
    _clearReplaceFlight();
  }

  void _clearReplaceFlight() {
    _replaceDrawnHoldTimer?.cancel();
    _replaceDrawnHoldTimer = null;
    setState(() {
      _replaceIncomingCard = null;
      _replaceOutgoingCard = null;
      _replacePlayerIndex = null;
      _replaceHandIndex = null;
      _replaceIncomingFace = CardFlightFace.hidden;
      _replaceAwaitingCommit = false;
      _replaceFrozenPileTop = null;
      _replaceIncomingReady = false;
      _replaceOutgoingReady = false;
      _replaceHideDrawnSlot = false;
    });
  }

  int? _hollowIndexFor(int playerIndex) {
    if (_eliminatePlayerIndex == playerIndex) return _eliminateHandIndex;
    if (_sabotagePlayerIndex == playerIndex && _sabotageFlightCard != null) {
      return _sabotageHandIndex;
    }
    if (_replacePlayerIndex == playerIndex &&
        (_replaceIncomingCard != null || _replaceAwaitingCommit) &&
        (_replaceIncomingReady || _replaceOutgoingReady)) {
      return _replaceHandIndex;
    }
    return null;
  }

  void _onReplaceIncomingStarted() {
    if (!mounted || _replaceIncomingReady) return;
    setState(() => _replaceIncomingReady = true);
    _replaceDrawnHoldTimer?.cancel();
    _replaceDrawnHoldTimer = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => _replaceHideDrawnSlot = true);
    });
  }

  void _onReplaceOutgoingStarted() {
    if (!mounted || _replaceOutgoingReady) return;
    setState(() => _replaceOutgoingReady = true);
  }

  Widget _drawnSlotContents(MatchCubit cubit, GameModel? state) {
    if (_pendingDiscardCard != null || _drawFlightCard != null) {
      return const SizedBox(width: 40, height: 60);
    }
    final live = state?.drawnCard;
    final held = !_replaceHideDrawnSlot ? _replaceIncomingCard : null;
    final card = live ?? held;
    if (card == null) return const SizedBox(width: 40, height: 60);

    if (live != null && cubit.canDiscardOrReplace()) {
      return Draggable<CardModel>(
        data: live,
        dragAnchorStrategy: _drawnCardAnchorStrategy,
        onDragUpdate: _onDrawnCardDragUpdate,
        onDragEnd: _onDrawnCardDragEnd,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.rotate(
            angle: _drawnCardTilt,
            child: FrontCard(cardModel: live),
          ),
        ),
        childWhenDragging: const SizedBox(width: 40, height: 60),
        child: FrontCard(cardModel: live),
      );
    }
    if (cubit.isMyTurn()) return FrontCard(cardModel: card);
    return BackCard(cardModel: card);
  }

  void _onDrawFlightCompleted() {
    if (!mounted) return;
    setState(() => _drawFlightCard = null);
  }

  void _onSabotageFlightCompleted() {
    if (!mounted) return;
    setState(() {
      _sabotageFlightCard = null;
      _sabotagePlayerIndex = null;
      _sabotageHandIndex = null;
    });
  }

  void _onEliminateFlightCompleted() {
    if (!mounted) return;
    if (!_eliminateCardRemoved || _eliminateHandIndex == null) {
      _clearEliminateFlight();
      return;
    }
    setState(() {
      _eliminateFlightCard = null;
      _eliminateCollapsing = true;
    });
    _eliminateCollapseTimer?.cancel();
    _eliminateCollapseTimer = Timer(PlayerHands.collapseDuration, () {
      if (!mounted) return;
      _clearEliminateFlight();
    });
  }

  void _clearEliminateFlight({String? statusMessage}) {
    _eliminateCollapseTimer?.cancel();
    _eliminateCollapseTimer = null;
    setState(() {
      _eliminateFlightCard = null;
      _eliminatePlayerIndex = null;
      _eliminateHandIndex = null;
      _eliminateCardRemoved = false;
      _eliminateCollapsing = false;
      if (statusMessage != null) _statusMessage = statusMessage;
    });
  }

  void _maybeShowResult(MatchCubit cubit) {
    if (!cubit.isMatchOver || _resultShown || !mounted) return;
    _resultShown = true;
    final isDraw = cubit.isDraw;
    final iWon = !isDraw && cubit.state?.winner?.playerId == cubit.state?.players[userIndex ?? 0].playerId;
    final title = isDraw ? 'Draw' : (iWon ? 'You win!' : 'You lose');
    final explanation = cubit.resultExplanation(iWon: iWon, isDraw: isDraw);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(explanation),
          contentTextStyle: const TextStyle(color: Colors.black, fontSize: 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.controller.navigateDashboard(context);
              },
              child: const Text('Back to dashboard'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchCubit, GameModel?>(
      listener: (context, state) {
        final matchCubit = context.read<MatchCubit>();
        _maybeShowResult(matchCubit);
        _maybeStartDrawFlight(matchCubit, state);
      },
      builder: (context, state) {
        final matchCubit = context.read<MatchCubit>();
        final mode = _modeFor(matchCubit);
        final oppIndex = userIndex == null ? null : (userIndex == 0 ? 1 : 0);

        return ScreenTemplateView(
          suffixActionList: [
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: IconButton(
                iconSize: 35,
                onPressed: () async {
                  LoadingOverlay().show(context);
                  await matchCubit.forfeitAndLeave();
                  LoadingOverlay().hide();
                  if (!context.mounted) return;
                  widget.controller.navigateDashboard(context);
                },
                icon: const Icon(Icons.cancel_outlined),
              ),
            )
          ],
          layout: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_statusMessage != null)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(_statusMessage!, style: const TextStyle(color: Colors.orangeAccent)),
                            ),
                          if (matchCubit.hasPendingPower && matchCubit.isMyTurn())
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                powerHint(matchCubit.topDiscard?.cardPower ?? CardPower.none),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          Expanded(
                            child: userIndex == null || ((state?.players.length ?? 0) <= 1) || oppIndex == null
                                ? const SizedBox.expand()
                                : Transform.flip(
                                    child: PlayerView(
                                      userIndex: oppIndex,
                                      matchCubit: matchCubit,
                                      isOpponent: true,
                                      mode: mode,
                                      revealedIndexes: {
                                        if (_queenRevealPlayer == oppIndex && _queenRevealIndex != null) _queenRevealIndex!,
                                      },
                                      jackSelected: _jackPicks,
                                      onCardTap: (i) => _onOpponentCardTap(matchCubit, i),
                                      onChallenge: null,
                                      onEndTurn: null,
                                      cardKeyFor: (i) => _handCardKey(oppIndex, i),
                                      hollowIndex: _hollowIndexFor(oppIndex),
                                      hollowIsExtra: _eliminatePlayerIndex == oppIndex && _eliminateCardRemoved,
                                      hollowCollapsing: _eliminatePlayerIndex == oppIndex && _eliminateCollapsing,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SizedBox(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: KeyedSubtree(
                                        key: _deckKey,
                                        child: (state?.drawDeck?.cardDeck?.isNotEmpty ?? false)
                                            ? UnconstrainedBox(
                                                child: SizedBox(
                                                  height: 80,
                                                  child: Image.asset(AssetPath.drawDeck5Plus, fit: BoxFit.contain),
                                                ),
                                              )
                                            : const SizedBox.expand(),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: KeyedSubtree(
                                          key: _drawnSlotKey,
                                          child: _drawnSlotContents(matchCubit, state),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: DiscardPile(
                                        key: _discardPileKey,
                                        highlighted: _drawnCardOverPile,
                                        pendingTopCard: _pendingDiscardCard,
                                        lockTop: _replaceOutgoingCard != null,
                                        lockedTopCard: _replaceFrozenPileTop,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: userIndex == null
                                ? const SizedBox.expand()
                                : PlayerView(
                                    userIndex: userIndex,
                                    matchCubit: matchCubit,
                                    isOpponent: false,
                                    mode: mode,
                                    revealedIndexes: {
                                      ..._peekedIndexes,
                                      if (_queenRevealPlayer == userIndex && _queenRevealIndex != null) _queenRevealIndex!,
                                    },
                                    jackSelected: _jackPicks,
                                    onCardTap: (i) => _onOwnCardTap(matchCubit, i),
                                    onCardDoubleTap: matchCubit.canEliminate() && _eliminatePlayerIndex == null && _replacePlayerIndex == null
                                        ? (i) => _onOwnCardDoubleTap(matchCubit, i)
                                        : null,
                                    onChallenge: matchCubit.canChallenge() ? () => matchCubit.declareChallenge() : null,
                                    onEndTurn: matchCubit.canEndTurn() ? () => matchCubit.endTurn() : null,
                                    cardKeyFor: (i) => _handCardKey(userIndex!, i),
                                    hollowIndex: _hollowIndexFor(userIndex!),
                                    hollowIsExtra: _eliminatePlayerIndex == userIndex && _eliminateCardRemoved,
                                    hollowCollapsing: _eliminatePlayerIndex == userIndex && _eliminateCollapsing,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned.fill(child: GameOverlay()),
                    if (_drawFlightCard != null)
                      Positioned.fill(
                        key: const ValueKey('draw-flight'),
                        child: DrawCardFlight(
                          card: _drawFlightCard!,
                          face: _drawFlightReveal ? CardFlightFace.reveal : CardFlightFace.hidden,
                          sourceKey: _deckKey,
                          destKey: _drawnSlotKey,
                          onCompleted: _onDrawFlightCompleted,
                        ),
                      ),
                    if (_eliminateFlightCard != null && _eliminatePlayerIndex != null && _eliminateHandIndex != null)
                      Positioned.fill(
                        key: const ValueKey('eliminate-flight'),
                        child: DrawCardFlight(
                          card: _eliminateFlightCard!,
                          face: CardFlightFace.reveal,
                          sourceKey: _handCardKey(_eliminatePlayerIndex!, _eliminateHandIndex!),
                          destKey: _discardPileKey,
                          holdAfter: const Duration(milliseconds: 1000),
                          onCompleted: _onEliminateFlightCompleted,
                        ),
                      ),
                    if (_replaceIncomingCard != null && _replacePlayerIndex != null && _replaceHandIndex != null)
                      Positioned.fill(
                        key: const ValueKey('replace-incoming-flight'),
                        child: DrawCardFlight(
                          card: _replaceIncomingCard!,
                          face: _replaceIncomingFace,
                          sourceKey: _drawnSlotKey,
                          destKey: _handCardKey(_replacePlayerIndex!, _replaceHandIndex!),
                          arcHeight: 0,
                          flipAtEnd: true,
                          onStarted: _onReplaceIncomingStarted,
                          onCompleted: _onReplaceIncomingCompleted,
                        ),
                      ),
                    if (_replaceOutgoingCard != null && _replacePlayerIndex != null && _replaceHandIndex != null)
                      Positioned.fill(
                        key: const ValueKey('replace-outgoing-flight'),
                        child: DrawCardFlight(
                          card: _replaceOutgoingCard!,
                          face: CardFlightFace.reveal,
                          sourceKey: _handCardKey(_replacePlayerIndex!, _replaceHandIndex!),
                          destKey: _discardPileKey,
                          holdAfter: const Duration(milliseconds: 1000),
                          onStarted: _onReplaceOutgoingStarted,
                          onCompleted: _onReplaceOutgoingCompleted,
                        ),
                      ),
                    if (_sabotageFlightCard != null && _sabotagePlayerIndex != null && _sabotageHandIndex != null)
                      Positioned.fill(
                        key: const ValueKey('sabotage-flight'),
                        child: DrawCardFlight(
                          card: _sabotageFlightCard!,
                          face: CardFlightFace.hidden,
                          sourceKey: _deckKey,
                          destKey: _handCardKey(_sabotagePlayerIndex!, _sabotageHandIndex!),
                          onCompleted: _onSabotageFlightCompleted,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.userIndex,
    required this.matchCubit,
    required this.isOpponent,
    required this.mode,
    required this.revealedIndexes,
    this.jackSelected,
    this.onCardTap,
    this.onCardDoubleTap,
    this.onChallenge,
    this.onEndTurn,
    this.cardKeyFor,
    this.hollowIndex,
    this.hollowIsExtra = false,
    this.hollowCollapsing = false,
  });

  final int? userIndex;
  final MatchCubit matchCubit;
  final bool isOpponent;
  final HandInteractionMode mode;
  final Set<int> revealedIndexes;
  final Set<String>? jackSelected;
  final void Function(int handIndex)? onCardTap;
  final void Function(int handIndex)? onCardDoubleTap;
  final VoidCallback? onChallenge;
  final VoidCallback? onEndTurn;
  final GlobalKey Function(int handIndex)? cardKeyFor;
  final int? hollowIndex;
  final bool hollowIsExtra;
  final bool hollowCollapsing;

  @override
  Widget build(BuildContext context) {
    final penalties = userIndex == null ? 0 : matchCubit.state?.players[userIndex!].penaltyCount ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOpponent)
                  ElevatedButton(
                    onPressed: onChallenge,
                    child: const Text('Challenge'),
                  ),
                if (!isOpponent && onEndTurn != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onEndTurn,
                    child: const Text('End turn'),
                  ),
                ],
                if (!isOpponent)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Penalties: $penalties/${GameConstants.maxPenalties}'),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.center,
            child: PlayerHands(
              playerIndex: userIndex!,
              isOpponent: isOpponent,
              mode: mode,
              revealedIndexes: revealedIndexes,
              jackSelected: jackSelected,
              onCardTap: onCardTap,
              onCardDoubleTap: onCardDoubleTap,
              cardKeyFor: cardKeyFor,
              hollowIndex: hollowIndex,
              hollowIsExtra: hollowIsExtra,
              hollowCollapsing: hollowCollapsing,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Image.memory(
                  base64Decode(matchCubit.state?.players[userIndex!].loadedPlayer?.icon ?? ''),
                  width: 60,
                  height: 60,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40),
                ),
              ),
              PlayerTimer(userIndex: userIndex),
            ],
          ),
        ),
      ],
    );
  }
}
