import "dart:convert";
import "dart:io";
import "package:flutter/services.dart";
import "package:pay_with_mona/src/core/api/api_endpoints.dart";
import "package:pay_with_mona/src/core/api/api_service.dart";
import "package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart";
import "package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart";
import "package:pay_with_mona/src/core/security/biometrics/biometrics_service.dart";
import "package:pay_with_mona/src/core/generators/uuid_generator.dart";
import "package:pay_with_mona/src/utils/extensions.dart";

class AuthService {
  factory AuthService() => singleInstance;
  AuthService._internal();
  static AuthService singleInstance = AuthService._internal();

  /// ***
  final _apiService = ApiService();
  final _secureStorage = SecureStorage();

  Future<Map<String, dynamic>?> validatePII({
    String? phoneNumber,
    String? bvn,
    String? dob,
    String? userKeyID,
  }) async {
    try {
      final doNotUseBody = (phoneNumber == null && bvn == null && dob == null);

      if (userKeyID == null && doNotUseBody) {
        return null;
      }

      final response = await _apiService.post(
        APIEndpoints.validatePII,
        headers: (userKeyID != null && doNotUseBody)
            ? {
                "x-client-type": "bioApp",
                "x-mona-key-id": userKeyID,
                "content-Type": "application/json",
              }
            : null,
        data: (phoneNumber == null && bvn == null && dob == null)
            ? {"": ""}
            : {
                if (phoneNumber != null) "phoneNumber": phoneNumber,
                if (bvn != null) "bvn": bvn,
                if (dob != null) "dob": dob,
              },
      );

      return (jsonDecode(response.body) as Map<String, dynamic>)["data"]
          as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  Future<Map<String, dynamic>?> loginWithStrongAuth({
    required String strongAuthToken,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        "/login",
        headers: {
          "x-strong-auth-token": strongAuthToken,
          "x-mona-key-exchange": "true",
        },
        data: {
          "phone": null,
        },
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  Future<void> signAndCommitAuthKeys({
    required Map<String, dynamic> deviceAuth,
    Function()? onSuccess,
    Function()? move,
    Function()? onBioError,
  }) async {
    final signatureService = BiometricService();

    final id = UUIDGenerator.v4();
    Map<String, dynamic> payload = {
      "registrationToken": deviceAuth["registrationToken"],
      "attestationResponse": {
        "id": id,
        "rawId": id,
      }
    };

    try {
      if (Platform.isIOS) {
        //! to give face ID time to cook
        await Future.delayed(Duration(milliseconds: 1500));
      }

      final publicKey = await signatureService.generatePublicKey();

      if (publicKey == null || publicKey.isEmpty) {
        onBioError?.call();
        return;
      }

      payload["attestationResponse"]["publicKey"] = publicKey;

      // sign data
      final rawData = base64Encode(
        utf8.encode(
          jsonEncode(
            deviceAuth["registrationOptions"],
          ),
        ),
      );

      final signature = await signatureService.createSignature(
        rawData: rawData,
      );

      if (signature == null || signature.isEmpty) {
        onBioError?.call();
        return;
      }

      payload["attestationResponse"]["signature"] = signature;
      move?.call();

      final response = await commitKeys(
        data: payload,
      );

      "Commit Keys Response ::: $response".log();

      if (response == null) {
        onBioError?.call();
        return;
      }

      if (response["success"] == true) {
        await Future.wait(
          [
            _secureStorage.write(
              key: SecureStorageKeys.hasPasskey,
              value: "true",
            ),
            _secureStorage.write(
              key: SecureStorageKeys.keyID,
              value: response["keyId"] as String,
            ),
            _secureStorage.write(
              key: SecureStorageKeys.monaCheckoutID,
              value: response["mona_checkoutId"] as String,
            ),
          ],
        );

        onSuccess?.call();

        return;
      }
    } on PlatformException catch (e) {
      ("$e").log();
      onBioError?.call();
    }
  }

  Future<Map<String, dynamic>?> commitKeys({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _apiService.post(
        "/keys/commit",
        headers: {
          "content-type": "application/json",
        },
        data: data,
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  /// Deletes all entries in secure storage for this app.
  ///
  /// Use with caution, as this will remove all persisted sensitive data.
  ///
  /// Throws:
  /// - [PlatformException] if the operation fails.
  Future<void> permanentlyClearKeys() async {
    try {
      await _secureStorage.permanentlyClearKeys();
      "Cleared Secure Storage Keys".log();
    } catch (e, stackTrace) {
      throw Exception("Failed to clear secure storage keys: $e\n$stackTrace");
    }
  }

  /// Deletes all entries using default options (no platform-specific settings).
  ///
  /// Provided for compatibility; preferred method is [clear()].
  Future<void> clearKeys() async {
    try {
      await _secureStorage.clearKeys();
      "Deleted Storage Keys".log();
    } catch (e, stackTrace) {
      throw Exception("Failed to delete storage keys: $e\n$stackTrace");
    }
  }
}
