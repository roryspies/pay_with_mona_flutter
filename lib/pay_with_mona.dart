import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/features/payments/pay_with_mona_widget.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';

class PayWithMona {
  static Widget payWidget({
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime dateOfBirth,
    required String transactionId,
    required String merchantName,
    required Color primaryColor,
    required Color secondaryColor,
    String? bvn,
  }) {
    final monaCheckOut = MonaCheckOut(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      transactionId: transactionId,
      merchantName: merchantName,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      bvn: bvn,
    );
    return PayWithMonaWidget(
      monaCheckOut: monaCheckOut,
    );
  }
}
