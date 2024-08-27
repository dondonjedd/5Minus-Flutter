import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/data/configuration_data.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';

import '../../../../core/errors/exceptions.dart';

class AugNetworkDatasource {
  const AugNetworkDatasource();

  Future<void> signInPlayGamesServices() async {
    try {
      await GamesServices.signIn();
    } catch (e) {
      throw ServerException(title: 'Sign In Error', message: e.toString(), statusCode: '999');
    }
  }

  Future<FirebaseUserModel?> signInFirebaseWithPlayGamesServices() async {
    try {
      final authCode = await GamesServices.getAuthCode(ConfigurationData.clientId);
      if (authCode?.isNotEmpty ?? false) FirebaseAuth.instance.signInWithCredential(PlayGamesAuthProvider.credential(serverAuthCode: authCode!));
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Sign In Error', statusCode: '999', type: '2');
    } catch (e) {
      throw ServerException(title: 'Sign In Error', message: e.toString(), statusCode: '999');
    }
    return null;
  }

  Future<FirebaseUserModel?> createFirebaseUser(FirebaseUserModel model) async {
    try {
      final userCollection = _getUserCollection();
      if (userCollection == null) return null;
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      await userCollection.doc(uid).set(model.toMap());
      return await getUserModel(uid);
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Create user error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<FirebaseUserModel?> getUserModel(String uid) async {
    try {
      final userCollection = _getUserCollection();
      if (userCollection == null) return null;
      final snapshot = await userCollection.doc(uid).get();
      if (snapshot.data() == null) return null;
      return FirebaseUserModel.fromMap(snapshot.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Create user error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<bool> getIsUserSignedIn() async {
    try {
      final res = await GamesServices.isSignedIn;
      return res;
    } catch (e) {
      throw ServerException(title: 'Sign In Error', message: e.toString(), statusCode: '999');
    }
  }

  Future<String> getPlayerId() async {
    try {
      final res = await GamesServices.getPlayerID();
      return res ?? '';
    } catch (e) {
      throw ServerException(title: 'Get player info error', message: e.toString(), statusCode: '999');
    }
  }

  Future<String> getPlayerName() async {
    try {
      final res = await GamesServices.getPlayerName();
      return res ?? '';
    } catch (e) {
      throw ServerException(title: 'Get player info error', message: e.toString(), statusCode: '999');
    }
  }

  Future<int> getPlayerScore() async {
    try {
      final res = await GamesServices.getPlayerScore(androidLeaderboardID: ConfigurationData.androidLeaderboardId);
      return res ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String> getPlayerIcon() async {
    try {
      final res = await GamesServices.getPlayerIconImage();
      return res ?? '';
    } catch (e) {
      throw ServerException(title: 'Get player info error', message: e.toString(), statusCode: '999');
    }
  }

  CollectionReference<Map<String, dynamic>>? _getUserCollection() {
    return FirebaseFirestore.instance.collection("users");
  }

  Future<bool> networkCall({
    required final String param,
    required final String token,
    required final String sessionId,
  }) async {
    try {
      // final response = await NetworkUtility.post(
      //     url: '${environment.hostAddress}/blablabla',
      //     body: {
      //       'body1': param,
      //     },
      //     authenticationToken: token,
      //     sessionId: sessionId);
      // if (response.isResponseSuccess) {
      //   return true;
      // }
      throw const ServerException(title: 'Login error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    } on ServerException {
      rethrow;
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      throw ServerException(
        message: e.toString(),
        statusCode: '505',
      );
    }
  }
}
