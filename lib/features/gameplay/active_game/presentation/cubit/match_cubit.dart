import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/service/supabase_service.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_power.dart';
import 'package:five_minus/features/gameplay/model/game_constants.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../auth_game_services/model/firebase_user_model.dart';
import '../../../model/card_model.dart';
import '../../../model/deck_model.dart';
import '../../../model/player_match_model.dart';

class MatchCubit extends Cubit<GameModel?> {
  MatchCubit() : super(null);

  SupabaseClient get _client => SupabaseService.client;

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

  bool get isMatchOver => state?.winner != null;

  bool get isDraw => state?.winner?.playerId == GameConstants.drawWinnerId;

  /// Host deals once; joiners only load existing state.
  Future<void> initalize(String? gameCode) async {
    if (gameCode == null) return;

    final row = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
    GameModel gameModel = GameModel.fromMap(Map<String, dynamic>.from(row ?? {}));

    final alreadyDealt = gameModel.drawDeck?.cardDeck?.isNotEmpty == true ||
        (gameModel.players.isNotEmpty && (gameModel.players.first.playerHand?.isNotEmpty ?? false));

    if (isHost(hostId: gameModel.hostId) && !alreadyDealt) {
      Deck deck = Deck(generateNewRandomDeck: true);
      final dealtPlayers = gameModel.players.map((player) {
        final hand = <CardModel>[];
        while (hand.length < GameConstants.startingHandSize) {
          final card = deck.getCardFromDeck();
          if (card == null) break;
          hand.add(card);
        }
        return player.copyWith(
          playerHand: hand,
          penaltyCount: 0,
          eliminationLocked: false,
          actionsComplete: false,
          isChallengedDeclard: false,
          lastSeen: DateTime.now().toUtc().toIso8601String(),
        );
      }).toList();

      gameModel = gameModel.copyWith(players: dealtPlayers, isActive: true);

      await _client.from('matches').update({
        'draw_deck': deck.toMapList(),
        'discard_deck': [],
        'players': gameModel.players.map((e) => e.toMap()).toList(),
        'turn': 0,
        'drawn_card': null,
        'is_active': true,
        'is_challenge_complete': false,
        'power_start_time': null,
        'winner': null,
        // Wall-clock turn start so every client can derive the same timer progress.
        'turn_start_time': DateTime.now().toUtc().toIso8601String(),
      }).eq('game_code', gameModel.code);
    }

    final refreshed = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
    final parsed = GameModel.fromMap(Map<String, dynamic>.from(refreshed ?? {}));
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
    await _client.from('matches').delete().eq('game_code', state!.code);
  }

  Future<void> setGameToActive() async {
    if (state?.code == null) return;
    emit(state?.copyWith(isActive: true));
    await _client.from('matches').update({'is_active': true}).eq('game_code', state!.code);
  }

  bool isMyTurn() {
    final idx = getUserIndex();
    if (idx == null || state?.turn == null) return false;
    return state!.turn == idx;
  }

  bool canDraw() {
    if (isMatchOver || !isMyTurn() || hasPendingPower) return false;
    final me = _me();
    if (me == null || (me.actionsComplete)) return false;
    return state?.drawnCard == null;
  }

  /// Active seat needs a face-up draw (any client may satisfy this).
  bool get needsAutoDraw {
    final game = state;
    if (game == null || isMatchOver || !game.isActive || hasPendingPower) return false;
    final turn = game.turn;
    if (turn == null || turn < 0 || turn >= game.players.length) return false;
    if (game.drawnCard != null) return false;
    if (game.players[turn].actionsComplete) return false;
    return true;
  }

  /// Draw for the active seat if needed. Either client may write; only the first
  /// conditional update (`drawn_card` IS NULL) wins.
  Future<void> ensureAutoDraw() async {
    if (_autoDrawInFlight || !needsAutoDraw) return;
    _autoDrawInFlight = true;
    try {
      if (!needsAutoDraw) return;

      var game = _cloneState();
      game = _ensureDrawPile(game);
      final card = game.drawDeck?.getCardFromDeck() as CardModel?;
      if (card == null) return;

      final code = game.code;
      // Use list select (not maybeSingle): 0 rows from a lost race throws PGRST116/406.
      List<Map<String, dynamic>> rows;
      try {
        rows = await _client
            .from('matches')
            .update({
              'drawn_card': card.toMap(),
              'draw_deck': game.drawDeck?.toMapList(),
              'discard_deck': game.discardDeck?.toMapList(),
            })
            .eq('game_code', code)
            .isFilter('drawn_card', null)
            .select();
      } on PostgrestException catch (e) {
        // Another client already drew, or no matching row.
        if (e.code == 'PGRST116') return;
        rethrow;
      }

      if (rows.isEmpty) return;
      if (state?.code != code) return;

      final parsed = GameModel.fromMap(Map<String, dynamic>.from(rows.first));
      final players = parsed.players.asMap().entries.map((e) {
        final loaded = (state?.players.length ?? 0) > e.key ? state!.players[e.key].loadedPlayer : null;
        final sameId = loaded != null && state!.players[e.key].playerId == e.value.playerId;
        return e.value.copyWith(loadedPlayer: sameId ? loaded : e.value.loadedPlayer);
      }).toList();
      emit(parsed.copyWith(players: players));
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
    // Allowed before discard/replace so the current top discard can still be matched.
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
    var game = _cloneState();
    game = _ensureDrawPile(game);
    final card = game.drawDeck!.getCardFromDeck() as CardModel?;
    if (card == null) return;

    await _persist(
      game.copyWith(drawnCard: card, drawDeck: game.drawDeck),
      clearDrawnCard: false,
      includeDrawnCard: true,
    );
  }

  /// Discard the drawn card without replacing a hand card.
  Future<void> discardDrawnCard() async {
    if (!canDiscardOrReplace()) return;
    GameModel game = _cloneState();
    final drawn = game.drawnCard;
    if (drawn == null) return;

    final discard = List<CardModel>.from(game.discardDeck?.cardDeck ?? []);
    discard.add(drawn);
    game = game.copyWith(discardDeck: Deck(list: discard), drawnCard: null);

    final idx = getUserIndex()!;
    await _afterDiscard(game, discarded: drawn, playerIndex: idx);
  }

  /// Replace hand card with drawn card; discarded hand card goes to discard pile.
  Future<void> replaceHandCard(int handIndex) async {
    if (!canDiscardOrReplace()) return;
    GameModel game = _cloneState();
    final drawn = game.drawnCard;
    final idx = getUserIndex()!;
    final hand = List<CardModel>.from(game.players[idx].playerHand ?? []);
    if (drawn == null || handIndex < 0 || handIndex >= hand.length) return;

    final removed = hand[handIndex];
    hand[handIndex] = drawn;
    final discard = List<CardModel>.from(game.discardDeck?.cardDeck ?? []);
    discard.add(removed);

    final players = List<PlayerMatchModel>.from(game.players);
    players[idx] = players[idx].copyWith(playerHand: hand);
    game = game.copyWith(players: players, discardDeck: Deck(list: discard), drawnCard: null);

    await _afterDiscard(game, discarded: removed, playerIndex: idx);
  }

  Future<void> _afterDiscard(GameModel game, {required CardModel discarded, required int playerIndex}) async {
    final power = discarded.cardPower ?? CardPower.none;
    var players = List<PlayerMatchModel>.from(game.players);

    if (power == CardPower.sabotage) {
      game = _applyBlackKing(game, sabotagedBy: playerIndex);
      players = List<PlayerMatchModel>.from(game.players);
      players[playerIndex] = players[playerIndex].copyWith(actionsComplete: true);
      game = game.copyWith(players: players, powerStartTime: null);
      await _persist(game, clearDrawnCard: true, includeDrawnCard: true, clearPowerTime: true);
      await _checkEmptyHandWin(playerIndex);
      return;
    }

    if (power == CardPower.look || power == CardPower.swap) {
      players[playerIndex] = players[playerIndex].copyWith(actionsComplete: true);
      game = game.copyWith(
        players: players,
        powerStartTime: DateTime.now().toUtc(),
      );
      await _persist(game, clearDrawnCard: true, includeDrawnCard: true);
      return;
    }

    players[playerIndex] = players[playerIndex].copyWith(actionsComplete: true);
    game = game.copyWith(players: players, powerStartTime: null);
    await _persist(game, clearDrawnCard: true, includeDrawnCard: true, clearPowerTime: true);
    await _checkEmptyHandWin(playerIndex);
  }

  GameModel _applyBlackKing(GameModel game, {required int sabotagedBy}) {
    final opponent = sabotagedBy == 0 ? 1 : 0;
    if (opponent >= game.players.length) return game;
    game = _ensureDrawPile(game);
    final card = game.drawDeck!.getCardFromDeck() as CardModel?;
    if (card == null) return game;
    final players = List<PlayerMatchModel>.from(game.players);
    final hand = List<CardModel>.from(players[opponent].playerHand ?? []);
    hand.insert(0, card);
    players[opponent] = players[opponent].copyWith(playerHand: hand);
    return game.copyWith(players: players, drawDeck: game.drawDeck);
  }

  Future<void> resolveQueenLook({required int handIndex}) async {
    if (!hasPendingPower || _topDiscardPower != CardPower.look || !isMyTurn()) return;
    // Reveal is local-only (own or opponent); just clear pending power.
    await _clearPendingPower();
  }

  Future<void> resolveJackSwap({
    required int handIndexA,
    required int playerIndexA,
    required int handIndexB,
    required int playerIndexB,
  }) async {
    if (!hasPendingPower || _topDiscardPower != CardPower.swap || !isMyTurn()) return;
    GameModel game = _cloneState();
    if (playerIndexA >= game.players.length || playerIndexB >= game.players.length) return;

    final players = List<PlayerMatchModel>.from(game.players);
    final handA = List<CardModel>.from(players[playerIndexA].playerHand ?? []);
    final handB = List<CardModel>.from(players[playerIndexB].playerHand ?? []);
    if (handIndexA < 0 || handIndexA >= handA.length) return;
    if (handIndexB < 0 || handIndexB >= handB.length) return;

    if (playerIndexA == playerIndexB) {
      final tmp = handA[handIndexA];
      handA[handIndexA] = handA[handIndexB];
      handA[handIndexB] = tmp;
      players[playerIndexA] = players[playerIndexA].copyWith(playerHand: handA);
    } else {
      final tmp = handA[handIndexA];
      handA[handIndexA] = handB[handIndexB];
      handB[handIndexB] = tmp;
      players[playerIndexA] = players[playerIndexA].copyWith(playerHand: handA);
      players[playerIndexB] = players[playerIndexB].copyWith(playerHand: handB);
    }

    game = game.copyWith(players: players, powerStartTime: null);
    await _persist(game, clearPowerTime: true);
  }

  Future<void> _clearPendingPower() async {
    if (state?.code == null) return;
    final game = state!.copyWith(powerStartTime: null);
    await _persist(game, clearPowerTime: true);
  }

  /// Attempt to eliminate a face-down hand card against the top discard rank.
  Future<String?> eliminateCard(int handIndex) async {
    if (!canEliminate()) return 'Cannot eliminate now';
    final top = topDiscard;
    if (top == null) return 'No discard card';

    GameModel game = _cloneState();
    final idx = getUserIndex()!;
    final hand = List<CardModel>.from(game.players[idx].playerHand ?? []);
    if (handIndex < 0 || handIndex >= hand.length) return 'Invalid card';

    final card = hand[handIndex];
    if (card.rank != top.rank) {
      game = _applyPenalty(game, playerIndex: idx, lockElimination: true);
      await _persist(game);
      if (_isDisqualified(game.players[idx])) {
        await _endAsWinner(opponentOf(idx), EndReason.penalties);
      }
      return 'Wrong rank — elimination locked until your next turn';
    }

    hand.removeAt(handIndex);
    final players = List<PlayerMatchModel>.from(game.players);
    players[idx] = players[idx].copyWith(playerHand: hand);
    game = game.copyWith(players: players);
    await _persist(game);

    if (hand.isEmpty) {
      await _endAsWinner(idx, EndReason.emptyHand);
    }
    return null;
  }

  Future<void> declareChallenge() async {
    if (!canChallenge()) return;
    GameModel game = _cloneState();
    final idx = getUserIndex()!;
    final players = List<PlayerMatchModel>.from(game.players);
    players[idx] = players[idx].copyWith(isChallengedDeclard: true);
    game = game.copyWith(players: players, isChallengeComplete: false);
    await _persist(game);
    await endTurn(fromChallenge: true);
  }

  Future<void> endTurn({bool fromChallenge = false}) async {
    if (!fromChallenge && !canEndTurn()) return;
    if (isMatchOver) return;

    final gameSnapshot = _cloneState();
    final current = gameSnapshot.turn ?? 0;
    final othersAlreadyChallenged = gameSnapshot.players.asMap().entries.any(
          (e) => e.key != current && (e.value.isChallengedDeclard ?? false),
        );

    // Response turn finished → resolve challenges before advancing.
    if (othersAlreadyChallenged) {
      await _resolveChallenges();
      if (isMatchOver) return;
    }

    var game = _cloneState();
    final newTurn = current == 1 ? 0 : 1;
    var players = List<PlayerMatchModel>.from(game.players);
    if (current < players.length) {
      players[current] = players[current].copyWith(actionsComplete: false);
    }
    if (newTurn < players.length) {
      players[newTurn] = players[newTurn].copyWith(
        actionsComplete: false,
        eliminationLocked: false,
      );
    }

    // New turn starts now — timer progress is (now - turnStartTime) / duration on all clients.
    final newTime = DateTime.now().toUtc();
    game = game.copyWith(
      players: players,
      turn: newTurn,
      turnStartTime: newTime,
      drawnCard: null,
      powerStartTime: null,
    );
    await _persist(game, clearDrawnCard: true, includeDrawnCard: true, clearPowerTime: true);
    await ensureAutoDraw();
  }

  Future<void> _resolveChallenges() async {
    final game = _cloneState();
    final challengers = <int>[];
    for (var i = 0; i < game.players.length; i++) {
      if (game.players[i].isChallengedDeclard ?? false) challengers.add(i);
    }
    if (challengers.isEmpty) return;

    if (challengers.length == 1) {
      final i = challengers.first;
      final points = game.players[i].handPoints();
      if (points <= GameConstants.challengePointLimit) {
        await _endAsWinner(i, EndReason.challenge);
      } else {
        var g = _applyPenalty(game, playerIndex: i, lockElimination: false);
        final players = List<PlayerMatchModel>.from(g.players);
        for (var j = 0; j < players.length; j++) {
          players[j] = players[j].copyWith(isChallengedDeclard: false);
        }
        g = g.copyWith(players: players, isChallengeComplete: true);
        await _persist(g);
        if (_isDisqualified(g.players[i])) {
          await _endAsWinner(opponentOf(i), EndReason.penalties);
        }
      }
      return;
    }

    int best = challengers.first;
    bool tie = false;
    for (final i in challengers.skip(1)) {
      final pi = game.players[i].handPoints();
      final pb = game.players[best].handPoints();
      if (pi < pb) {
        best = i;
        tie = false;
      } else if (pi == pb) {
        tie = true;
      }
    }

    if (tie) {
      await _endAsDraw(EndReason.challengeTie);
    } else {
      await _endAsWinner(best, EndReason.challenge);
    }
  }

  GameModel _applyPenalty(GameModel game, {required int playerIndex, required bool lockElimination}) {
    game = _ensureDrawPile(game);
    final card = game.drawDeck!.getCardFromDeck() as CardModel?;
    final players = List<PlayerMatchModel>.from(game.players);
    final hand = List<CardModel>.from(players[playerIndex].playerHand ?? []);
    if (card != null) hand.insert(0, card);
    players[playerIndex] = players[playerIndex].copyWith(
      playerHand: hand,
      penaltyCount: players[playerIndex].penaltyCount + 1,
      eliminationLocked: lockElimination ? true : players[playerIndex].eliminationLocked,
    );
    return game.copyWith(players: players, drawDeck: game.drawDeck);
  }

  bool _isDisqualified(PlayerMatchModel p) => p.penaltyCount >= GameConstants.maxPenalties;

  int opponentOf(int index) => index == 0 ? 1 : 0;

  Future<void> _checkEmptyHandWin(int playerIndex) async {
    final hand = state?.players[playerIndex].playerHand;
    if (hand != null && hand.isEmpty) {
      await _endAsWinner(playerIndex, EndReason.emptyHand);
    }
  }

  Future<void> _endAsWinner(int playerIndex, String reason) async {
    if (state == null || playerIndex >= state!.players.length) return;
    final winner = state!.players[playerIndex];
    final game = state!.copyWith(
      winner: winner,
      endReason: reason,
      isActive: false,
      isChallengeComplete: true,
    );
    await _client.from('matches').update({
      'winner': {
        ...winner.toMap(),
        'end_reason': reason,
      },
      'is_active': false,
      'is_challenge_complete': true,
      'players': game.players.map((e) => e.toMap()).toList(),
    }).eq('game_code', game.code);
    emit(game);
  }

  Future<void> _endAsDraw(String reason) async {
    if (state == null) return;
    const draw = PlayerMatchModel(playerId: GameConstants.drawWinnerId);
    final game = state!.copyWith(
      winner: draw,
      endReason: reason,
      isActive: false,
      isChallengeComplete: true,
    );
    await _client.from('matches').update({
      'winner': {
        ...draw.toMap(),
        'end_reason': reason,
      },
      'is_active': false,
      'is_challenge_complete': true,
    }).eq('game_code', game.code);
    emit(game);
  }

  Future<void> forfeitWinForRemainingPlayer() async {
    final idx = getUserIndex();
    if (idx == null || isMatchOver) return;
    await _endAsWinner(idx, EndReason.disconnect);
  }

  /// Human-readable end explanation for the local player.
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
    final idx = getUserIndex();
    if (idx == null) return;
    final code = state!.code;

    // Read-merge-write so a stale local snapshot cannot clobber turn resets
    // (actionsComplete / eliminationLocked) written by the other client.
    final row = await _client.from('matches').select('players').eq('game_code', code).maybeSingle();
    if (row == null || state?.code != code) return;

    final remote = (row['players'] as List<dynamic>? ?? []).map((e) => PlayerMatchModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    if (idx >= remote.length) return;

    final merged = remote.asMap().entries.map((e) {
      final loaded = (state?.players.length ?? 0) > e.key ? state!.players[e.key].loadedPlayer : null;
      final sameId = loaded != null && state!.players[e.key].playerId == e.value.playerId;
      return e.value.copyWith(loadedPlayer: sameId ? loaded : e.value.loadedPlayer);
    }).toList();

    merged[idx] = merged[idx].copyWith(lastSeen: DateTime.now().toUtc().toIso8601String());
    await _client.from('matches').update({
      'players': merged.map((e) => e.toMap()).toList(),
    }).eq('game_code', code);

    if (state?.code != code) return;
    emit(state!.copyWith(players: merged));
  }

  /// Returns true if opponent has been gone longer than reconnect timeout.
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

  GameModel _ensureDrawPile(GameModel game) {
    if (game.drawDeck?.cardDeck?.isNotEmpty ?? false) return game;
    final discard = List<CardModel>.from(game.discardDeck?.cardDeck ?? []);
    if (discard.length <= 1) return game;
    final top = discard.removeLast();
    discard.shuffle();
    return game.copyWith(
      drawDeck: Deck(list: discard),
      discardDeck: Deck(list: [top]),
    );
  }

  GameModel _cloneState() {
    final s = state!;
    return GameModel.fromMap(s.toMap()).copyWith(
      players: s.players.map((p) => PlayerMatchModel.fromMap(p.toMap()).copyWith(loadedPlayer: p.loadedPlayer)).toList(),
      drawDeck: s.drawDeck == null ? null : Deck(list: List<CardModel>.from(s.drawDeck!.cardDeck ?? [])),
      discardDeck: s.discardDeck == null ? null : Deck(list: List<CardModel>.from(s.discardDeck!.cardDeck ?? [])),
    );
  }

  Future<void> _persist(
    GameModel game, {
    bool clearDrawnCard = false,
    bool includeDrawnCard = false,
    bool clearPowerTime = false,
  }) async {
    final map = <String, dynamic>{
      'draw_deck': game.drawDeck?.toMapList(),
      'discard_deck': game.discardDeck?.toMapList(),
      'players': game.players.map((e) => e.toMap()).toList(),
      'turn': game.turn,
      'is_challenge_complete': game.isChallengeComplete,
      'is_active': game.isActive,
    };
    if (includeDrawnCard || clearDrawnCard) {
      map['drawn_card'] = clearDrawnCard ? null : game.drawnCard?.toMap();
    }
    if (game.turnStartTime != null) {
      map['turn_start_time'] = game.turnStartTime!.toUtc().toIso8601String();
    }
    if (clearPowerTime) {
      map['power_start_time'] = null;
    } else if (game.powerStartTime != null) {
      map['power_start_time'] = game.powerStartTime!.toUtc().toIso8601String();
    }
    if (game.winner != null) {
      map['winner'] = game.winner!.toMap();
    }

    await _client.from('matches').update(map).eq('game_code', game.code);

    final players = game.players.asMap().entries.map((e) {
      final loaded = state?.players.length == game.players.length ? state!.players[e.key].loadedPlayer : null;
      return e.value.copyWith(loadedPlayer: e.value.loadedPlayer ?? loaded);
    }).toList();

    emit(game.copyWith(players: players));
  }

  Future<void> forfeitAndLeave() async {
    final idx = getUserIndex();
    if (idx != null && !isMatchOver && (state?.players.length ?? 0) >= 2) {
      await _endAsWinner(opponentOf(idx), EndReason.forfeit);
    }
  }

  Future<void> leaveGame() async {
    if (state?.code == null || state?.players == null) return;
    if (state!.code.length != 4) return;
    final userId = _uid;
    final players = List<PlayerMatchModel>.from(state!.players)..removeWhere((e) => e.playerId == userId);
    if (userId != null) {
      await _client.from('matches').update({
        'players': players.map((e) => e.toMap()).toList(),
      }).eq('game_code', state!.code);
    }
  }

  bool updateFromSupabase(Map<String, dynamic>? data, {required bool deleted}) {
    if (deleted || data == null) return false;
    final parsed = GameModel.fromMap(data);
    final players = parsed.players.asMap().entries.map((e) {
      final loaded = (state?.players.length ?? 0) > e.key ? state!.players[e.key].loadedPlayer : null;
      final sameId = loaded != null && state!.players[e.key].playerId == e.value.playerId;
      return e.value.copyWith(loadedPlayer: sameId ? loaded : e.value.loadedPlayer);
    }).toList();
    emit(parsed.copyWith(players: players));
    if (needsAutoDraw) {
      unawaited(ensureAutoDraw());
    }
    return true;
  }

  // Legacy API used by old drag-discard UI
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

  PlayerMatchModel? _me() {
    final idx = getUserIndex();
    if (idx == null || state == null) return null;
    return state!.players[idx];
  }

  Future<List<PlayerMatchModel>> _loadPlayers(List<PlayerMatchModel> players) async {
    final List<PlayerMatchModel> loaded = [];
    for (final e in players) {
      if (e.loadedPlayer != null || e.playerId == null) {
        loaded.add(e);
        continue;
      }
      final data = await _client.from('users').select().eq('id', e.playerId!).maybeSingle();
      loaded.add(
        e.copyWith(
          loadedPlayer: data == null ? null : FirebaseUserModel.fromMap(Map<String, dynamic>.from(data)),
        ),
      );
    }
    return loaded;
  }
}
