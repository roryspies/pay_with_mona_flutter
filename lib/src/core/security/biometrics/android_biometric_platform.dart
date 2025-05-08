import 'package:biometric_signature/android_config.dart';
import 'package:biometric_signature/biometric_signature.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_signature/local_auth_signature.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_exception.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_platform_interface.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_prompt_config.dart';
import 'dart:async';

/// Android-specific implementation of biometric operations.
///
/// This class leverages both a native biometric signature SDK and the
/// platform's local authentication fallback to provide:
/// 1. Public key generation
/// 2. Biometric payload signing
///
/// It detects unsupported device models and uses an alternative
/// `LocalAuthSignature` API when necessary.
class AndroidBiometricPlatform implements BiometricPlatformInterface {
  final DeviceInfoPlugin _deviceInfo;
  final BiometricSignature _biometricSignature;
  final LocalAuthSignature _localAuthSignature;
  final List<String> _unsupportedModels;

  /// Constructs an [AndroidBiometricPlatform].
  ///
  /// [deviceInfo]: plugin for retrieving Android device metadata.
  /// [biometricSignature]: primary SDK for biometric key and signature operations.
  /// [localAuthSignature]: fallback for older or unsupported devices.
  /// [unsupportedModels]: optional whitelist of device model identifiers
  ///   that require fallback behavior (defaults to `['CP3706AS']`).
  AndroidBiometricPlatform({
    required DeviceInfoPlugin deviceInfo,
    required BiometricSignature biometricSignature,
    required LocalAuthSignature localAuthSignature,
    List<String>? unsupportedModels,
  })  : _deviceInfo = deviceInfo,
        _biometricSignature = biometricSignature,
        _localAuthSignature = localAuthSignature,
        _unsupportedModels = unsupportedModels ?? const ['CP3706AS'];

  /// Checks if biometric authentication is available and enrolled on the device.
  ///
  /// Returns `true` if the device reports at least one enrolled biometric
  /// (e.g., fingerprint, face), otherwise `false`.
  @override
  Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    final canCheck = await localAuth.canCheckBiometrics;
    if (!canCheck) return false;

    final enrolled = await localAuth.getAvailableBiometrics();
    return enrolled.isNotEmpty;
  }

  /// Generates a new asymmetric key pair protected by biometric or device credentials.
  ///
  /// [config]: UI prompt configuration for biometric enrollment.
  ///
  /// Returns the public key as a Base64-encoded string, or throws
  /// [BiometricException] on failure.
  @override
  Future<String> generatePublicKey(BiometricPromptConfig config) async {
    final androidInfo = await _deviceInfo.androidInfo;

    try {
      if (!_unsupportedModels.contains(androidInfo.model)) {
        // Primary SDK path for modern devices
        final key = await _biometricSignature.createKeys(
          androidConfig: AndroidConfig(useDeviceCredentials: true),
          //iosConfig: IosConfig(useDeviceCredentials: true),
        );
        if (key == null) {
          throw BiometricException('Failed to generate key via signature SDK');
        }
        return key;
      }

      // Fallback path for unsupported device models
      const fallbackAlias = 'pay_with_mona';
      final key = await _localAuthSignature.createKeyPair(
        fallbackAlias,
        AndroidPromptInfo(
          title: config.title,
          subtitle: config.subtitle,
          negativeButton: config.cancelButtonText,
        ),
        IOSPromptInfo(reason: config.subtitle),
      );
      if (key == null) {
        throw BiometricException('Failed to generate key via local auth');
      }
      return key;
    } catch (e, st) {
      // Wrap any errors in a unified BiometricException
      throw BiometricException('generatePublicKey error', e, st);
    }
  }

  /// Signs arbitrary data using biometric authentication.
  ///
  /// [data]: the payload to sign (e.g., transaction hash).
  /// [config]: UI prompt configuration for the signing prompt.
  ///
  /// Returns the signature as a Base64 string, or throws
  /// [BiometricException] on failure.
  @override
  Future<String> createSignature(
      String data, BiometricPromptConfig config) async {
    final androidInfo = await _deviceInfo.androidInfo;

    try {
      if (!_unsupportedModels.contains(androidInfo.model)) {
        // Primary path uses the signature SDK
        final sig = await _biometricSignature.createSignature(
          options: {
            'payload': data,
            'promptMessage': config.title,
          },
        );
        if (sig == null) {
          throw BiometricException('Failed to sign with signature SDK');
        }
        return sig;
      }

      // Fallback path uses the local auth plugin
      const fallbackAlias = 'ng.mona.app';
      final sig = await _localAuthSignature.sign(
        fallbackAlias,
        data,
        AndroidPromptInfo(
          title: config.title,
          subtitle: config.subtitle,
          negativeButton: config.cancelButtonText,
        ),
        IOSPromptInfo(reason: config.subtitle),
      );
      if (sig == null) {
        throw BiometricException('Failed to sign via local auth');
      }
      return sig;
    } catch (e, st) {
      throw BiometricException('createSignature error', e, st);
    }
  }
}
