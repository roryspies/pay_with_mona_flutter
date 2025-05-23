abstract class ApiHeaders {
  static const String _xClientType = "bioApp";

  static Map<String, String> initSDKHeaders({
    required String merchantKey,
  }) {
    return {
      "x-client-type": _xClientType,
      "x-public-key": merchantKey,
    };
  }

  static Map<String, dynamic> getHeaders() {
    return {
      "x-client-type": _xClientType,
    };
  }

  ///
  /// *** MARK: Payment Service Headers
  static Map<String, String> initiatePaymentHeader({
    required String merchantKey,
  }) {
    return {
      "x-client-type": _xClientType,
      "x-public-key": merchantKey,
    };
  }

  static Map<String, String> getPaymentMethods({
    required String userEnrolledCheckoutID,
  }) {
    return {
      "x-client-type": _xClientType,
      "cookie": "mona_checkoutId=$userEnrolledCheckoutID",
    };
  }

  static Map<String, String> paymentHeader({
    required String? monaKeyID,
    required String? monaCheckoutID,
    required String? checkoutType,
    required String? signature,
    required String? nonce,
    required String? timestamp,
  }) {
    return {
      "x-client-type": _xClientType,
      if (monaCheckoutID != null) 'cookie': 'mona_checkoutId=$monaCheckoutID',
      if (monaKeyID != null) 'x-mona-key-id': monaKeyID,
      if (signature != null) 'x-mona-pay-auth': signature,
      if (nonce != null) 'x-mona-nonce': nonce,
      if (timestamp != null) 'x-mona-timestamp': timestamp,
      if (checkoutType != null) "x-mona-checkout-type": checkoutType,
    };
  }
}
