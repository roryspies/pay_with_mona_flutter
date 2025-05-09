import 'package:pay_with_mona/src/core/security/biometrics/biometric_prompt_config.dart';

import 'package:flutter/services.dart';

/// Abstract interface defining platform-specific biometric capabilities.
///
/// Implementations must provide methods to check biometric availability,
/// generate cryptographic key pairs secured by biometrics, and sign data
/// via biometric authentication prompts.
abstract class BiometricPlatformInterface {
  /// Checks whether biometric authentication is supported and enrolled on the device.
  ///
  /// Returns:
  /// - `true` if the device has at least one biometric sensor (fingerprint, face, etc.)
  ///   and the user has enrolled one or more biometrics.
  /// - `false` otherwise.
  ///
  /// Throws:
  /// - [PlatformException] if the underlying platform API call fails unexpectedly.
  Future<bool> isBiometricAvailable();

  /// Generates a new asymmetric key pair tied to the user's biometric identity.
  ///
  /// [config]: UI prompt details shown during biometric enrollment or if user
  ///           interaction is required.
  ///
  /// Returns:
  /// - A Base64-encoded public key string on success.
  ///
  /// Throws:
  /// - [BiometricException] if key generation fails or the operation is canceled.
  Future<String> generatePublicKey(BiometricPromptConfig config);

  /// Signs arbitrary data using biometric authentication.
  ///
  /// [data]: The payload to be signed (e.g. a transaction hash).
  /// [config]: UI prompt configuration for the signing prompt, providing
  ///           titles, subtitles, and cancel button text.
  ///
  /// Returns:
  /// - A Base64-encoded signature string on success.
  ///
  /// Throws:
  /// - [BiometricException] if the signing process fails or is canceled by the user.
  Future<String> createSignature(
    String data,
    BiometricPromptConfig config,
  );
}
