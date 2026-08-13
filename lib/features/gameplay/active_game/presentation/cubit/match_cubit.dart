import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/errors/exceptions.dart';
import 'package:five_minus/features/auth_game_services/data/repositories/user_repository.dart';
import 'package:five_minus/features/gameplay/data/repositories/match_repository.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_power.dart';
import 'package:five_minus/features/gameplay/model/game_constants.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../model/card_model.dart';
import '../../../model/player_match_model.dart';

class MatchCubit extends Cubit<GameModel?> {
  MatchCubit({
    MatchRepository? matchRepository,
    UserRepository? userRepository,
  })  : _matchRepository = matchRepository ?? MatchRepository(),
        _userRepository = userRepository ?? UserRepository(),
        super(null);

  final MatchRepository _matchRepository;
  final UserRepository _userRepository;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool _autoDrawInFlight = false;

  bool get hasPendingPower {
    if (state?.powerStartTime == null) return false;
    final power = _topDiscardPower;
    return power == CardPower.look || power == CardPower.swap;
  }

  CardPower get _topDiscardPower {
    final deck = state?.discardDeck?.cardDeck;
    if (deck == null || deck.isEmpty) return CardPower.none;
    return deck.last.cardPower ?? CardPower.none;
  }

  CardModel? get topDiscard {
    final deck = state?.discardDeck?.cardDeck;
    if (deck == null || deck.isEmpty) return null;
    return deck.last;
  }

  bool get isMatchOver => state?.winner != null || state?.status == 'finished';

  bool get isDraw => state?.winner?.playerId == GameConstants.drawWinnerId;

  Future<void> initalize(String? gameCode) async {
    if (gameCode == null) return;

    final fetched = await _matchRepository.fetchMatch(gameCode);
    final parsed = fetched ?? GameModel.fromMap(<String, dynamic>{});
    final players = await _loadPlayers(parsed.players);
    emit(parsed.copyWith(players: players));
    await ensureAutoDraw();
    await heartbeat();
  }

  bool isHost({String? hostId, String? uid}) {
    final host = hostId ?? state?.hostId;
    if (host == null || host.isEmpty) return false;
    return host == (uid ?? _uid);
  }

  Future<void> deleteGame() async {
    if (state?.code.isEmpty ?? true) return;
    await _matchRepository.deleteMatch(state!.code);
  }

  Future<void> setGameToActive() async {}

  bool isMyTurn() {
    final me = _me();
    if (me == null || state?.turn == null) return false;
    return state!.turn == me.seat;
  }

  bool canDraw() {
    if (isMatchOver || !isMyTurn() || hasPendingPower) return false;
    final me = _me();
    if (me == null || (me.actionsComplete)) return false;
    return state?.drawnCard == null;
  }

  bool get needsAutoDraw {
    final game = state;
    if (game == null || isMatchOver || !game.isActive || hasPendingPower) return false;
    final turn = game.turn;
    final active = _playerAtSeat(game, turn);
    if (active == null) return false;
    if (game.drawnCard != null) return false;
    if (active.actionsComplete) return false;
    return true;
  }

  Future<void> ensureAutoDraw() async {
    if (_autoDrawInFlight || !needsAutoDraw) return;
    _autoDrawInFlight = true;
    try {
      if (!needsAutoDraw) return;
      await _emitMove(await _matchRepository.claimDraw(state!.code));
    } on ServerException {
      // Another client claimed, or it is not this seat's turn.
    } finally {
      _autoDrawInFlight = false;
    }
  }

  bool canDiscardOrReplace() {
    if (isMatchOver || !isMyTurn() || hasPendingPower) return false;
    final me = _me();
    if (me == null || me.actionsComplete) return false;
    return state?.drawnCard != null;
  }

  bool canEliminate() {
    if (isMatchOver || !isMyTurn() || hasPendingPower) return false;
    final me = _me();
    if (me == null) return false;
    if (me.eliminationLocked) return false;
    return topDiscard != null;
  }

  bool canChallenge() {
    if (isMatchOver || !isMyTurn() || hasPendingPower) return false;
    final me = _me();
    if (me == null) return false;
    return me.actionsComplete && !(me.isChallengedDeclard ?? false);
  }

  bool canEndTurn() {
    if (isMatchOver || !isMyTurn() || hasPendingPower) return false;
    final me = _me();
    return me?.actionsComplete == true;
  }

  Future<void> drawCard() async {
    if (!canDraw()) return;
    try {
      await _emitMove(await _matchRepository.claimDraw(state!.code));
    } on ServerException {
      return;
    }
  }

  Future<void> discardDrawnCard() async {
    if (!canDiscardOrReplace()) return;
    await _emitMove(await _matchRepository.discardDrawn(state!.code));
  }

  Future<void> replaceHandCard(int handIndex) async {
    if (!canDiscardOrReplace()) return;
    await _emitMove(await _matchRepository.replaceHand(state!.code, handIndex));
  }

  Future<void> resolveQueenLook({required int handIndex}) async {
    if (!hasPendingPower || _topDiscardPower != CardPower.look || !isMyTurn()) return;
    await _emitMove(await _matchRepository.clearPendingPower(state!.code));
  }

  Future<void> resolveJackSwap({
    required int handIndexA,
    required int playerIndexA,
    required int handIndexB,
    required int playerIndexB,
  }) async {
    if (!hasPendingPower || _topDiscardPower != CardPower.swap || !isMyTurn()) return;
    final game = state;
    if (game == null) return;
    if (playerIndexA >= game.players.length || playerIndexB >= game.players.length) return;
    await _emitMove(await _matchRepository.swapHands(
      gameCode: game.code,
      seatA: game.players[playerIndexA].seat,
      indexA: handIndexA,
      seatB: game.players[playerIndexB].seat,
      indexB: handIndexB,
    ));
  }

  Future<String?> eliminateCard(int handIndex) async {
    if (!canEliminate()) return 'Cannot eliminate now';
    if (topDiscard == null) return 'No discard card';
    final result = await _matchRepository.eliminateCard(state!.code, handIndex);
    await _emitMove(result.game);
    return result.notice;
  }

  Future<void> declareChallenge() async {
    if (!canChallenge()) return;
    await _emitMove(await _matchRepository.declareChallenge(state!.code));
    await ensureAutoDraw();
  }

  Future<void> endTurn({bool fromChallenge = false}) async {
    if (!fromChallenge && !canEndTurn()) return;
    if (isMatchOver) return;
    await _emitMove(await _matchRepository.endTurn(state!.code));
    await ensureAutoDraw();
  }

  Future<void> forfeitWinForRemainingPlayer() async {
    if (getUserIndex() == null || isMatchOver) return;
    try {
      await _emitMove(await _matchRepository.winByDisconnect(state!.code));
    } on ServerException {
      return;
    }
  }

  String resultExplanation({required bool iWon, required bool isDraw}) {
    switch (state?.endReason) {
      case EndReason.emptyHand:
        return iWon ? 'You cleared all your cards.' : 'Opponent cleared all their cards.';
      case EndReason.challenge:
        return iWon ? 'You won by challenge.' : 'Opponent won by challenge.';
      case EndReason.challengeTie:
        return 'Both challenged with the same hand points.';
      case EndReason.penalties:
        return iWon
            ? 'Opponent reached ${GameConstants.maxPenalties} penalties.'
            : 'You reached ${GameConstants.maxPenalties} penalties.';
      case EndReason.forfeit:
        return iWon ? 'Opponent left the game.' : 'You left the game.';
      case EndReason.disconnect:
        return iWon
            ? 'Opponent disconnected and timed out.'
            : 'You disconnected and timed out.';
      default:
        if (isDraw) return 'The match ended in a draw.';
        return iWon ? 'You won the match.' : 'You lost the match.';
    }
  }

  Future<void> heartbeat() async {
    if (state?.code == null) return;
    final userId = _uid;
    final idx = getUserIndex();
    if (userId == null || idx == null) return;
    final code = state!.code;
    final lastSeen = DateTime.now().toUtc();
    await _matchRepository.heartbeatSeat(code, userId, lastSeen);
    if (state?.code != code) return;
    final players = List<PlayerMatchModel>.from(state!.players);
    players[idx] = players[idx].copyWith(lastSeen: lastSeen.toIso8601String());
    emit(state!.copyWith(players: players));
  }

  bool opponentTimedOut() {
    final idx = getUserIndex();
    if (idx == null || state == null || state!.players.length < 2) return false;
    final opp = state!.players[opponentOf(idx)];
    final seen = opp.lastSeen;
    if (seen == null) return false;
    final last = DateTime.tryParse(seen)?.toUtc();
    if (last == null) return false;
    return DateTime.now().toUtc().difference(last).inSeconds >= GameConstants.reconnectTimeoutSeconds;
  }

  Future<void> forfeitAndLeave() async {
    if (getUserIndex() != null && !isMatchOver && (state?.players.length ?? 0) >= 2) {
      await _emitMove(await _matchRepository.forfeit(state!.code));
    }
  }

  Future<void> leaveGame() async {
    if (state?.code == null || state?.players == null) return;
    if (state!.code.length != 4) return;
    final userId = _uid;
    if (userId != null) {
      await _matchRepository.deleteSeat(state!.code, userId);
    }
  }

  bool updateFromSupabase(GameModel? data, {required bool deleted}) {
    if (deleted || data == null) return false;
    emit(data.copyWith(players: _mergeLoadedPlayers(data.players)));
    if (needsAutoDraw) {
      unawaited(ensureAutoDraw());
    }
    return true;
  }

  StreamSubscription<GameModel?>? watchMatch(void Function(GameModel? game, {required bool deleted}) onData) {
    final code = state?.code;
    if (code == null) return null;
    return _matchRepository.watchMatch(code).listen((game) {
      onData(game, deleted: game == null);
    });
  }

  Future<void> discardHand(int playerIndex, int cardIndex) async {
    if (playerIndex != getUserIndex()) return;
    if (state?.drawnCard != null) {
      await replaceHandCard(cardIndex);
    }
  }

  int? getUserIndex() {
    final uid = _uid;
    final userIndex = state?.players.indexWhere((element) => element.playerId == uid);
    if (userIndex == null || userIndex == -1) return null;
    return userIndex;
  }

  int opponentOf(int index) => index == 0 ? 1 : 0;

  PlayerMatchModel? _playerAtSeat(GameModel game, int? seat) {
    if (seat == null) return null;
    for (final p in game.players) {
      if (p.seat == seat) return p;
    }
    return null;
  }

  PlayerMatchModel? _me() {
    final idx = getUserIndex();
    if (idx == null || state == null) return null;
    return state!.players[idx];
  }

  Future<void> _emitMove(GameModel game) async {
    emit(game.copyWith(players: _mergeLoadedPlayers(game.players)));
  }

  List<PlayerMatchModel> _mergeLoadedPlayers(List<PlayerMatchModel> incoming) {
    return incoming.map((p) {
      PlayerMatchModel? prev;
      for (final existing in state?.players ?? const <PlayerMatchModel>[]) {
        if (existing.playerId == p.playerId) {
          prev = existing;
          break;
        }
      }
      return p.copyWith(loadedPlayer: prev?.loadedPlayer ?? p.loadedPlayer);
    }).toList();
  }

  Future<List<PlayerMatchModel>> _loadPlayers(List<PlayerMatchModel> players) async {
    final List<PlayerMatchModel> loaded = [];
    for (final e in players) {
      if (e.loadedPlayer != null || e.playerId == null) {
        loaded.add(e);
        continue;
      }
      final user = await _userRepository.fetchFirebaseUser(e.playerId!);
      loaded.add(e.copyWith(loadedPlayer: user));
    }
    return loaded;
  }
}
