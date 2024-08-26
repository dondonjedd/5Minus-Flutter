import '../../../../core/errors/exceptions.dart';
import '../../../../core/utility/key_value_utility.dart';

const _userInfo = 'userInfo';

class AugLocalDatasource {
  const AugLocalDatasource();
  Future<bool> setUserInfo(final String userInfo) async {
    try {
      return await KeyValueUtility().setString(_userInfo, userInfo);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  String getUserInfo() {
    try {
      return KeyValueUtility().getString(_userInfo) ?? '';
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
