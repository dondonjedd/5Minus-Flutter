import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:five_minus/features/gameplay/active_game/presentation/active_game_controller.dart';
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
  static Widget screen({required LobbyParams params}) {
    return LobbyScreen(
      controller: LobbyController._(),
      lobbyParams: params,
    );
  }

  LobbyController._();
  bool isHost({required String? hostId, String? uid}) {
    if (hostId == null) return false;
    if (hostId.isEmpty) return false;
    return hostId == (uid ?? FirebaseAuth.instance.currentUser?.uid);
  }

  //*******************HOST********************
  String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  final matchesCollection = FirebaseFirestore.instance.collection('matches');
  final userCollection = FirebaseFirestore.instance.collection('users');

  //START GAME
  startGame({required String? gameCode}) async {
    if (gameCode == null) return;
    await FirebaseFirestore.instance.collection('matches').doc(gameCode).update({'is_active': true});
    return;
  }

  //DELETE GAME
  deleteGame({required String? gameCode}) async {
    if (gameCode == null) return;
    if (gameCode.isEmpty) return;
    await matchesCollection.doc(gameCode).delete();
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
      await matchesCollection.doc(gameCode).set(GameModel(
              hostId: hostId,
              code: gameCode,
              players: [PlayerMatchModel(player: userCollection.doc(hostId), isReady: true)],
              gameType: 0,
              isActive: false)
          .toMap());
    }

    GameModel gameModel = GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});
    List<PlayerMatchModel> players = [];

    for (final e in gameModel.players) {
      if (e.loadedPlayer == null) {
        final data = (await e.player?.get())?.data();
        players.addAll([e.copyWith(loadedPlayer: data == null ? null : FirebaseUserModel.fromMap(data))]);
      }
    }

    return gameModel.copyWith(players: players);
  }

  //GENERATE GAME CODE
  String generateGameCode() {
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(4, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  //VERIFY IF GAME CODE IS AVAILABLE
  Future<bool> isGameCodeAvailable(String gameCode) async {
    final res = await matchesCollection.doc(gameCode).get();

    if (res.exists) {
      return false;
    } else {
      return true;
    }
  }

  //TOGGLE GAME TYPE
  List<bool> toggleGameTypeLocal({required int? index, required List<bool> selectedGameType}) {
    List<bool> tmpList = [...selectedGameType];
    for (int i = 0; i < tmpList.length; i++) {
      tmpList[i] = i == index;
    }
    return tmpList;
  }

  //TOGGLE GAME TYPE IN FIRESTORE
  Future<void> toggleGameTypeFstore({required String? gameCode, required int gameType}) async {
    if (gameCode == null) return;

    await FirebaseFirestore.instance.collection('matches').doc(gameCode).update({'game_type': gameType});
    return;
  }

  StreamSubscription? listenToChanges(GameModel? gameModel, void Function(DocumentSnapshot<Map<String, dynamic>>)? onData) {
    if (gameModel?.code != null) {
      return FirebaseFirestore.instance.collection('matches').doc(gameModel?.code).snapshots().listen(onData);
    }
    return null;
  }

  //*******************HOST********************

  //*******************CLIENT********************

  //JOIN GAME
  Future<GameModel> joinGame(String gameCode) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      await matchesCollection.doc(gameCode).set({
        'players': FieldValue.arrayUnion([PlayerMatchModel(player: userCollection.doc(userId)).toMap()])
      }, SetOptions(merge: true));
    }

    GameModel gameModel = GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});
    List<PlayerMatchModel> players = [];

    for (final e in gameModel.players) {
      if (e.loadedPlayer == null) {
        final data = (await e.player?.get())?.data();
        players.addAll([e.copyWith(loadedPlayer: data == null ? null : FirebaseUserModel.fromMap(data))]);
      }
    }

    return gameModel.copyWith(players: players);
  }

  //LEAVE GAME
  Future<void> leaveGame({required String? gameCode, required List<PlayerMatchModel>? playerModelList}) async {
    if (gameCode == null || playerModelList == null) return;
    if (gameCode.length != 4) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    playerModelList.removeWhere(
      (element) {
        return element.player?.id == userId;
      },
    );
    if (userId != null) {
      await matchesCollection.doc(gameCode).set({
        'players': playerModelList.map(
          (e) {
            return e.toMap();
          },
        ).toList()
      }, SetOptions(merge: true));
    }
  }

  //TOGGLE READY OR UNREADY
  Future<void> toggleReady({required String? gameCode, required List<PlayerMatchModel>? playerModelList}) async {
    if (gameCode == null || playerModelList == null) return;
    if (gameCode.length != 4) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    playerModelList = playerModelList.map(
      (e) {
        if (e.player?.id == userId) {
          e = e.copyWith(isReady: !(e.isReady ?? true));
        }
        return e;
      },
    ).toList();
    if (userId != null) {
      await matchesCollection.doc(gameCode).update({
        'players': playerModelList.map(
          (e) {
            return e.toMap();
          },
        ).toList()
      });
    }
  }

  bool isPlayerReady({required List<PlayerMatchModel>? playerModelList}) {
    if (playerModelList == null) return false;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    return playerModelList.firstWhere((element) => element.player?.id == userId, orElse: () {
          return const PlayerMatchModel(player: null, isReady: false);
        }).isReady ??
        false;
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
