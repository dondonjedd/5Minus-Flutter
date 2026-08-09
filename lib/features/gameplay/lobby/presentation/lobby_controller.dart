import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/service/supabase_service.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/active_game_controller.dart';
import 'package:five_minus/features/gameplay/model/active_game_params.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:five_minus/features/gameplay/model/lobby_params.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';
import 'package:five_minus/features/dashboard/presentation/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'lobby_screen.dart';

class LobbyController {
  static const String routeName = '/LobbyController';
  static Widget screen({required LobbyParams params}) {
    return LobbyScreen(
      controller: LobbyController._(),
      lobbyParams: params,
    );
  }

  LobbyController._();

  SupabaseClient get _client => SupabaseService.client;

  bool isHost({required String? hostId, String? uid}) {
    if (hostId == null) return false;
    if (hostId.isEmpty) return false;
    return hostId == (uid ?? FirebaseAuth.instance.currentUser?.uid);
  }

  //*******************HOST********************
  String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  //START GAME
  startGame(BuildContext context, {required String? gameCode}) async {
    if (gameCode == null) return;
    await _client.from('matches').update({'has_started': true}).eq('game_code', gameCode);

    if (!context.mounted) return;
    navigateActiveGame(context, gameCode: gameCode);

    return;
  }

  //DELETE GAME
  deleteGame({required String? gameCode}) async {
    if (gameCode == null) return;
    if (gameCode.isEmpty) return;
    await _client.from('matches').delete().eq('game_code', gameCode);
  }

  //CREATE GAME
  Future<GameModel> createGame() async {
    String gameCode = '';

    while (gameCode.isEmpty) {
      String tmpGamecode = generateGameCode();
      bool isCodeAvailable = await isGameCodeAvailable(tmpGamecode);
      if (isCodeAvailable) {
        gameCode = tmpGamecode;
      }
    }

    final hostId = FirebaseAuth.instance.currentUser?.uid;

    if (hostId != null) {
      final game = GameModel(
        hostId: hostId,
        code: gameCode,
        players: [PlayerMatchModel(playerId: hostId, isReady: true)],
        gameType: 0,
        isActive: false,
        hasStarted: false,
      );
      await _client.from('matches').insert(game.toMap());
    }

    final data = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
    GameModel gameModel = GameModel.fromMap(Map<String, dynamic>.from(data ?? {}));
    return gameModel.copyWith(players: await _loadPlayers(gameModel.players));
  }

  //GENERATE GAME CODE
  String generateGameCode() {
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(4, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  //VERIFY IF GAME CODE IS AVAILABLE
  Future<bool> isGameCodeAvailable(String gameCode) async {
    final res = await _client.from('matches').select('game_code').eq('game_code', gameCode).maybeSingle();
    return res == null;
  }

  //TOGGLE GAME TYPE
  List<bool> toggleGameTypeLocal({required int? index, required List<bool> selectedGameType}) {
    List<bool> tmpList = [...selectedGameType];
    for (int i = 0; i < tmpList.length; i++) {
      tmpList[i] = i == index;
    }
    return tmpList;
  }

  //TOGGLE GAME TYPE IN SUPABASE
  Future<void> toggleGameTypeFstore({required String? gameCode, required int gameType}) async {
    if (gameCode == null) return;

    await _client.from('matches').update({'game_type': gameType}).eq('game_code', gameCode);
    return;
  }

  RealtimeChannel? listenToChanges(GameModel? gameModel, void Function(Map<String, dynamic>? data, {required bool deleted})? onData) {
    final code = gameModel?.code;
    if (code == null || onData == null) return null;

    return _client.channel('match:$code').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'matches',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'game_code',
        value: code,
      ),
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.delete) {
          onData(null, deleted: true);
          return;
        }
        final record = payload.newRecord;
        onData(Map<String, dynamic>.from(record), deleted: false);
      },
    ).subscribe();
  }

  //*******************HOST********************

  //*******************CLIENT********************

  //JOIN GAME
  Future<GameModel> joinGame(String gameCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final existing = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
      if (existing != null) {
        final gameModel = GameModel.fromMap(Map<String, dynamic>.from(existing));
        final alreadyJoined = gameModel.players.any((p) => p.playerId == userId);
        if (!alreadyJoined) {
          final players = [
            ...gameModel.players.map((e) => e.toMap()),
            PlayerMatchModel(playerId: userId).toMap(),
          ];
          await _client.from('matches').update({'players': players}).eq('game_code', gameCode);
        }
      }
    }

    final data = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
    GameModel gameModel = GameModel.fromMap(Map<String, dynamic>.from(data ?? {}));
    return gameModel.copyWith(players: await _loadPlayers(gameModel.players));
  }

  //LEAVE GAME
  Future<void> leaveGame({required String? gameCode, required List<PlayerMatchModel>? playerModelList}) async {
    if (gameCode == null || playerModelList == null) return;
    if (gameCode.length != 4) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    playerModelList.removeWhere(
      (element) {
        return element.playerId == userId;
      },
    );
    if (userId != null) {
      await _client.from('matches').update({
        'players': playerModelList.map((e) => e.toMap()).toList(),
      }).eq('game_code', gameCode);
    }
  }

  //TOGGLE READY OR UNREADY
  Future<void> toggleReady({required String? gameCode, required List<PlayerMatchModel>? playerModelList}) async {
    if (gameCode == null || playerModelList == null) return;
    if (gameCode.length != 4) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    playerModelList = playerModelList.map(
      (e) {
        if (e.playerId == userId) {
          e = e.copyWith(isReady: !(e.isReady ?? true));
        }
        return e;
      },
    ).toList();
    if (userId != null) {
      await _client.from('matches').update({
        'players': playerModelList.map((e) => e.toMap()).toList(),
      }).eq('game_code', gameCode);
    }
  }

  bool isPlayerReady({required List<PlayerMatchModel>? playerModelList}) {
    if (playerModelList == null) return false;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    return playerModelList
            .firstWhere(
              (element) => element.playerId == userId,
              orElse: () => const PlayerMatchModel(playerId: null, isReady: false),
            )
            .isReady ??
        false;
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

  //*******************CLIENT********************

  navigateDashboard(BuildContext context) {
    context.goNamed(DashboardController.routeName);
  }

  navigateActiveGame(BuildContext context, {required String? gameCode}) {
    if (gameCode == null) return;

    context.goNamed(ActiveGameController.routeName, extra: ActiveGameParams(gameCode: gameCode));
  }
}
