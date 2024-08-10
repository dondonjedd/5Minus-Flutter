import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyValueUtility {
  static SecureKeyValueUtility? _instance;

  SecureKeyValueUtility._internal() {
    _instance = this;
  }

  factory SecureKeyValueUtility() => _instance ?? SecureKeyValueUtility._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> deleteItem({required String key}) async {
    await _storage.delete(
      key: key,
      aOptions: _getAndroidOptions(),
    );
  }

  Future<void> addNewItem({required String key, required String value}) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: _getAndroidOptions(),
    );
  }

  Future<String> getItem({required String key}) async {
    String? res = await _storage.read(
      key: key,
      aOptions: _getAndroidOptions(),
    );
    return res ?? '';
  }

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
        // sharedPreferencesName: 'Test2',
        // preferencesKeyPrefix: 'Test'
      );
}
