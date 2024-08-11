import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utility/typedefs.dart';
import 'datasource/auth_local_data.dart';
import 'datasource/auth_network_data.dart';

class AuthRepositoryData {
  static const _localDatasource = AuthLocalDatasource();
  static const _networkDatasource = AuthNetworkDatasource();
  AuthRepositoryData();
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

  ResultFutureServer<bool> signInWithEmailAndPassword({required String emailAddress, required String password}) async {
    try {
      final result = await _networkDatasource.signInEmailPassword(emailAddress: emailAddress, password: password);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<bool> registerEmailPassword({required String emailAddress, required String password}) async {
    try {
      final result = await _networkDatasource.registerEmailPassword(emailAddress: emailAddress, password: password);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<bool> signOut() async {
    try {
      final result = await _networkDatasource.signOut();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<bool> signInGoogle() async {
    try {
      final result = await _networkDatasource.signInGoogle();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }
  // ResultCache<String> string() {
  //   try {
  //     String? model = _localDatasource.string();
  //     return Right(model);
  //   } on CacheException catch (e) {
  //     return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
  //   }
  // }

  // ResultVoid setString({required String model}) async {
  //   try {
  //     await _localDatasource.setString(model);
  //     return const Right(null);
  //   } on CacheException catch (e) {
  //     return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
  //   }
  // }
}
