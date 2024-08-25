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

  Future<bool> getIsUserSignedIn() async {
    try {
      final res = await GamesServices.isSignedIn;
      return res;
    } catch (e) {
      throw ServerException(title: 'Sign In Error', message: e.toString(), statusCode: '999');
    }
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
