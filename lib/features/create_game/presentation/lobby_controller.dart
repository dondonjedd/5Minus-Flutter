import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/utility/loading_overlay_utility.dart';
import 'package:five_minus/features/create_game/model/game_model.dart';
import 'package:five_minus/features/dashboard/presentation/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'lobby_screen.dart';

class LobbyController {
  static const String routeName = '/LobbyController';
  static Widget screen() {
    return LobbyScreen(controller: LobbyController._());
  }

  LobbyController._();
  String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  final matchesCollection = FirebaseFirestore.instance.collection('matches');
  final userCollection = FirebaseFirestore.instance.collection('users');

  deleteGame(String gameCode) async {
    if (gameCode.isEmpty) return;
    await matchesCollection.doc(gameCode).delete();
  }

  Future<GameModel> createGame() async {
    String gameCode = '';

    while (gameCode.isEmpty) {
      String tmpGamecode = generateGameCode();
      bool isCodeAvailable = await isGameCodeAvailable(tmpGamecode);
      if (isCodeAvailable) {
        gameCode = tmpGamecode;
      }
    }

    await matchesCollection
        .doc(gameCode)
        .set(GameModel(code: gameCode, players: [userCollection.doc(FirebaseAuth.instance.currentUser?.uid ?? '')], gameType: 0).toMap());
    return GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});
  }

  String generateGameCode() {
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(4, (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  Future<bool> isGameCodeAvailable(String gameCode) async {
    final res = await matchesCollection.doc(gameCode).get();

    if (res.exists) {
      return false;
    } else {
      return true;
    }
  }

  navigateDashboard(BuildContext context) {
    context.goNamed(DashboardController.routeName);
  }
}
