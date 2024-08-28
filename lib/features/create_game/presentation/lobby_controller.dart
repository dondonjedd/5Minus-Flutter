import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/create_game/model/game_model.dart';
import 'package:five_minus/features/create_game/model/lobby_params.dart';
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
  bool isHost(String uid) {
    return uid == FirebaseAuth.instance.currentUser?.uid;
  }

  //*******************HOST********************
  String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  final matchesCollection = FirebaseFirestore.instance.collection('matches');
  final userCollection = FirebaseFirestore.instance.collection('users');

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
      await matchesCollection
          .doc(gameCode)
          .set(GameModel(hostId: hostId, code: gameCode, players: [userCollection.doc(hostId)], gameType: 0).toMap());
    }
    return GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});
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
        'players': FieldValue.arrayUnion([userCollection.doc(userId)])
      }, SetOptions(merge: true));
    }

    return GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});
  }

  //LEAVE GAME
  Future<void> leaveGame(String? gameCode) async {
    if (gameCode == null) return;
    if (gameCode.length != 4) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      await matchesCollection.doc(gameCode).set({
        'players': FieldValue.arrayRemove([userCollection.doc(userId)])
      }, SetOptions(merge: true));
    }
  }
  //*******************CLIENT********************

  navigateDashboard(BuildContext context) {
    context.goNamed(DashboardController.routeName);
  }
}
