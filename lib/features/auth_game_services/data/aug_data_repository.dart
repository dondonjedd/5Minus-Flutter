import 'package:dartz/dartz.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';
import 'package:five_minus/features/auth_game_services/model/pgs_user_model.dart';
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

  ResultVoid signInFirebaseWithPlayGamesServices() async {
    try {
      await _networkDatasource.signInFirebaseWithPlayGamesServices();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultVoid createFirebaseUser(FirebaseUserModel model) async {
    try {
      await _networkDatasource.createFirebaseUser(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<bool> getIsUserSignedInNetwork() async {
    try {
      final result = await _networkDatasource.getIsUserSignedIn();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<PgsUserModel> getUserInfoNetwork() async {
    try {
      final playerId = await _networkDatasource.getPlayerId();
      final username = await _networkDatasource.getPlayerName();
      final score = await _networkDatasource.getPlayerScore();
      final icon = await _networkDatasource.getPlayerIcon();

      return Right(PgsUserModel(icon: icon, id: playerId, points: score, username: username));
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

  ResultCache<String> getUserInfoLocal() {
    try {
      String res = _localDatasource.getUserInfo();
      return Right(res);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultVoid setUserInfoLocal({required String userInfo}) async {
    try {
      await _localDatasource.setUserInfo(userInfo);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }
}
