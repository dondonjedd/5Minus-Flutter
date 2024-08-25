import 'dart:ffi';

import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utility/typedefs.dart';
import 'datasource/aug_datasource_local.dart';
import 'datasource/aug_datasource_network.dart';

class AugDataRepository {
  static const _localDatasource = AugLocalDatasource();
  static const _networkDatasource = AugNetworkDatasource();
  AugDataRepository();
// result.fold(
//   (failure) {
//     DialogUtility().showError(context, title: failure.title, message: failure.errorMessage, type: failure.type);
//   },
//   (success) {
//   },
// );

  ResultVoid signInPlayGamesServices() async {
    try {
      await _networkDatasource.signInPlayGamesServices();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<bool> getIsUserSignedIn() async {
    try {
      final result = await _networkDatasource.getIsUserSignedIn();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  static ResultFutureServer<bool> callNetwork({
    required String param,
    required String token,
    required String sessionId,
  }) async {
    try {
      final result = await _networkDatasource.networkCall(
        param: param,
        token: token,
        sessionId: sessionId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultCache<bool> getIsSignedInLocal() {
    try {
      bool res = _localDatasource.getIsSignedIn();
      return Right(res);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultVoid setIsSignedIn({required bool bol}) async {
    try {
      await _localDatasource.setIsSignedIn(bol);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }
}
