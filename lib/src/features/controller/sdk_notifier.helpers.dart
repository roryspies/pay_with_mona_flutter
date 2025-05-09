part of "sdk_notifier.dart";

extension SDKNotifierHelpers on MonaSDKNotifier {
  Future<Map<String, dynamic>> buildBankPaymentPayload() async {
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    return {
      "origin": _selectedBankOption?.bankId ?? "",
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
