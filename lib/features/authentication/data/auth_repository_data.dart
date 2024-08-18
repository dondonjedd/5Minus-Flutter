import 'package:dartz/dartz.dart';
import 'package:five_minus/features/authentication/model/user_model.dart';
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

//**************************SIGN IN */
  ResultFutureServer<UserModel?> signInWithEmailAndPassword({required String emailAddress, required String password}) async {
    try {
      final result = await _networkDatasource.signInEmailPassword(emailAddress: emailAddress, password: password);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<UserModel?> signInGoogle() async {
    try {
      final result = await _networkDatasource.signInGoogle();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  //**************************SIGN IN */
  //**************************REGISTER */
  ResultFutureServer<UserModel?> registerEmailPassword({required String emailAddress, required String password}) async {
    try {
      final result = await _networkDatasource.registerEmailPassword(emailAddress: emailAddress, password: password);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  //**************************REGISTER */
  //**************************LOG OUT */
  ResultFutureServer<bool> signOut() async {
    try {
      final result = await _networkDatasource.signOut();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }
  //**************************LOG OUT */

  ResultFutureServer<UserModel?> getUserModelNetwork() async {
    try {
      final result = await _networkDatasource.getUserModel();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<UserModel?> updateUserNetwork(UserModel? usermodel) async {
    try {
      final result = await _networkDatasource.updateUser(usermodel);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultFutureServer<bool> sendEmailVerification() async {
    try {
      final result = await _networkDatasource.sendEmailVerification();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(type: e.type, title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultCache<UserModel?> getUserDetails() {
    try {
      String? model = _localDatasource.getUserDetails();
      if (model == null) throw const CacheException(message: 'Not initialized');
      return Right(UserModel.fromJson(model));
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  ResultVoid setUserDetails({required UserModel? userModel}) async {
    try {
      await _localDatasource.setUserDetails(userModel?.toJson());
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }

  Future<ResultCache<bool>> clearAuth() async {
    try {
      final res = await _localDatasource.clear();
      return Right(res);
    } on CacheException catch (e) {
      return Left(CacheFailure(title: e.title, message: e.message, statusCode: e.statusCode));
    }
  }
}
