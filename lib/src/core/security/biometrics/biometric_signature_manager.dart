import 'package:flutter/services.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_exception.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_platform_factory.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_platform_interface.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_prompt_config.dart';

/// Main class for biometric operations that uses the appropriate platform implementation
class BiometricSignatureManager {
  final BiometricPlatformInterface _platformImpl;

  BiometricSignatureManager({BiometricPlatformInterface? platformImpl})
      : _platformImpl = platformImpl ?? BiometricPlatformFactory.create();

  /// Checks if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _platformImpl.isBiometricAvailable();
    } on PlatformException catch (e) {
      throw BiometricException(
          'Platform error when checking biometric availability', e);
    } catch (e) {
      throw BiometricException('Error checking biometric availability', e);
    }
  }

  /// Generates a public key using biometric authentication
  ///
  /// [config] Configuration for the biometric prompt
  /// Returns the generated public key
  /// Throws [BiometricException] if generation fails
  Future<String> generatePublicKey({BiometricPromptConfig? config}) async {
    final promptConfig = config ?? const BiometricPromptConfig();

    if (!await isBiometricAvailable()) {
      throw BiometricException('Biometric authentication not available');
    }

    return await _platformImpl.generatePublicKey(promptConfig);
  }

  /// Creates a signature for the given data using biometric authentication
  ///
  /// [data] The data to sign
  /// [config] Configuration for the biometric prompt
  /// Returns the generated signature
  /// Throws [BiometricException] if signing fails
  Future<String> createSignature({
    required String data,
    BiometricPromptConfig? config,
  }) async {
    final promptConfig =
        config ?? const BiometricPromptConfig(title: 'Authenticate to sign');

    if (!await isBiometricAvailable()) {
      throw BiometricException('Biometric authentication not available');
    }

    return await _platformImpl.createSignature(data, promptConfig);
  }
}
