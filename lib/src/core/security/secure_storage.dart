import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A secure storage utility for the `pay_with_mona` SDK.
/// Ensures sensitive data is securely stored and retrieved.
class SecureStorage {
  /// Singleton instance
  static final SecureStorage _instance = SecureStorage._internal();

  /// Factory constructor to return the singleton instance
  factory SecureStorage() => _instance;

  SecureStorage._internal();

  /// Instance of FlutterSecureStorage
  final _storage = const FlutterSecureStorage();

  /// Secure storage options for Android & iOS
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true, // Uses EncryptedSharedPreferences
  );

  static const _iOSOptions = IOSOptions(
    accessibility:
        KeychainAccessibility.first_unlock, // Available after first unlock
  );

  //! Save a secure value**
  Future<void> write({required String key, required String value}) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  //! Read a secure value**
  Future<String?> read({required String key}) async {
    return await _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  //! Delete a specific key**
  Future<void> delete({required String key}) async {
    await _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  //! Check if a key exists**
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  //! Clear all secure storage data** (Use with caution)
  Future<void> clear() async {
    await _storage.deleteAll(
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
