import '../../../../../errors/exceptions.dart';
import '../../../../../utility/key_value_utility.dart';

const _user = 'user';

class AuthLocalDatasource {
  const AuthLocalDatasource();
  Future<bool> setUserDetails(String? userModel) async {
    try {
      return await KeyValueUtility().setString(_user, userModel ?? '');
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  String? getUserDetails() {
    try {
      return KeyValueUtility().getString(_user);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  Future<bool> clear() async {
    return await KeyValueUtility().remove(_user);
  }
}
