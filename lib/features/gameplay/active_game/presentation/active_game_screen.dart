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

  static const Size _drawnCardSize = Size(40, 60);
  static const double _drawnCardTilt = 0.18;

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _heartbeat?.cancel();
    _reconnectCheck?.cancel();
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
      await cubit.replaceHandCard(handIndex);
      setState(() => _statusMessage = null);
      return;
    }
    if (mode == HandInteractionMode.jackPick) {
      _toggleJackPick(userIndex!, handIndex, cubit);
    }
  }

  Future<void> _onOwnCardDoubleTap(MatchCubit cubit, int handIndex) async {
    if (!cubit.canEliminate()) return;
    final err = await cubit.eliminateCard(handIndex);
    setState(() => _statusMessage = err);
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
      return;
    }
    final hasDrawn = state.drawnCard != null;
    if (!_hadDrawnCard && hasDrawn && _drawFlightCard == null) {
      setState(() {
        _drawFlightCard = state.drawnCard;
        _drawFlightReveal = cubit.isMyTurn();
      });
    }
    _hadDrawnCard = hasDrawn;
  }

  void _onDrawFlightCompleted() {
    if (!mounted) return;
    setState(() => _drawFlightCard = null);
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
                                      child: KeyedSubtree(
                                        key: _drawnSlotKey,
                                        child: (state?.drawnCard == null ||
                                                _pendingDiscardCard != null ||
                                                _drawFlightCard != null)
                                            ? const SizedBox.expand()
                                            : matchCubit.canDiscardOrReplace()
                                                ? Draggable<CardModel>(
                                                    data: state!.drawnCard!,
                                                    dragAnchorStrategy: _drawnCardAnchorStrategy,
                                                    onDragUpdate: _onDrawnCardDragUpdate,
                                                    onDragEnd: _onDrawnCardDragEnd,
                                                    feedback: Material(
                                                      color: Colors.transparent,
                                                      child: Transform.rotate(
                                                        angle: _drawnCardTilt,
                                                        child: FrontCard(cardModel: state.drawnCard!),
                                                      ),
                                                    ),
                                                    childWhenDragging: const SizedBox(width: 40, height: 60),
                                                    child: FrontCard(cardModel: state.drawnCard!),
                                                  )
                                                : matchCubit.isMyTurn()
                                                    ? FrontCard(cardModel: state!.drawnCard!)
                                                    : BackCard(cardModel: state!.drawnCard!),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: DiscardPile(
                                        key: _discardPileKey,
                                        highlighted: _drawnCardOverPile,
                                        pendingTopCard: _pendingDiscardCard,
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
                                    onCardDoubleTap: matchCubit.canEliminate() ? (i) => _onOwnCardDoubleTap(matchCubit, i) : null,
                                    onChallenge: matchCubit.canChallenge() ? () => matchCubit.declareChallenge() : null,
                                    onEndTurn: matchCubit.canEndTurn() ? () => matchCubit.endTurn() : null,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned.fill(child: GameOverlay()),
                    if (_drawFlightCard != null)
                      Positioned.fill(
                        child: DrawCardFlight(
                          card: _drawFlightCard!,
                          revealFace: _drawFlightReveal,
                          deckKey: _deckKey,
                          drawnSlotKey: _drawnSlotKey,
                          onCompleted: _onDrawFlightCompleted,
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
