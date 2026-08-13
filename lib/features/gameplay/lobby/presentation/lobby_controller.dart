import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/errors/exceptions.dart';
import 'package:five_minus/features/auth_game_services/data/repositories/user_repository.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/active_game_controller.dart';
import 'package:five_minus/features/gameplay/data/repositories/match_repository.dart';
import 'package:five_minus/features/gameplay/model/active_game_params.dart';
import 'package:five_minus/features/gameplay/model/game_model.dart';
import 'package:five_minus/features/gameplay/model/lobby_params.dart';
import 'package:five_minus/features/gameplay/model/player_match_model.dart';
import 'package:five_minus/features/dashboard/presentation/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'lobby_screen.dart';

class LobbyController {
  static const String routeName = '/LobbyController';

  /// Product cap for this milestone; schema still allows more players later.
  static const int maxPlayers = 2;

  static Widget screen({required LobbyParams params}) {
    return LobbyScreen(
      controller: LobbyController._(),
      lobbyParams: params,
    );
  }

  LobbyController._({
    MatchRepository? matchRepository,
    UserRepository? userRepository,
  })  : _matchRepository = matchRepository ?? MatchRepository(),
        _userRepository = userRepository ?? UserRepository();

  final MatchRepository _matchRepository;
  final UserRepository _userRepository;

  /// Pre-lobby join validation (full / started / missing).
  static Future<String?> joinGate(String gameCode) => LobbyController._().joinGameOrError(gameCode);

  bool isHost({required String? hostId, String? uid}) {
    if (hostId == null) return false;
    if (hostId.isEmpty) return false;
    return hostId == (uid ?? FirebaseAuth.instance.currentUser?.uid);
  }

  //*******************HOST********************
  String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  //START GAME
  startGame(BuildContext context, {required String? gameCode, required List<PlayerMatchModel>? players}) async {
    if (gameCode == null) return;
    if ((players?.length ?? 0) != maxPlayers) return;
    if (players!.any((p) => !(p.isReady ?? false))) return;

    await _matchRepository.updateMatch(gameCode, {'has_started': true});

    if (!context.mounted) return;
    navigateActiveGame(context, gameCode: gameCode);

    return;
  }

  //DELETE GAME
  deleteGame({required String? gameCode}) async {
    if (gameCode == null) return;
    if (gameCode.isEmpty) return;
    await _matchRepository.deleteMatch(gameCode);
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
        players: [PlayerMatchModel(playerId: hostId, isReady: true, seat: 0)],
        gameType: 0,
        isActive: false,
        hasStarted: false,
      );
      await _matchRepository.insertMatch(game);
    }

    final gameModel = await _matchRepository.fetchMatch(gameCode) ?? GameModel.fromMap(<String, dynamic>{});
    return gameModel.copyWith(players: await loadPlayers(gameModel.players));
  }

  //GENERATE GAME CODE
  String generateGameCode() {
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(4, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  //VERIFY IF GAME CODE IS AVAILABLE
  Future<bool> isGameCodeAvailable(String gameCode) async {
    return !(await _matchRepository.matchExists(gameCode));
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

    await _matchRepository.updateMatch(gameCode, {'game_type': gameType});
    return;
  }

  StreamSubscription<GameModel?>? listenToChanges(
    GameModel? gameModel,
    void Function(GameModel? data, {required bool deleted})? onData,
  ) {
    final code = gameModel?.code;
    if (code == null || onData == null) return null;

    return _matchRepository.watchMatch(code).listen((data) {
      onData(data, deleted: data == null);
    });
  }

  //*******************HOST********************

  //*******************CLIENT********************

  static int lowestFreeSeat(List<PlayerMatchModel> players) {
    final taken = players.map((p) => p.seat).toSet();
    var seat = 0;
    while (taken.contains(seat)) {
      seat++;
    }
    return seat;
  }

  /// Returns a join error message, or null on success.
  Future<String?> joinGameOrError(String gameCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 'Not signed in';

    for (var attempt = 0; attempt < 2; attempt++) {
      final existing = await _matchRepository.fetchMatch(gameCode);
      if (existing == null) return 'Game does not exist';

      if (existing.hasStarted) return 'Game already started';

      if (existing.players.any((p) => p.playerId == userId)) return null;

      if (existing.players.length >= maxPlayers) {
        return 'Game is full (max $maxPlayers players)';
      }

      final seat = lowestFreeSeat(existing.players);
      try {
        await _matchRepository.insertSeat(
          PlayerMatchModel(playerId: userId, seat: seat),
          gameCode: gameCode,
        );
        return null;
      } on ServerException catch (e) {
        final alreadySeated = e.statusCode == '23505' && e.message.contains('pkey');
        if (alreadySeated) return null;
        final seatTaken = e.statusCode == '23505';
        if (seatTaken && attempt == 0) continue;
        if (seatTaken) return 'Game is full (max $maxPlayers players)';
        rethrow;
      }
    }

    return 'Game is full (max $maxPlayers players)';
  }

  //JOIN GAME
  Future<GameModel> joinGame(String gameCode) async {
    final error = await joinGameOrError(gameCode);
    if (error != null) {
      throw StateError(error);
    }

    final gameModel = await _matchRepository.fetchMatch(gameCode) ?? GameModel.fromMap(<String, dynamic>{});
    return gameModel.copyWith(players: await loadPlayers(gameModel.players));
  }

  //LEAVE GAME
  Future<void> leaveGame({required String? gameCode, required List<PlayerMatchModel>? playerModelList}) async {
    if (gameCode == null || playerModelList == null) return;
    if (gameCode.length != 4) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _matchRepository.deleteSeat(gameCode, userId);
    }
  }

  //TOGGLE READY OR UNREADY
  Future<void> toggleReady({required String? gameCode, required List<PlayerMatchModel>? playerModelList}) async {
    if (gameCode == null || playerModelList == null) return;
    if (gameCode.length != 4) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final me = playerModelList.firstWhereOrNull((e) => e.playerId == userId);
    if (me == null) return;
    await _matchRepository.updateSeat(gameCode, userId, {
      'is_ready': !(me.isReady ?? true),
    });
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

  Future<List<PlayerMatchModel>> loadPlayers(List<PlayerMatchModel> players) async {
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

  /// Preserve already-loaded profiles when applying a realtime lobby update.
  Future<List<PlayerMatchModel>> mergePlayersWithProfiles(
    List<PlayerMatchModel> incoming, {
    List<PlayerMatchModel>? previous,
  }) async {
    final List<PlayerMatchModel> tmpList = [];
    for (final element in incoming) {
      final matchingElement = previous?.firstWhereOrNull((el2) => el2.playerId == element.playerId);
      if (matchingElement != null) {
        tmpList.add(element.copyWith(loadedPlayer: matchingElement.loadedPlayer));
      } else if (element.playerId != null) {
        try {
          final user = await _userRepository.fetchFirebaseUser(element.playerId!);
          tmpList.add(element.copyWith(loadedPlayer: user));
        } catch (_) {
          tmpList.add(element);
        }
      } else {
        tmpList.add(element);
      }
    }
    return tmpList;
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
