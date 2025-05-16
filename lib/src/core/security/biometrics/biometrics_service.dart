import 'package:pay_with_mona/src/core/security/biometrics/biometric_exception.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_prompt_config.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_signature_manager.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';

/// A high-level service that wraps biometric signature operations.
///
/// Provides methods to sign arbitrary data (e.g. transaction hashes),
/// generate new public keys, and handle underlying exceptions gracefully.
class BiometricService {
  /// The low-level manager that interacts with the platform’s biometric APIs.
  final BiometricSignatureManager _biometricManager;

  /// Creates a [BiometricService], optionally injecting a custom manager
  /// (useful for testing or alternative implementations).
  ///
  /// By default, it instantiates the platform’s standard [BiometricSignatureManager].
  BiometricService({BiometricSignatureManager? biometricManager})
      : _biometricManager = biometricManager ?? BiometricSignatureManager();

  /// Signs an already-hashed transaction payload with the user’s biometric.
  ///
  /// Returns the base64‐encoded signature string on success, or `null`
  /// if the user cancels or authentication fails.
  ///
  /// [hashedTXNData]: a cryptographic hash (e.g. SHA-256) of the raw transaction.
  Future<String?> signTransaction({
    required String hashedTXNData,
  }) async {
    try {
      // Prompt the user with a clear title/subtitle before capturing biometrics
      final signature = await _biometricManager.createSignature(
        data: hashedTXNData,
        config: const BiometricPromptConfig(
          title: 'Sign Transaction',
          subtitle: 'Use your biometric to authorize this transaction',
        ),
      );
      return signature;
    } on BiometricException catch (e) {
      'BiometricService ::: signTransaction ::: Biometric error: ${e.message}'
          .log();
      return null;
    }
  }

  /// Creates a signature over raw data (e.g. challenge strings) for authentication.
  ///
  /// Useful for non-transaction flows that still require proof of liveness.
  /// Returns the signature or `null` on failure.
  Future<String?> createSignature({
    required String rawData,
  }) async {
    try {
      final signature = await _biometricManager.createSignature(
        data: rawData,
        config: const BiometricPromptConfig(
          title: 'Authorize',
          subtitle: 'Use your biometric to authenticate.',
        ),
      );
      return signature;
    } on BiometricException catch (e, trace) {
      'BiometricService ::: createSignature ::: Biometric error: ${e.message} ::: Trace ::: $trace'
          .log();
      return null;
    }
  }

  /// Generates a new public key tied to the user’s biometric identity.
  ///
  /// This is typically used once (e.g. on device setup) to create a key
  /// that can later verify signatures without additional biometric prompts.
  Future<String?> generatePublicKey() async {
    try {
      final publicKey = await _biometricManager.generatePublicKey(
        config: const BiometricPromptConfig(
          title: 'Authorize',
          subtitle: 'Use your biometric to create your ID',
        ),
      );
      return publicKey;
    } on BiometricException catch (e, trace) {
      'BiometricService ::: generatePublicKey ::: Biometric error: ${e.message} TRACE ::: $trace'
          .log();
      return null;
    }
  }
}
