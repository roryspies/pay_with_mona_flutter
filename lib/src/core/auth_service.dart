import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/core/secure_storage.dart';
import 'package:pay_with_mona/src/core/secure_storage_keys.dart';
import 'package:pay_with_mona/src/core/signatures.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  factory AuthService() => singleInstance;
  AuthService._internal();
  static AuthService singleInstance = AuthService._internal();

  /// ***
  final _apiService = ApiService();
  final _secureStorage = SecureStorage();

  Future<PaymentUserType?> validatePhoneNumberAsMonaUser({
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        "/login/validate",
        data: {
          'phoneNumber': phoneNumber,
        },
      );

      final responseInMap = jsonDecode(response.body) as Map<String, dynamic>;
      final isMonaUser = responseInMap["success"] as bool? ?? false;

      "Is Mona User: $isMonaUser".log();
      if (!isMonaUser) {
        return PaymentUserType.nonMonaUser;
      }

      return PaymentUserType.monaUser;
    } catch (error) {
      "$error".log();
      if (error.toString().toLowerCase().contains("404")) {
        return PaymentUserType.nonMonaUser;
      }

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
    final signatureService = BiometricSignatureHelper();

    final id = const Uuid().v4();
    Map<String, dynamic> payload = {
      "registrationToken": deviceAuth['registrationToken'],
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

      payload['attestationResponse']['publicKey'] = publicKey;

      // sign data
      final rawData = base64Encode(
        utf8.encode(
          jsonEncode(
            deviceAuth['registrationOptions'],
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

      payload['attestationResponse']['signature'] = signature;
      move?.call();

      final response = await commitKeys(
        data: payload,
      );

      "Commit Keys Response ::: $response".log();

      if (response == null) {
        onBioError?.call();
        return;
      }

      if (response['success'] == true) {
        await Future.wait(
          [
            _secureStorage.write(
              key: SecureStorageKeys.hasPasskey,
              value: "true",
            ),
            _secureStorage.write(
              key: SecureStorageKeys.keyID,
              value: response['keyId'] as String,
            ),
            _secureStorage.write(
              key: SecureStorageKeys.monaCheckoutID,
              value: response['mona_checkoutId'] as String,
            ),
          ],
        );

        onSuccess?.call();

        return;
      }
    } on PlatformException catch (e) {
      ('$e').log();
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
          "Content-Type": "application/json",
        },
        data: data,
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }
}
