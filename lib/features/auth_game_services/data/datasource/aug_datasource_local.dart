import '../../../../core/errors/exceptions.dart';
import '../../../../core/utility/key_value_utility.dart';

const _isSignedIn = 'isSignedIn';

class AugLocalDatasource {
  const AugLocalDatasource();
  Future<bool> setIsSignedIn(final bool bol) async {
    try {
      return await KeyValueUtility().setBool(_isSignedIn, bol);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  bool getIsSignedIn() {
    try {
      return KeyValueUtility().getBool(_isSignedIn) ?? false;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
