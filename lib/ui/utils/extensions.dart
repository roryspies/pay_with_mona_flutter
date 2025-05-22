import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "dart:developer" as dev_tools show log;

import 'package:intl/intl.dart';

extension ImagePath on String {
  String get png => "packages/pay_with_mona/assets/images/$this.png";
  String get jpg => "packages/pay_with_mona/assets/images/$this.jpg";
  String get jpeg => "packages/pay_with_mona/assets/images/$this.jpeg";
  String get gif => "packages/pay_with_mona/assets/gif/$this.gif";
  String get svg => "packages/pay_with_mona/assets/icons/$this.svg";
}

/// Extension for creating a ValueNotifier from a value directly.
extension ValueNotifierExtension<T> on T {
  ValueNotifier<T> get notifier {
    return ValueNotifier<T>(this);
  }
}

/// extension for listening to ValueNotifier instances.
extension ValueNotifierBuilderExtension<T> on ValueNotifier<T> {
  Widget sync({
    required Widget Function(BuildContext context, T value, Widget? child)
        builder,
  }) {
    return ValueListenableBuilder<T>(
      valueListenable: this,
      builder: builder,
    );
  }
}

extension ListenableBuilderExtension on List<Listenable> {
  Widget multiSync({
    required Widget Function(BuildContext context, Widget? child) builder,
  }) {
    return ListenableBuilder(
      listenable: Listenable.merge(this),
      builder: builder,
    );
  }
}

extension Log on Object {
  void log() {
    if (kDebugMode) {
      dev_tools.log("PWM - ${toString()}");
    }
  }
}

extension StringCasingExtension on String {
  String? camelCase() => toBeginningOfSentenceCase(this);
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
  String? trimToken() => contains(":") ? split(":")[1].trim() : this;
  String? trimSpaces() => replaceAll(" ", "");
  String removeSpacesAndLower() => replaceAll(' ', '').toLowerCase();
}
