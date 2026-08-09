import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/service/supabase_service.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/data/configuration_data.dart';
import '../../../../auth_game_services/model/firebase_user_model.dart';
import '../../../model/card_model.dart';
import '../../../model/deck_model.dart';
import '../../../model/player_match_model.dart';

class MatchCubit extends Cubit<GameModel?> {
  MatchCubit() : super(null);

  SupabaseClient get _client => SupabaseService.client;

  initalize(String? gameCode) async {
    if (gameCode == null) return null;

    final row = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
    GameModel? gameModel = GameModel.fromMap(Map<String, dynamic>.from(row ?? {}));

    Deck deck = Deck(generateNewRandomDeck: true);

    final dealtPlayers = gameModel.players.map((player) {
      final hand = List<CardModel>.from(player.playerHand ?? const []);
      while (hand.length < 4) {
        hand.add(deck.getCardFromDeck());
      }
      return player.copyWith(playerHand: hand);
    }).toList();
    gameModel = gameModel.copyWith(players: dealtPlayers);

    final Map<String, dynamic> updateDetails = {
      'draw_deck': deck.toMapList(),
      'discard_deck': [],
      'players': gameModel.players.map((e) => e.toMap()).toList(),
      'turn': 0,
    };

    if (isHost(hostId: gameModel.hostId)) {
      updateDetails['turn_start_time'] =
          DateTime.now().add(Duration(milliseconds: ConfigurationData.turnDuration)).toIso8601String();
    }

    await _client.from('matches').update(updateDetails).eq('game_code', gameModel.code);

    final List<PlayerMatchModel> players = await _loadPlayers(gameModel.players);

    final refreshed = await _client.from('matches').select().eq('game_code', gameModel.code).maybeSingle();
    emit(GameModel.fromMap(Map<String, dynamic>.from(refreshed ?? {})).copyWith(players: players));
  }

  bool isHost({String? hostId, String? uid}) {
    if (state?.hostId == null) {
      if (hostId == null) return false;
    }

    return (hostId ?? state!.hostId) == (uid ?? FirebaseAuth.instance.currentUser?.uid);
  }

  //DELETE GAME
  deleteGame() async {
    if (state?.code.isEmpty ?? true) return;
    await _client.from('matches').delete().eq('game_code', state!.code);
  }

  setGameToActive() async {
    if (state?.code == null) return;
    emit(state?.copyWith(isActive: true));
    await _client.from('matches').update({'is_active': true}).eq('game_code', state!.code);
  }

  startNextTurn() async {
    if (state?.code == null) return;
    int newTurn = state?.turn == 1 ? 0 : 1;
    DateTime? newTime = state?.turnStartTime?.add(Duration(milliseconds: ConfigurationData.turnDuration));
    await _client.from('matches').update({
      'turn': newTurn,
      'turn_start_time': (newTime ?? DateTime.now()).toIso8601String(),
    }).eq('game_code', state!.code);

    emit(state?.copyWith(turn: newTurn, turnStartTime: newTime));
  }

  //LEAVE GAME
  Future<void> leaveGame() async {
    if (state?.code == null || state?.players == null) return;
    if (state?.code.length != 4) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    state?.players.removeWhere(
      (element) {
        return element.playerId == userId;
      },
    );
    if (userId != null) {
      await _client.from('matches').update({
        'players': state?.players.map((e) => e.toMap()).toList(),
      }).eq('game_code', state!.code);
    }
  }

  bool updateFromSupabase(Map<String, dynamic>? data, {required bool deleted}) {
    if (deleted || data == null) {
      return false;
    }
    emit(GameModel.fromMap(data).copyWith(players: state?.players));
    return true;
  }

  //Discard Card
  discardHand(int playerIndex, int cardIndex) async {
    GameModel? gameModel = state?.copyWith();
    CardModel? cardDiscarded = gameModel?.players[playerIndex].playerHand?.removeAt(cardIndex);
    if (cardDiscarded != null) gameModel?.discardDeck?.cardDeck?.add(cardDiscarded);

    emit(gameModel?.copyWith(players: state?.players));

    await _client.from('matches').update({
      'discard_deck': gameModel?.discardDeck?.toMapList(),
      'players': gameModel?.players.map((e) => e.toMap()).toList(),
    }).eq('game_code', gameModel!.code);
  }

  //Draw Card
  Future<void> drawCard() async {
    GameModel? gameModel = state?.copyWith();
    CardModel? cardDiscarded = gameModel?.drawDeck?.getCardFromDeck();

    emit(gameModel?.copyWith(drawnCard: cardDiscarded).copyWith(players: state?.players));

    await _client.from('matches').update({
      'draw_deck': gameModel?.drawDeck?.toMapList(),
      'drawn_card': cardDiscarded?.toMap(),
    }).eq('game_code', gameModel!.code);
  }

  int? getUserIndex() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final userIndex = state?.players.indexWhere(
      (element) {
        return (element.playerId == uid);
      },
    );

    if (userIndex == -1) {
      return null;
    }
    return userIndex;
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
