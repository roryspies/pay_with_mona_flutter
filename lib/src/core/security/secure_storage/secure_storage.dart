import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart';

/// A secure singleton wrapper for FlutterSecureStorage.
///
/// Provides type-safe, platform-aware methods for handling sensitive data
/// like API keys, tokens, and other credentials. It uses EncryptedSharedPreferences
/// on Android and the Keychain service on iOS for optimal security.
class SecureStorage {
  /// Singleton instance of [SecureStorage].
  static final SecureStorage _instance = SecureStorage._internal();

  /// Factory constructor returns the shared singleton.
  factory SecureStorage() => _instance;

  /// Internal constructor for singleton initialization.
  SecureStorage._internal();

  /// Underlying secure storage plugin instance.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Android-specific storage options.
  ///
  /// Uses EncryptedSharedPreferences for strong encryption at rest.
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  /// iOS-specific storage options.
  ///
  /// Uses Keychain with `first_unlock` accessibility to allow
  /// access only after the device has been unlocked at least once.
  static const IOSOptions _iOSOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  /// Writes a value to secure storage.
  ///
  /// [key]: The identifier for the stored value.
  /// [value]: The sensitive data to store (e.g., tokens, IDs).
  ///
  /// Throws:
  /// - [PlatformException] if the write operation fails.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  /// Reads a value from secure storage.
  ///
  /// [key]: The identifier for the stored value.
  ///
  /// Returns:
  /// - The stored value, or `null` if not found.
  ///
  /// Throws:
  /// - [PlatformException] if the read operation fails.
  Future<String?> read({required String key}) async {
    return await _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  /// Deletes a specific key-value pair from secure storage.
  ///
  /// [key]: The identifier for the entry to remove.
  ///
  /// Throws:
  /// - [PlatformException] if the delete operation fails.
  Future<void> delete({required String key}) async {
    await _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  /// Checks whether a key exists in secure storage.
  ///
  /// [key]: The identifier to check for existence.
  ///
  /// Returns:
  /// - `true` if the key exists, `false` otherwise.
  ///
  /// Throws:
  /// - [PlatformException] if the check operation fails.
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  /// Deletes all entries in secure storage for this app.
  ///
  /// Use with caution, as this will remove ALL persisted sensitive data,
  /// including the merchant API key.
  ///
  /// Throws:
  /// - [PlatformException] if the operation fails.
  Future<void> permanentlyClearAllKeys() async {
    try {
      await _storage.deleteAll(
        aOptions: _androidOptions,
        iOptions: _iOSOptions,
      );
    } catch (e, stackTrace) {
      throw Exception('Failed to clear secure storage: $e\n$stackTrace');
    }
  }

  // --- NEW METHOD ---
  /// Deletes all entries EXCEPT for the `merchantAPIKey`.
  ///
  /// This method is ideal for logging a user out or clearing session data
  /// without forcing them to re-enter their permanent merchant API key.
  /// It works by reading the key, deleting everything, and then writing it back.
  Future<void> clearAllExceptMerchantAPIKey() async {
    try {
      final merchantAPIKey = await read(
        key: SecureStorageKeys.merchantAPIKey,
      );
      final merchantPublicKey = await read(
        key: SecureStorageKeys.merchantKey,
      );

      await permanentlyClearAllKeys();

      if (merchantAPIKey != null) {
        await write(
          key: SecureStorageKeys.merchantAPIKey,
          value: merchantAPIKey,
        );
      }
      if (merchantPublicKey != null) {
        await write(
          key: SecureStorageKeys.merchantKey,
          value: merchantPublicKey,
        );
      }
    } catch (e, stackTrace) {
      throw Exception(
        'Failed to clear storage while preserving merchantAPIKey: $e\n$stackTrace',
      );
    }
  }
}
