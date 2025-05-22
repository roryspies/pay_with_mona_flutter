part of "pay_with_mona.dart";

class _MonaSDKImpl extends PayWithMona {
  final String merchantAPIKey;

  _MonaSDKImpl._({required this.merchantAPIKey});

  /// Called by PayWithMona.initialize(...)
  static _MonaSDKImpl initialize({required String merchantAPIKey}) {
    // Perform any SDK‐wide setup here (HTTP, logging, etc.)
    return _MonaSDKImpl._(merchantAPIKey: merchantAPIKey);
  }

  @override
  Widget payWidget({
    required BuildContext context,
    required MonaCheckOut checkoutPayload,
  }) {
    return PayWithMonaWidget(
      monaCheckOut: checkoutPayload,
      callingContext: context,
    );
  }

  @override
  Widget paymentUpdateSettingsWidget({num? transactionAmountInKobo}) {
    return MerchantPaymentSettingsWidget(
      transactionAmountInKobo: transactionAmountInKobo,
    );
  }

  @override
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
  }) {
    // TODO: implement showDataShareSheet
    throw UnimplementedError();
  }
}

/* 
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
 */
