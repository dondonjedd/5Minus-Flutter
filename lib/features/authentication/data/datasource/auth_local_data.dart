import '../../../../core/errors/exceptions.dart';
import '../../../../core/utility/key_value_utility.dart';

const _string = 'string';

class AuthLocalDatasource {
  const AuthLocalDatasource();
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
