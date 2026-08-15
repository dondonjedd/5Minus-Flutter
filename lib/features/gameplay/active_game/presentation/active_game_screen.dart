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

enum _EliminatePhase { hover, commit, returning, rearranging, penalty, collapsing }

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

  Timer? _peekTimer;

  /// Local queen reveal: playerIndex → handIndex.
  int? _queenRevealPlayer;
  int? _queenRevealIndex;

  /// Jack multi-select: "playerIndex:handIndex"
  final Set<String> _jackPicks = {};

  String? _statusMessage;

  final GlobalKey _discardPileKey = GlobalKey();
  final GlobalKey _eliminateHoverKey = GlobalKey();
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
  _EliminatePhase _eliminatePhase = _EliminatePhase.hover;
  bool _eliminateFailed = false;
  bool _eliminateMatchOver = false;
  bool _eliminateHoverReady = false;
  bool _eliminateResultReady = false;
  bool _eliminateFollowUpStarted = false;
  bool _eliminateCardRemoved = false;
  bool _eliminateCollapsing = false;
  bool _eliminateAllowResult = false;
  DateTime? _eliminateHoverArrivedAt;
  Timer? _eliminateHoldTimer;
  Timer? _eliminateCollapseTimer;
  String? _eliminateNotice;
  String? _lastEliminateToken;
  CardModel? _eliminatePenaltyCard;
  int? _eliminatePenaltyIndex;
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

  CardModel? _swapCardA;
  CardModel? _swapCardB;
  int? _swapPlayerA;
  int? _swapPlayerB;
  int? _swapIndexA;
  int? _swapIndexB;
  bool _swapAwaitingCommit = false;

  static const Size _drawnCardSize = Size(40, 60);
  static const double _drawnCardTilt = 0.18;

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _heartbeat?.cancel();
    _reconnectCheck?.cancel();
    _peekTimer?.cancel();
    _eliminateCollapseTimer?.cancel();
    _eliminateHoldTimer?.cancel();
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

      _syncPeekTimer(matchCubit.state);
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

  void _syncPeekTimer(GameModel? state) {
    if (state == null || !state.isPeekOpen) {
      _peekTimer?.cancel();
      _peekTimer = null;
      return;
    }
    if (_peekTimer != null) return;
    _peekTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onPeekTick());
    _onPeekTick();
  }

  void _onPeekTick() {
    if (!mounted) return;
    final cubit = context.read<MatchCubit>();
    final game = cubit.state;
    if (game == null || !game.isPeekOpen) {
      _peekTimer?.cancel();
      _peekTimer = null;
      setState(() {});
      return;
    }
    if (game.peekSecondsRemaining() <= 0) {
      _peekTimer?.cancel();
      _peekTimer = null;
      unawaited(cubit.readyPeek());
    }
    setState(() {});
  }

  Set<int> _openingPeekIndexes(MatchCubit cubit) {
    final game = cubit.state;
    if (game == null || !game.isPeekOpen || userIndex == null) return {};
    if (userIndex! < 0 || userIndex! >= game.players.length) return {};
    if (game.players[userIndex!].peekReady) return {};
    return {for (var i = 0; i < GameConstants.openingPeekCount; i++) i};
  }

  Widget _peekReadyControl(MatchCubit cubit, GameModel state) {
    final seconds = state.peekSecondsRemaining();
    final meReady = userIndex != null && userIndex! < state.players.length && state.players[userIndex!].peekReady;
    return ElevatedButton(
      onPressed: meReady ? null : () => cubit.readyPeek(),
      child: Text(meReady ? 'Waiting… $seconds' : 'Ready $seconds'),
    );
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
    if (_swapPlayerA != null || _replacePlayerIndex != null) return HandInteractionMode.none;
    // Powers are only actionable on the active player's client.
    if (cubit.hasPendingPower && cubit.isMyTurn()) {
      final power = cubit.topDiscard?.cardPower;
      if (power == CardPower.look) return HandInteractionMode.queenLook;
      if (power == CardPower.swap) return HandInteractionMode.jackPick;
    }
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
    if (!cubit.canEliminate() || _eliminatePlayerIndex != null || _replacePlayerIndex != null || _swapPlayerA != null) {
      return;
    }
    final me = userIndex;
    if (me == null) return;
    final card = cubit.state?.players[me].playerHand?[handIndex];
    if (card == null) return;

    _beginEliminateHover(card: card, playerIndex: me, handIndex: handIndex);

    final err = await cubit.eliminateCard(handIndex);
    if (!mounted) return;
    final ev = cubit.state?.lastEliminate;
    final penalty = ev != null && ev.failed ? _penaltyFrom(cubit.state, me) : (card: null, index: null);
    _applyEliminateResult(
      failed: ev?.failed ?? err != null,
      matchOver: ev?.matchOver ?? cubit.isMatchOver,
      notice: err,
      penaltyCard: penalty.card,
      penaltyIndex: penalty.index,
    );
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
      final playerA = int.parse(parts[0][0]);
      final indexA = int.parse(parts[0][1]);
      final playerB = int.parse(parts[1][0]);
      final indexB = int.parse(parts[1][1]);
      final cardA = cubit.state?.players[playerA].playerHand?[indexA];
      final cardB = cubit.state?.players[playerB].playerHand?[indexB];
      if (cardA == null || cardB == null) {
        setState(() => _jackPicks.clear());
        return;
      }
      _beginSwapFlight(
        playerA: playerA,
        indexA: indexA,
        cardA: cardA,
        playerB: playerB,
        indexB: indexB,
        cardB: cardB,
        awaitingCommit: true,
      );
      try {
        await cubit.resolveJackSwap(
          playerIndexA: playerA,
          handIndexA: indexA,
          playerIndexB: playerB,
          handIndexB: indexB,
        );
        if (!mounted) return;
        setState(() => _swapAwaitingCommit = false);
        _maybeClearSwapFlight();
      } catch (_) {
        if (mounted) _clearSwapFlight();
      }
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
    _maybeStartSwapFlight(state);
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

  static const _wrongRankNotice = 'Wrong rank - elimination locked until your next turn';

  bool get _showEliminateHoverFlight {
    if (_eliminateFlightCard == null || _eliminatePlayerIndex == null || _eliminateHandIndex == null) {
      return false;
    }
    if (_eliminatePhase == _EliminatePhase.hover) return true;
    if (_eliminateFollowUpStarted) return false;
    return _eliminatePhase == _EliminatePhase.commit || _eliminatePhase == _EliminatePhase.returning;
  }

  ({CardModel? card, int? index}) _penaltyFrom(GameModel? state, int playerIndex) {
    if (state == null || playerIndex < 0 || playerIndex >= state.players.length) {
      return (card: null, index: null);
    }
    final hand = state.players[playerIndex].playerHand ?? const <CardModel>[];
    if (hand.isEmpty) return (card: null, index: null);
    return (card: hand.last, index: hand.length - 1);
  }

  void _beginEliminateHover({
    required CardModel card,
    required int playerIndex,
    required int handIndex,
  }) {
    _eliminateHoldTimer?.cancel();
    _eliminateHoldTimer = null;
    setState(() {
      _eliminateFlightCard = card;
      _eliminatePlayerIndex = playerIndex;
      _eliminateHandIndex = handIndex;
      _eliminatePhase = _EliminatePhase.hover;
      _eliminateFailed = false;
      _eliminateMatchOver = false;
      _eliminateHoverReady = false;
      _eliminateResultReady = false;
      _eliminateFollowUpStarted = false;
      _eliminateCardRemoved = false;
      _eliminateCollapsing = false;
      _eliminateAllowResult = false;
      _eliminateHoverArrivedAt = null;
      _eliminateNotice = null;
      _eliminatePenaltyCard = null;
      _eliminatePenaltyIndex = null;
    });
  }

  void _applyEliminateResult({
    required bool failed,
    required bool matchOver,
    String? notice,
    CardModel? penaltyCard,
    int? penaltyIndex,
  }) {
    if (!mounted) return;
    if (_eliminateResultReady && _eliminateFailed == failed && _eliminateMatchOver == matchOver) {
      return;
    }
    setState(() {
      _eliminateFailed = failed;
      _eliminateMatchOver = matchOver;
      _eliminateResultReady = true;
      _eliminateNotice = notice;
      if (failed) {
        _eliminatePenaltyIndex = penaltyIndex;
        _eliminatePenaltyCard = penaltyCard;
      } else {
        _eliminateCardRemoved = true;
      }
    });
    _maybeBranchEliminate();
  }

  void _maybeStartEliminateFlight(GameModel state) {
    if (_replacePlayerIndex != null) return;
    final ev = state.lastEliminate;
    if (ev == null) {
      _lastEliminateToken = null;
      if (_eliminatePlayerIndex != null) return;
      final previousHands = _lastHands;
      if (previousHands.length != state.players.length) return;
      for (var i = 0; i < state.players.length; i++) {
        final previous = previousHands[i];
        final next = state.players[i].playerHand ?? const <CardModel>[];
        final index = _removedHandIndex(previous, next);
        if (index == null) continue;
        _beginEliminateHover(card: previous[index], playerIndex: i, handIndex: index);
        _applyEliminateResult(failed: false, matchOver: state.status == 'finished');
        return;
      }
      return;
    }

    final token = '${ev.seat}:${ev.handIndex}:${ev.failed}:${ev.matchOver}';
    if (token == _lastEliminateToken) return;
    _lastEliminateToken = token;

    final playerIndex = state.players.indexWhere((p) => p.seat == ev.seat);
    if (playerIndex < 0) return;
    final penalty = ev.failed ? _penaltyFrom(state, playerIndex) : (card: null, index: null);

    if (_eliminatePlayerIndex != null) {
      _applyEliminateResult(
        failed: ev.failed,
        matchOver: ev.matchOver,
        notice: ev.failed ? (_eliminateNotice ?? _wrongRankNotice) : null,
        penaltyCard: penalty.card,
        penaltyIndex: penalty.index,
      );
      return;
    }

    CardModel? card;
    if (ev.failed) {
      final hand = state.players[playerIndex].playerHand ?? const <CardModel>[];
      if (ev.handIndex >= 0 && ev.handIndex < hand.length) card = hand[ev.handIndex];
    } else if (playerIndex < _lastHands.length && ev.handIndex >= 0 && ev.handIndex < _lastHands[playerIndex].length) {
      card = _lastHands[playerIndex][ev.handIndex];
    }
    if (card == null) return;

    _beginEliminateHover(card: card, playerIndex: playerIndex, handIndex: ev.handIndex);
    _applyEliminateResult(
      failed: ev.failed,
      matchOver: ev.matchOver,
      notice: ev.failed ? _wrongRankNotice : null,
      penaltyCard: penalty.card,
      penaltyIndex: penalty.index,
    );
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
    if (state.lastEliminate?.failed == true) return;
    if (_eliminatePlayerIndex != null && _eliminateFailed) return;
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

  ({int playerA, int indexA, CardModel cardA, int playerB, int indexB, CardModel cardB})? _findSwap(
    List<List<CardModel>> previous,
    GameModel state,
  ) {
    if (previous.length != state.players.length) return null;
    final changes = <({int player, int index, CardModel from, CardModel to})>[];
    for (var p = 0; p < state.players.length; p++) {
      final prev = previous[p];
      final next = state.players[p].playerHand ?? const <CardModel>[];
      if (prev.length != next.length) return null;
      for (var i = 0; i < prev.length; i++) {
        if (prev[i] != next[i]) {
          changes.add((player: p, index: i, from: prev[i], to: next[i]));
        }
      }
    }
    if (changes.length != 2) return null;
    final a = changes[0];
    final b = changes[1];
    if (a.from != b.to || b.from != a.to) return null;
    return (
      playerA: a.player,
      indexA: a.index,
      cardA: a.from,
      playerB: b.player,
      indexB: b.index,
      cardB: b.from,
    );
  }

  void _maybeStartSwapFlight(GameModel state) {
    if (_swapPlayerA != null) return;
    final swap = _findSwap(_lastHands, state);
    if (swap == null) return;
    _beginSwapFlight(
      playerA: swap.playerA,
      indexA: swap.indexA,
      cardA: swap.cardA,
      playerB: swap.playerB,
      indexB: swap.indexB,
      cardB: swap.cardB,
    );
  }

  void _beginSwapFlight({
    required int playerA,
    required int indexA,
    required CardModel cardA,
    required int playerB,
    required int indexB,
    required CardModel cardB,
    bool awaitingCommit = false,
  }) {
    setState(() {
      _jackPicks.clear();
      _swapCardA = cardA;
      _swapCardB = cardB;
      _swapPlayerA = playerA;
      _swapPlayerB = playerB;
      _swapIndexA = indexA;
      _swapIndexB = indexB;
      _swapAwaitingCommit = awaitingCommit;
    });
  }

  void _onSwapFlightACompleted() {
    if (!mounted) return;
    setState(() => _swapCardA = null);
    _maybeClearSwapFlight();
  }

  void _onSwapFlightBCompleted() {
    if (!mounted) return;
    setState(() => _swapCardB = null);
    _maybeClearSwapFlight();
  }

  void _maybeClearSwapFlight() {
    if (_swapCardA != null || _swapCardB != null) return;
    if (_swapAwaitingCommit) return;
    _clearSwapFlight();
  }

  void _clearSwapFlight() {
    setState(() {
      _swapCardA = null;
      _swapCardB = null;
      _swapPlayerA = null;
      _swapPlayerB = null;
      _swapIndexA = null;
      _swapIndexB = null;
      _swapAwaitingCommit = false;
    });
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

  Set<int> _omittedIndexesFor(int playerIndex) {
    if (_eliminatePlayerIndex != playerIndex || !_eliminateFailed) return const {};
    if (_eliminatePhase == _EliminatePhase.collapsing) return const {};
    final index = _eliminatePenaltyIndex;
    if (index == null) return const {};
    return {index};
  }

  bool _eliminateHollowIsExtra(int playerIndex) {
    if (_eliminatePlayerIndex != playerIndex) return false;
    if (_eliminateCardRemoved) return true;
    return _eliminateFailed &&
        _eliminatePenaltyIndex != null &&
        (_eliminatePhase == _EliminatePhase.rearranging || _eliminatePhase == _EliminatePhase.penalty);
  }

  Set<int> _hollowIndexesFor(int playerIndex) {
    final indexes = <int>{};
    if (_eliminatePlayerIndex == playerIndex) {
      if ((_eliminatePhase == _EliminatePhase.rearranging || _eliminatePhase == _EliminatePhase.penalty) && _eliminatePenaltyIndex != null) {
        indexes.add(_eliminatePenaltyIndex!);
      } else if (_eliminateHandIndex != null) {
        indexes.add(_eliminateHandIndex!);
      }
    }
    if (_sabotagePlayerIndex == playerIndex && _sabotageFlightCard != null && _sabotageHandIndex != null) {
      indexes.add(_sabotageHandIndex!);
    }
    if (_replacePlayerIndex == playerIndex &&
        (_replaceIncomingCard != null || _replaceAwaitingCommit) &&
        (_replaceIncomingReady || _replaceOutgoingReady) &&
        _replaceHandIndex != null) {
      indexes.add(_replaceHandIndex!);
    }
    if (_swapPlayerA != null) {
      if (_swapPlayerA == playerIndex && _swapIndexA != null) indexes.add(_swapIndexA!);
      if (_swapPlayerB == playerIndex && _swapIndexB != null) indexes.add(_swapIndexB!);
    }
    return indexes;
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

  void _onEliminateHoverCompleted() {
    if (!mounted || _eliminateHoverReady) return;
    _eliminateHoverReady = true;
    _eliminateHoverArrivedAt = DateTime.now();
    _maybeBranchEliminate();
  }

  void _maybeBranchEliminate() {
    if (!mounted || !_eliminateHoverReady || !_eliminateResultReady) return;
    if (_eliminatePhase != _EliminatePhase.hover) return;
    if (_eliminateHoldTimer != null) return;
    final arrived = _eliminateHoverArrivedAt ?? DateTime.now();
    final remaining = const Duration(seconds: 1) - DateTime.now().difference(arrived);
    _eliminateHoldTimer = Timer(remaining.isNegative ? Duration.zero : remaining, _branchEliminate);
  }

  void _branchEliminate() {
    if (!mounted) return;
    _eliminateHoldTimer = null;
    if (_eliminateFailed && _eliminateMatchOver) {
      setState(() => _eliminateAllowResult = true);
      _maybeShowResult(context.read<MatchCubit>());
      return;
    }
    if (_eliminateFailed) {
      setState(() {
        _eliminatePhase = _EliminatePhase.returning;
        _statusMessage = _eliminateNotice ?? _wrongRankNotice;
      });
      return;
    }
    setState(() => _eliminatePhase = _EliminatePhase.commit);
  }

  void _onEliminateFollowUpStarted() {
    if (!mounted || _eliminateFollowUpStarted) return;
    setState(() => _eliminateFollowUpStarted = true);
  }

  void _onEliminateCommitCompleted() {
    if (!mounted) return;
    setState(() {
      _eliminateFlightCard = null;
      _eliminatePhase = _EliminatePhase.collapsing;
      _eliminateCollapsing = true;
    });
    _eliminateCollapseTimer?.cancel();
    _eliminateCollapseTimer = Timer(PlayerHands.collapseDuration, () {
      if (!mounted) return;
      _clearEliminateFlight();
    });
  }

  void _onEliminateReturnCompleted() {
    if (!mounted) return;
    if (_eliminatePenaltyCard == null || _eliminatePenaltyIndex == null) {
      _clearEliminateFlight();
      return;
    }
    setState(() {
      _eliminatePhase = _EliminatePhase.rearranging;
      _eliminateFollowUpStarted = false;
      _eliminateCollapsing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _eliminatePhase != _EliminatePhase.rearranging) return;
      setState(() => _eliminateCollapsing = false);
      _eliminateCollapseTimer?.cancel();
      _eliminateCollapseTimer = Timer(PlayerHands.collapseDuration, () {
        if (!mounted || _eliminatePhase != _EliminatePhase.rearranging) return;
        setState(() => _eliminatePhase = _EliminatePhase.penalty);
      });
    });
  }

  void _onEliminatePenaltyCompleted() {
    if (!mounted) return;
    _clearEliminateFlight();
  }

  void _clearEliminateFlight({String? statusMessage}) {
    _eliminateCollapseTimer?.cancel();
    _eliminateCollapseTimer = null;
    _eliminateHoldTimer?.cancel();
    _eliminateHoldTimer = null;
    setState(() {
      _eliminateFlightCard = null;
      _eliminatePlayerIndex = null;
      _eliminateHandIndex = null;
      _eliminatePhase = _EliminatePhase.hover;
      _eliminateFailed = false;
      _eliminateMatchOver = false;
      _eliminateHoverReady = false;
      _eliminateResultReady = false;
      _eliminateFollowUpStarted = false;
      _eliminateCardRemoved = false;
      _eliminateCollapsing = false;
      _eliminateAllowResult = false;
      _eliminateHoverArrivedAt = null;
      _eliminateNotice = null;
      _eliminatePenaltyCard = null;
      _eliminatePenaltyIndex = null;
      if (statusMessage != null) _statusMessage = statusMessage;
    });
    if (mounted) _maybeShowResult(context.read<MatchCubit>());
  }

  void _maybeShowResult(MatchCubit cubit) {
    if (_eliminatePlayerIndex != null && !_eliminateAllowResult) return;
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
        _syncPeekTimer(state);
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
                                      onCardTap: matchCubit.isPeekOpen ? null : (i) => _onOpponentCardTap(matchCubit, i),
                                      onChallenge: null,
                                      onEndTurn: null,
                                      cardKeyFor: (i) => _handCardKey(oppIndex, i),
                                      hollowIndexes: _hollowIndexesFor(oppIndex),
                                      hollowIsExtra: _eliminateHollowIsExtra(oppIndex),
                                      hollowCollapsing: _eliminatePlayerIndex == oppIndex && _eliminateCollapsing,
                                      omittedIndexes: _omittedIndexesFor(oppIndex),
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
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: DiscardPile(
                                              key: _discardPileKey,
                                              highlighted: _drawnCardOverPile,
                                              pendingTopCard: _pendingDiscardCard,
                                              lockTop: _replaceOutgoingCard != null,
                                              lockedTopCard: _replaceFrozenPileTop,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            key: _eliminateHoverKey,
                                            width: 40,
                                            height: 60,
                                          ),
                                        ],
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
                                      ..._openingPeekIndexes(matchCubit),
                                      if (_queenRevealPlayer == userIndex && _queenRevealIndex != null) _queenRevealIndex!,
                                    },
                                    jackSelected: _jackPicks,
                                    onCardTap: matchCubit.isPeekOpen ? null : (i) => _onOwnCardTap(matchCubit, i),
                                    onCardDoubleTap: !matchCubit.isPeekOpen &&
                                            matchCubit.canEliminate() &&
                                            _eliminatePlayerIndex == null &&
                                            _replacePlayerIndex == null &&
                                            _swapPlayerA == null
                                        ? (i) => _onOwnCardDoubleTap(matchCubit, i)
                                        : null,
                                    onChallenge: !matchCubit.isPeekOpen && matchCubit.canChallenge() ? () => matchCubit.declareChallenge() : null,
                                    onEndTurn: !matchCubit.isPeekOpen && matchCubit.canEndTurn() ? () => matchCubit.endTurn() : null,
                                    cardKeyFor: (i) => _handCardKey(userIndex!, i),
                                    hollowIndexes: _hollowIndexesFor(userIndex!),
                                    hollowIsExtra: _eliminateHollowIsExtra(userIndex!),
                                    hollowCollapsing: _eliminatePlayerIndex == userIndex && _eliminateCollapsing,
                                    omittedIndexes: _omittedIndexesFor(userIndex!),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned.fill(child: GameOverlay()),
                    if (state != null && state.isPeekOpen)
                      Positioned(
                        right: MediaQuery.sizeOf(context).width * 0.08,
                        top: 0,
                        bottom: 0,
                        child: Center(child: _peekReadyControl(matchCubit, state)),
                      ),
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
                    if (_showEliminateHoverFlight)
                      Positioned.fill(
                        key: const ValueKey('eliminate-hover'),
                        child: DrawCardFlight(
                          card: _eliminateFlightCard!,
                          face: CardFlightFace.reveal,
                          sourceKey: _handCardKey(_eliminatePlayerIndex!, _eliminateHandIndex!),
                          destKey: _eliminateHoverKey,
                          onCompleted: _onEliminateHoverCompleted,
                        ),
                      ),
                    if (_eliminateFlightCard != null &&
                        _eliminatePhase == _EliminatePhase.commit &&
                        _eliminatePlayerIndex != null &&
                        _eliminateHandIndex != null)
                      Positioned.fill(
                        key: const ValueKey('eliminate-commit'),
                        child: DrawCardFlight(
                          card: _eliminateFlightCard!,
                          face: CardFlightFace.visible,
                          sourceKey: _eliminateHoverKey,
                          destKey: _discardPileKey,
                          onStarted: _onEliminateFollowUpStarted,
                          onCompleted: _onEliminateCommitCompleted,
                        ),
                      ),
                    if (_eliminateFlightCard != null &&
                        _eliminatePhase == _EliminatePhase.returning &&
                        _eliminatePlayerIndex != null &&
                        _eliminateHandIndex != null)
                      Positioned.fill(
                        key: const ValueKey('eliminate-return'),
                        child: DrawCardFlight(
                          card: _eliminateFlightCard!,
                          face: CardFlightFace.conceal,
                          sourceKey: _eliminateHoverKey,
                          destKey: _handCardKey(_eliminatePlayerIndex!, _eliminateHandIndex!),
                          flipAtEnd: true,
                          onStarted: _onEliminateFollowUpStarted,
                          onCompleted: _onEliminateReturnCompleted,
                        ),
                      ),
                    if (_eliminatePhase == _EliminatePhase.penalty &&
                        _eliminatePenaltyCard != null &&
                        _eliminatePlayerIndex != null &&
                        _eliminatePenaltyIndex != null)
                      Positioned.fill(
                        key: const ValueKey('eliminate-penalty'),
                        child: DrawCardFlight(
                          card: _eliminatePenaltyCard!,
                          face: CardFlightFace.hidden,
                          sourceKey: _deckKey,
                          destKey: _handCardKey(_eliminatePlayerIndex!, _eliminatePenaltyIndex!),
                          onCompleted: _onEliminatePenaltyCompleted,
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
                    if (_swapCardA != null && _swapPlayerA != null && _swapIndexA != null && _swapPlayerB != null && _swapIndexB != null)
                      Positioned.fill(
                        key: const ValueKey('swap-flight-a'),
                        child: DrawCardFlight(
                          card: _swapCardA!,
                          face: CardFlightFace.hidden,
                          sourceKey: _handCardKey(_swapPlayerA!, _swapIndexA!),
                          destKey: _handCardKey(_swapPlayerB!, _swapIndexB!),
                          arcHeight: 28,
                          onCompleted: _onSwapFlightACompleted,
                        ),
                      ),
                    if (_swapCardB != null && _swapPlayerA != null && _swapIndexA != null && _swapPlayerB != null && _swapIndexB != null)
                      Positioned.fill(
                        key: const ValueKey('swap-flight-b'),
                        child: DrawCardFlight(
                          card: _swapCardB!,
                          face: CardFlightFace.hidden,
                          sourceKey: _handCardKey(_swapPlayerB!, _swapIndexB!),
                          destKey: _handCardKey(_swapPlayerA!, _swapIndexA!),
                          arcHeight: -28,
                          onCompleted: _onSwapFlightBCompleted,
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
    this.hollowIndexes = const {},
    this.hollowIsExtra = false,
    this.hollowCollapsing = false,
    this.omittedIndexes = const {},
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
  final Set<int> hollowIndexes;
  final bool hollowIsExtra;
  final bool hollowCollapsing;
  final Set<int> omittedIndexes;

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
              hollowIndexes: hollowIndexes,
              hollowIsExtra: hollowIsExtra,
              hollowCollapsing: hollowCollapsing,
              omittedIndexes: omittedIndexes,
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
