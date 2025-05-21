library;

import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/payments/pay_with_mona_widget.dart';

import 'widgets/merchant_payment_settings_widget.dart';

part "_pay_with_mona_impl.dart";

abstract class PayWithMona {
  static PayWithMona? _instance;

  /// Access the singleton instance
  static PayWithMona get instance {
    if (_instance == null) {
      throw Exception(
        'PayWithMona has not been initialized. Call PayWithMona.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize the SDK with your merchant API key
  static void initialize({
    required String merchantAPIKey,
  }) {
    _instance ??= _MonaSDKImpl.initialize(
      merchantAPIKey: merchantAPIKey,
    );
  }

  Widget payWidget({
    required BuildContext context,
    required MonaCheckOut checkoutPayload,
  });

  Widget paymentUpdateSettingsWidget({
    num? transactionAmountInKobo,
  });

  Future<void> showDataShareSheet({
    required BuildContext context,
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime dateOfBirth,
    required String transactionId,
    required String merchantName,
    required Color primaryColor,
    required Color secondaryColor,
    required String phoneNumber,
    String? bvn,
  });
}
