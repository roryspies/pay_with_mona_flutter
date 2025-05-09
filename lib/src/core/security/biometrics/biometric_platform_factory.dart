import 'dart:io';
import 'package:biometric_signature/biometric_signature.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth_signature/local_auth_signature.dart';
import 'package:pay_with_mona/src/core/security/biometrics/android_biometric_platform.dart';
import 'package:pay_with_mona/src/core/security/biometrics/biometric_platform_interface.dart';
import 'package:pay_with_mona/src/core/security/biometrics/ios_biometric_platform.dart';

/// A factory that returns the correct [BiometricPlatformInterface]
/// implementation for the current operating system.
///
/// This abstracts away platform checks so consumers simply write:
/// ```dart
/// final platform = BiometricPlatformFactory.create();
/// ```
///
/// and get back an object that implements the same interface on both
/// Android and iOS.
class BiometricPlatformFactory {
  BiometricPlatformFactory._(); // Private constructor to prevent instantiation

  /// Returns an OS-specific biometric implementation:
  ///
  /// - On **Android**, returns [AndroidBiometricPlatform], which uses:
  ///   - `DeviceInfoPlugin()` to inspect device capabilities.
  ///   - `BiometricSignature()` for cryptographic signature operations.
  ///   - `LocalAuthSignature.instance` for fallback local authentication.
  ///
  /// - On **iOS**, returns [IOSBiometricPlatform], which only needs
  ///   `BiometricSignature()`.
  ///
  /// Throws an [UnsupportedError] on other platforms.
  static BiometricPlatformInterface create() {
    if (Platform.isAndroid) {
      return AndroidBiometricPlatform(
        deviceInfo: DeviceInfoPlugin(),
        biometricSignature: BiometricSignature(),
        localAuthSignature: LocalAuthSignature.instance,
      );
    } else if (Platform.isIOS) {
      return IOSBiometricPlatform(
        biometricSignature: BiometricSignature(),
      );
    } else {
      throw UnsupportedError(
        'Biometric authentication is not supported on this platform '
        '(${Platform.operatingSystem}).',
      );
    }
  }
}
