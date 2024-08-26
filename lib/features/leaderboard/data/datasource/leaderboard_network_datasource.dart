import 'package:flutter/material.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utility/network_utility.dart';

class LeaderboardNetworkDatasource {
  const LeaderboardNetworkDatasource();
  Future<bool> networkCall({
    required final String param,
    required final String token,
    required final String sessionId,
  }) async {
    try {
      final response = await NetworkUtility.post(
          url: 'blablabla',
          body: {
            'body1': param,
          },
          authenticationToken: token,
          sessionId: sessionId);
      if (response.isResponseSuccess) {
        return true;
      }
      throw ServerException(
          title: response.responseError.title,
          message: response.responseError.message,
          statusCode: response.statusCode.toString(),
          type: response.responseError.type);
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
