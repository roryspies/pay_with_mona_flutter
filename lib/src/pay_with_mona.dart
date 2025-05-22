import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/features/data_share/widgets/data_share_sheet.dart';
import 'package:pay_with_mona/src/features/payments/pay_with_mona_widget.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/ui/widgets/merchant_payment_settings_widget.dart';

class PayWithMona {
  static Future<void> initialize({
    required String publicKey,
    required String secretKey,
    required String merchantId,
    required String environment,
  }) async {}

  static Widget payWidget({
    required BuildContext context,
    required MonaCheckOut payload,
  }) {
    return PayWithMonaWidget(
      monaCheckOut: payload,
      callingContext: context,
    );
  }

  static Widget paymentSettingsWidget({
    num? transactionAmountInKobo,
  }) {
    return MerchantPaymentSettingsWidget(
      transactionAmountInKobo: transactionAmountInKobo,
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
