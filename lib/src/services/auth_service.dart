import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/services/signature_service.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  factory AuthService() => singleInstance;
  AuthService._internal();
  static AuthService singleInstance = AuthService._internal();

  /// ***
  final _apiService = ApiService();

  Future<PaymentUserType?> validatePhoneNumberAsMonaUser({
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        "/login/validate",
        headers: {
          "Content-Type": "application/json",
        },
        data: {
          'phoneNumber': phoneNumber,
        },
      );

      final responseInMap = response.data as Map<String, dynamic>;
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
          //"content-type": "application/json",
          "x-strong-auth-token": strongAuthToken,
          "x-mona-key-exchange": "true",
        },
      );

      final responseInMap = response.data as Map<String, dynamic>;
      responseInMap.log();

      return response.data as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
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
      );

      final responseInMap = response.data as Map<String, dynamic>;
      responseInMap.log();

      return response.data as Map<String, dynamic>;
    } catch (error) {
      "$error".log();

      return null;
    }
  }

  Future<void> enrolLocalAuth2({
    required Map<String, dynamic> deviceAuth,
    Function()? onSuccess,
    Function()? move,
    Function()? onBioError,
  }) async {
    final signatureService = SignatureService();
    ('_enrolLocalAuth').log();

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
        await Future.delayed(Duration(seconds: 1));
      }
      final String? publicKey = await signatureService.getPublicKey();

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

      final signature = await signatureService.generateSignature(
        rawData: rawData,
      );

      if (signature == null || signature.isEmpty) {
        onBioError?.call();
        return;
      }

      payload['attestationResponse']['signature'] = signature;
      move?.call();

      // commit keys
      final response = await commitKeys(
        data: payload,
      );

      if (response == null) {
        onBioError?.call();
        return;
      }

      if (response['success'] == true) {
        //Prefs.setBool(Prefs.hasPasskey, true);

        ///Prefs.setString(Prefs.keyId, res['keyId']);
        /* Prefs.setString(
          "${callingRef.read(serverEnvironmentToggleProvider).currentEnvironment.label}_keyId",
          res['keyId'],
        ); */

        onSuccess?.call();

        return;
      }
    } on PlatformException catch (e) {
      ('$e').log();
      onBioError?.call();
    }
  }
}
