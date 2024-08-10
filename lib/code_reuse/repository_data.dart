import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../core/errors/exceptions.dart';
import '../core/errors/failures.dart';
import '../core/utility/key_value_utility.dart';
import '../core/utility/network_utility.dart';
import '../core/utility/typedefs.dart';

class RepositoryData {
  static const _localDatasource = LocalDatasource();
  static const _networkDatasource = NetworkDatasource();

  RepositoryData();

  // result.fold(
  //   (failure) {
  //     DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
  //   },
  //   (success) {
  //   },
  // );

  static ResultFutureServer<bool> callNetwork({
    required String param,
    required String token,
    required String sessionId,
    required String hostAddress,
  }) async {
    try {
      final result = await _networkDatasource.networkCall(
        param: param,
        token: token,
        sessionId: sessionId,
        hostAddress: hostAddress,
      );

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultCache<String> string() {
    try {
      String? model = _localDatasource.string();
      return Right(model);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultVoid setString({required String model}) async {
    try {
      await _localDatasource.setString(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }
}

const _string = 'string';

class LocalDatasource {
  const LocalDatasource();

  Future<bool> setString(final String token) async {
    try {
      return await KeyValueUtility().setString(_string, token);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  String string() {
    try {
      return KeyValueUtility().getString(_string) ?? '';
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}

class NetworkDatasource {
  const NetworkDatasource();

  Future<bool> networkCall({
    required final String param,
    required final String token,
    required final String sessionId,
    required final String hostAddress,
  }) async {
    try {
      final response = await NetworkUtility.post(
          url: '$hostAddress/blablabla',
          body: {
            'body1': param,
          },
          authenticationToken: token,
          sessionId: sessionId);

      if (response.isResponseSuccess) {
        //do something with response.responseMap
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
