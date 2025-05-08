import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_signature/local_auth_signature.dart';
import 'package:biometric_signature/biometric_signature.dart';
import 'package:biometric_signature/android_config.dart';
import 'package:biometric_signature/ios_config.dart';

/// A utility class for managing biometric signatures and authentication
class BiometricSignatureHelper {
  factory BiometricSignatureHelper() => singleInstance;
  BiometricSignatureHelper._internal();
  static BiometricSignatureHelper singleInstance =
      BiometricSignatureHelper._internal();

  /// List of device models with known biometric signature limitations
  static final List<String> _unsupportedModels = [
    "CP3706AS",
  ];

  /// Checks if biometric authentication is available and at least one method is enrolled
  ///
  /// Returns a [Future] that completes with a boolean indicating biometric availability
  Future<bool> isBiometricAvailable() async {
    try {
      final LocalAuthentication localAuth = LocalAuthentication();
      final isAvailable = await localAuth.canCheckBiometrics;

      if (!isAvailable) return false;

      final availableBiometrics = await localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Generates a public key using biometric authentication
  ///
  /// [title] Optional title for the biometric prompt
  /// Returns a [Future] with the generated public key or null if generation fails
  Future<String?> generatePublicKey({String? title}) async {
    if (!await isBiometricAvailable()) {
      return null;
    }

    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      const String key = 'pay_with_mona';

      if (!_unsupportedModels.contains(androidInfo.model)) {
        final BiometricSignature biometricSignature = BiometricSignature();
        return await biometricSignature.createKeys(
          androidConfig: AndroidConfig(useDeviceCredentials: true),
          iosConfig: IosConfig(useDeviceCredentials: true),
        );
      } else {
        final LocalAuthSignature localAuth = LocalAuthSignature.instance;
        return await localAuth.createKeyPair(
          key,
          AndroidPromptInfo(
            title: title ?? 'Biometric Authentication',
            subtitle: 'Authenticate to generate key',
            negativeButton: 'Cancel',
          ),
          IOSPromptInfo(reason: 'Authenticate to generate key'),
        );
      }
    }

    // For iOS and other platforms
    final BiometricSignature biometricSignature = BiometricSignature();
    return await biometricSignature.createKeys(
      androidConfig: AndroidConfig(useDeviceCredentials: true),
      iosConfig: IosConfig(useDeviceCredentials: true),
    );
  }

  /// Generates a signature using biometric authentication
  ///
  /// [rawData] The data to be signed
  /// [title] Optional title for the biometric prompt
  /// [onCancel] Optional callback for cancellation
  /// Returns a [Future] with the generated signature or null if signing fails
  Future<String?> createSignature({
    required String rawData,
    String? title,
    VoidCallback? onCancel,
  }) async {
    if (!await isBiometricAvailable()) {
      return null;
    }

    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      const String key = 'ng.mona.app';

      if (!_unsupportedModels.contains(androidInfo.model)) {
        try {
          final biometricSignature = BiometricSignature();
          return await biometricSignature.createSignature(
            options: {
              "payload": rawData,
              "promptMessage": title ?? "Authenticate to sign",
            },
          );
        } catch (error) {
          // Log or handle specific error scenarios
          return null;
        }
      } else {
        try {
          final localAuth = LocalAuthSignature.instance;
          return await localAuth.sign(
            key,
            rawData,
            AndroidPromptInfo(
              title: title ?? 'Authenticate to sign',
              subtitle: 'Biometric Authentication',
              negativeButton: 'Cancel',
            ),
            IOSPromptInfo(reason: 'Authenticate to sign'),
          );
        } catch (error) {
          // Log or handle specific error scenarios
          return null;
        }
      }
    }

    // For iOS and other platforms
    try {
      final biometricSignature = BiometricSignature();
      return await biometricSignature.createSignature(
        options: {
          "payload": rawData,
          "promptMessage": title ?? "Authenticate to sign",
        },
      );
    } catch (error) {
      // Log or handle specific error scenarios
      return null;
    }
  }
}
