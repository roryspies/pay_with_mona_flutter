import 'package:biometric_signature/biometric_signature.dart';
import 'package:biometric_signature/ios_config.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_exception.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_platform_interface.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_prompt_config.dart';
import 'dart:async';

/// iOS-specific implementation of biometric operations.
///
/// Utilizes the platform’s local_auth-based [BiometricSignature] SDK to:
/// 1. Check for enrolled biometrics on the device
/// 2. Generate cryptographic key pairs secured by biometrics
/// 3. Sign arbitrary payloads via biometric prompts
class IOSBiometricPlatform implements BiometricPlatformInterface {
  final BiometricSignature _biometricSignature;

  /// Constructs an [IOSBiometricPlatform].
  ///
  /// [biometricSignature]: SDK that handles key and signature operations
  ///   on iOS, backed by Secure Enclave or Keychain.
  IOSBiometricPlatform({
    required BiometricSignature biometricSignature,
  }) : _biometricSignature = biometricSignature;

  /// Checks whether biometric authentication is available on the device.
  ///
  /// Returns:
  /// - `true` if the device supports and has at least one enrolled biometric
  ///   (Touch ID, Face ID, etc.).
  /// - `false` otherwise.
  ///
  /// Throws:
  /// - [PlatformException] if the underlying system call fails.
  @override
  Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    final canCheck = await localAuth.canCheckBiometrics;
    if (!canCheck) return false;

    final enrolled = await localAuth.getAvailableBiometrics();
    return enrolled.isNotEmpty;
  }

  /// Generates a new asymmetric key pair in the Secure Enclave.
  ///
  /// [config]: Prompt details shown to the user if biometric UI is needed.
  ///
  /// Returns:
  /// - A Base64-encoded public key string.
  ///
  /// Throws:
  /// - [BiometricException] if key generation fails or user cancels.
  @override
  Future<String> generatePublicKey(BiometricPromptConfig config) async {
    try {
      final key = await _biometricSignature.createKeys(
        //androidConfig: AndroidConfig(useDeviceCredentials: true),
        iosConfig: IosConfig(useDeviceCredentials: true),
      );
      if (key == null) {
        throw BiometricException('generatePublicKey returned null');
      }
      return key;
    } catch (e, st) {
      throw BiometricException('Failed to generate key', e, st);
    }
  }

  /// Signs the provided [data] using biometric authentication.
  ///
  /// [data]: The payload to sign (e.g., transaction hash).
  /// [config]: UI prompt text configuration for the biometric prompt.
  ///
  /// Returns:
  /// - A Base64-encoded signature string.
  ///
  /// Throws:
  /// - [BiometricException] if signing fails or is cancelled.
  @override
  Future<String> createSignature(
      String data, BiometricPromptConfig config) async {
    try {
      final sig = await _biometricSignature.createSignature(
        options: {
          'payload': data,
          'promptMessage': config.title,
        },
      );
      if (sig == null) {
        throw BiometricException('createSignature returned null');
      }
      return sig;
    } catch (e, st) {
      throw BiometricException('Failed to create signature', e, st);
    }
  }
}
