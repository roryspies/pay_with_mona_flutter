// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class MerchantBranding {
  final BrandingColors colors;
  final String image;
  final String name;
  final String tradingName;

  const MerchantBranding({
    required this.colors,
    required this.image,
    required this.name,
    required this.tradingName,
  });

  factory MerchantBranding.fromJSON({
    required Map<String, dynamic>? json,
  }) {
    final raw = json ?? <String, dynamic>{};

    return MerchantBranding(
      colors: BrandingColors.fromJSON(
        json: raw['colors'] as Map<String, dynamic>?,
      ),
      image: raw['image'] as String? ?? '',
      name: raw['name'] as String? ?? '',
      tradingName: raw['tradingName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'colors': colors.toJson(),
        'image': image,
        'name': name,
        'tradingName': tradingName,
      };

  MerchantBranding copyWith({
    BrandingColors? colors,
    String? image,
    String? name,
    String? tradingName,
  }) {
    return MerchantBranding(
      colors: colors ?? this.colors,
      image: image ?? this.image,
      name: name ?? this.name,
      tradingName: tradingName ?? this.tradingName,
    );
  }

  @override
  String toString() {
    return 'MerchantBranding(colors: $colors, image: $image, name: $name, tradingName: $tradingName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MerchantBranding &&
            other.colors == colors &&
            other.image == image &&
            other.name == name &&
            other.tradingName == tradingName);
  }

  @override
  int get hashCode =>
      colors.hashCode ^ image.hashCode ^ name.hashCode ^ tradingName.hashCode;
}

class BrandingColors {
  final Color primaryColour;
  final Color primaryText;

  const BrandingColors({
    required this.primaryColour,
    required this.primaryText,
  });

  factory BrandingColors.fromJSON({
    required Map<String, dynamic>? json,
  }) {
    final raw = json ?? <String, dynamic>{};

    Color parseHex(String? hex, {Color fallback = Colors.black}) {
      if (hex == null || hex.isEmpty) return fallback;
      final cleaned = hex.replaceAll('#', '');
      final value = int.tryParse(cleaned, radix: 16);
      return value != null ? Color(0xFF000000 | value) : fallback;
    }

    return BrandingColors(
      primaryColour:
          parseHex(raw['primaryColour'] as String?, fallback: Colors.blue),
      primaryText:
          parseHex(raw['primaryText'] as String?, fallback: Colors.white),
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryColour':
            '#${primaryColour.value.toRadixString(16).substring(2)}',
        'primaryText': '#${primaryText.value.toRadixString(16).substring(2)}',
      };

  BrandingColors copyWith({
    Color? primaryColour,
    Color? primaryText,
  }) {
    return BrandingColors(
      primaryColour: primaryColour ?? this.primaryColour,
      primaryText: primaryText ?? this.primaryText,
    );
  }
}
