import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/active_game/model/deck_model.dart';
import 'package:five_minus/features/create_game/model/active_game_params.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../create_game/model/game_model.dart';
import '../../create_game/model/player_match_model.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import 'active_game_screen.dart';

class ActiveGameController {
  static const String routeName = '/ActiveGameController';
  static Widget screen({
    required ActiveGameParams activeGameParams,
  }) {
    return ActiveGameScreen(
      controller: ActiveGameController._(),
      activeGameParams: activeGameParams,
    );
  }

  ActiveGameController._();
  final matchesCollection = FirebaseFirestore.instance.collection('matches');

  bool isHost({required String? hostId, String? uid}) {
    if (hostId == null) return false;
    if (hostId.isEmpty) return false;
    return hostId == (uid ?? FirebaseAuth.instance.currentUser?.uid);
  }

  StreamSubscription? listenToChanges(GameModel? gameModel, void Function(DocumentSnapshot<Map<String, dynamic>>)? onData) {
    if (gameModel?.code != null) {
      return FirebaseFirestore.instance.collection('matches').doc(gameModel?.code).snapshots().listen(onData);
    }
    return null;
  }

  navigateDashboard(BuildContext context) {
    context.goNamed(DashboardController.routeName);
  }

  Future<GameModel?> initializeGame(String? gameCode) async {
    if (gameCode == null) return null;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await matchesCollection.doc(gameCode).update({'deck': Deck(generateNewRandomDeck: true).toMapList()});

    return GameModel.fromMap((await matchesCollection.doc(gameCode).get()).data() ?? {});
  }

  //DELETE GAME
  deleteGame({required String? gameCode}) async {
    if (gameCode == null) return;
    if (gameCode.isEmpty) return;
    await matchesCollection.doc(gameCode).delete();
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
}
