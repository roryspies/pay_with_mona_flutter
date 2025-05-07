part of "payment_notifier.dart";

extension PaymentNotifierHelpers on PaymentNotifier {
  Future<Map<String, dynamic>> buildBankPaymentPayload() async {
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    final transferDestination =
        _pendingPaymentResponseModel?.selectedPaymentOptions?.transfer?.details;

    return {
      "origin": _selectedBankOption?.bankId ?? "",
      "destination": {
        "type": "bank",
        "typeDetail": "p2p",
        "params": {
          "institutionCode": transferDestination?.accountNumber ?? "",
          "accountNumber": transferDestination?.accountNumber ?? "",
        },
      },
      "amount":
          num.parse(_pendingPaymentResponseModel?.amount.toString() ?? "0")
              .toInt(),
      "narration": "Sent from Mona",
      "hasDeviceKey": userCheckoutID != null,
      "transactionId": _currentTransactionId,
    };
  }

  /// *** TODO: Fix the below to match card payments.
  Future<Map<String, dynamic>> buildCardPaymentPayload() async {
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    return {
      "origin": _selectedBankOption?.bankId ?? "",
      "destination": {
        "type": "bank",
        "typeDetail": "p2p",
        "params": {
          //"institutionCode": destinationBank?.institutionCode ?? "",
          "accountNumber": _selectedBankOption?.accountNumber ?? "",
        },
      },
      "amount":
          (num.parse(_pendingPaymentResponseModel?.amount.toString() ?? "0") *
                  100)
              .toInt(),
      "narration": "Sent from Mona",
      "hasDeviceKey": userCheckoutID != null,
    };
  }
}
