library;

import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/data_share/widgets/data_share_sheet.dart';
import 'package:pay_with_mona/src/features/payments/pay_with_mona_widget.dart';

part "_pay_with_mona_impl.dart";

abstract class PayWithMona {
  static PayWithMona? _instance;

  static PayWithMona get instance {
    if (_instance == null) {
      throw Exception(
        'PayWithMona has not been initialized. Call PayWithMona.initialize() first.',
      );
    }
    return _instance!;
  }

  static Future<void> initialize({
    required String merchantKey,
  }) async {
    _instance ??= await _MonaSDKImpl.initialize(
      merchantKey: merchantKey,
    );
  }

  Widget payWidget({
    required BuildContext context,
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
