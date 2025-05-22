import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/models/merchant_branding.dart';

class MonaColors {
  static BrandingColors? _merchantBrandingColours;

  /// Set this once after SDK initialization
  static void setBranding({required BrandingColors merchantBrandingColours}) {
    _merchantBrandingColours = merchantBrandingColours;
  }

  static const Color _defaultBgGrey = Color(0xFFF2F2F3);
  static const Color _defaultNeutralWhite = Color(0xFFFFFFFF);
  static const Color _defaultTextHeading = Color(0xFF131503);
  static const Color _defaultTextBody = Color(0xFF6A6C60);
  static const Color _defaultPrimaryBlue = Color(0xFF3045FB);
  static const Color _defaultTextField = Color(0xFFF7F7F8);
  static const Color _defaultHint = Color(0xFF999999);
  static const Color _defaultSuccess = Color(0xFF0F973D);

  static Color get bgGrey => _defaultBgGrey;
  static Color get neutralWhite => _defaultNeutralWhite;
  static Color get textHeading => _defaultTextHeading;
  static Color get textBody => _defaultTextBody;
  static Color get textField => _defaultTextField;
  static Color get hint => _defaultHint;
  static Color get successColour => _defaultSuccess;

  static Color get primaryBlue =>
      _merchantBrandingColours?.primaryColour ?? _defaultPrimaryBlue;
  static Color get primaryText =>
      _merchantBrandingColours?.primaryText ?? _defaultTextBody;
}
