import 'package:five_minus/core/data/datasource/user_remote_datasource.dart';
import 'package:five_minus/features/auth_game_services/model/firebase_user_model.dart';

class UserRepository {
  UserRepository({UserRemoteDatasource? datasource}) : _datasource = datasource ?? const UserRemoteDatasource();

  final UserRemoteDatasource _datasource;

  Future<FirebaseUserModel?> fetchFirebaseUser(String id) async {
    final data = await _datasource.fetchUser(id);
    if (data == null) return null;
    return FirebaseUserModel.fromMap(data);
  }

  Future<void> upsertFirebaseUser(FirebaseUserModel model, {required String id}) {
    return _datasource.upsertUser(model.toMap(id: id));
  }
}
