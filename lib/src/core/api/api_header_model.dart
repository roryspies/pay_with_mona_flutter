abstract class ApiHeaderModel {
  static const String _xClientType = "bioApp";

  static Map<String, dynamic> getHeaders() {
    return {
      "x-client-type": _xClientType,
    };
  }

  static Map<String, String> paymentHeaders({
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
