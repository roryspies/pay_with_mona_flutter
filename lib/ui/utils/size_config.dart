import 'dart:math';
import 'package:flutter/material.dart';

extension MediaQueryValues on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  double get textScaleFactor => MediaQuery.of(this).textScaler.scale(1.0);

  double sp(double value) {
    return screenWidth > 640
        ? value * textScaleFactor
        : (min(
              screenWidth / SizeConfig.baseWidth,
              screenHeight / SizeConfig.baseHeight,
            ) *
            textScaleFactor *
            value);
  }

  double h(double value) {
    return screenWidth > SizeConfig.breakpoint
        ? value
        : ((screenHeight / SizeConfig.baseHeight) * value).toDouble();
  }

  double w(double value) {
    return screenWidth > SizeConfig.breakpoint
        ? value
        : ((screenWidth / SizeConfig.baseWidth) * value).toDouble();
  }

  double r(double value) {
    return screenWidth > SizeConfig.breakpoint
        ? value
        : ((screenWidth / SizeConfig.baseWidth) * value).toDouble();
  }

  SizedBox sbH(double value) {
    return screenWidth > SizeConfig.breakpoint
        ? SizedBox(height: value)
        : SizedBox(
            height: ((screenHeight / SizeConfig.baseHeight) * value).toDouble(),
          );
  }

  SizedBox sbW(double value) {
    return screenWidth > SizeConfig.breakpoint
        ? SizedBox(width: value)
        : SizedBox(
            width: ((screenWidth / SizeConfig.baseWidth) * value).toDouble());
  }
}

class SizeConfig {
  static double breakpoint = 640;
  static double baseWidth = 375;
  static double baseHeight = 812;
}

double height(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

double width(BuildContext context) {
  return MediaQuery.of(context).size.width;
}
