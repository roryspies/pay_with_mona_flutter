import 'dart:io';

import 'package:biometric_signature/android_config.dart';
import 'package:biometric_signature/biometric_signature.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_signature/local_auth_signature.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';

class SignatureService {
  factory SignatureService() => singleInstance;
  SignatureService._internal();
  static SignatureService singleInstance = SignatureService._internal();

  List<String> unsupportedModels = [
    "CP3706AS",
  ];

  Future<bool> isBiometricAvailableAndEnrolled() async {
    final localAuth = LocalAuthentication();
    try {
      final isAvailable = await localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final availableBiometrics = await localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getPublicKey({
    String? title,
  }) async {
    if (!await isBiometricAvailableAndEnrolled()) {
      return '';
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      'Running on ${androidInfo.model}'.log();
      const key = 'ng.mona.app';

      if (!unsupportedModels.contains(androidInfo.model)) {
        final biometricSignature = BiometricSignature();
        return await biometricSignature.createKeys(
          androidConfig: AndroidConfig(
            useDeviceCredentials: false,
          ),
        );
      } else {
        final localAuth = LocalAuthSignature.instance;
        return await localAuth.createKeyPair(
          key,
          AndroidPromptInfo(
            title: title ?? 'Scan your biometrics',
            subtitle: 'Biometrics auth',
            negativeButton: 'CANCEL',
          ),
          IOSPromptInfo(
            reason: 'Scan your biometrics',
          ),
        );
      }
    } else {
      final biometricSignature = BiometricSignature();
      return await biometricSignature.createKeys(
        androidConfig: AndroidConfig(useDeviceCredentials: false),
      );
    }
  }

  Future<String?> generateSignature({
    required String rawData,
    String? title,
    VoidCallback? onCancel,
  }) async {
    if (!await isBiometricAvailableAndEnrolled()) {
      return '';
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      'Running on ${androidInfo.model}'.log();
      const key = 'ng.mona.app';

      if (!unsupportedModels.contains(androidInfo.model)) {
        try {
          final biometricSignature = BiometricSignature();

          return await biometricSignature.createSignature(
            options: {
              "payload": rawData,
              "promptMessage": title ?? "Unlock with your fingerprint",
            },
          );
        } catch (error) {
          "SIGNATURES.DART ==>> generateSignature ==>> biometricSignature.createSignature ==>> Biometric authentication failed: $error"
              .log();

          return null;
        }
      } else {
        try {
          final localAuth = LocalAuthSignature.instance;

          return await localAuth.sign(
            key,
            rawData,
            AndroidPromptInfo(
              title: title ?? 'Unlock with your fingerprint',
              subtitle: 'Biometrics auth',
              negativeButton: 'CANCEL',
            ),
            IOSPromptInfo(
              reason: 'Unlock with your fingerprint',
            ),
          );
        } catch (error) {
          "SIGNATURES.DART ==>> generateSignature ==>> localAuth.sign ==>> Biometric authentication failed: $error"
              .log();
          return null;
        }
      }
    } else {
      try {
        final biometricSignature = BiometricSignature();

        return await biometricSignature.createSignature(
          options: {
            "payload": rawData,
            "promptMessage": title ?? "Unlock with your fingerprint",
          },
        );
      } catch (error) {
        "SIGNATURES.DART ==>> generateSignature ==>> biometricSignature.createSignature ==>> Biometric authentication failed: $error"
            .log();

        return null;
      }
    }
  }
}
