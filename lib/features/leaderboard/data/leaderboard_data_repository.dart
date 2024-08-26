import 'package:dartz/dartz.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utility/typedefs.dart';
import 'datasource/leaderboard_local_datasource.dart';
import 'datasource/leaderboard_network_datasource.dart';

class LeaderboardDataRepository {
  static const _localDatasource = LeaderboardLocalDatasource();
  static const _networkDatasource = LeaderboardNetworkDatasource();
  LeaderboardDataRepository();
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
