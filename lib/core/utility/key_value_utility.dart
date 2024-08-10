import 'package:shared_preferences/shared_preferences.dart';

class KeyValueUtility {
  static KeyValueUtility? _instance;

  KeyValueUtility._internal() {
    _instance = this;
  }

  factory KeyValueUtility() => _instance ?? KeyValueUtility._internal();

  late SharedPreferences _sharedPreferences;

  Future<void> initialise() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  //getter
  int? getInt(final String key) {
    return _sharedPreferences.getInt(key);
  }

  bool? getBool(final String key) {
    return (_sharedPreferences).getBool(key);
  }

  double? getDouble(final String key) {
    return (_sharedPreferences).getDouble(key);
  }

  String? getString(final String key) {
    return (_sharedPreferences).getString(key);
  }

  List<String>? getStringList(final String key) {
    return (_sharedPreferences).getStringList(key);
  }

  Future<bool> setInt(final String key, final int value) {
    return (_sharedPreferences).setInt(key, value);
  }

  //setter
  Future<bool> setBool(final String key, final bool value) {
    return (_sharedPreferences).setBool(key, value);
  }

  Future<bool> setDouble(final String key, final double value) {
    return (_sharedPreferences).setDouble(key, value);
  }

  Future<bool> setString(final String key, final String value) {
    return (_sharedPreferences).setString(key, value);
  }

  Future<bool> setStringList(final String key, final List<String> value) {
    return (_sharedPreferences).setStringList(key, value);
  }

  Future<bool> clear() async {
    return (_sharedPreferences).clear();
  }
}
