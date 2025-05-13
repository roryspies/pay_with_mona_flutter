export 'package:pay_with_mona/src/features/collections/views/create_collection_view.dart';
export 'package:pay_with_mona/src/features/controller/sdk_notifier.dart';
export 'package:pay_with_mona/src/core/events/auth_state_stream.dart';

import 'package:flutter/material.dart';

import 'package:pay_with_mona/src/features/data_share/widgets/data_share_sheet.dart';
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
    required String phoneNumber,
    required num amount,
    String? bvn,
  }) {
    final monaCheckOut = MonaCheckOut(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      transactionId: transactionId,
      merchantName: merchantName,
      phoneNumber: phoneNumber,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      bvn: bvn,
      amount: amount,
    );

    return PayWithMonaWidget(
      monaCheckOut: monaCheckOut,
    );
  }

  /// Opens the data share widget in a bottom sheet
  static Future<void> showDataShareSheet({
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
  }) {
    final widget = DataShareSheet();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Wrap(
        children: [
          widget,
        ],
      ),
    );
  }
}
