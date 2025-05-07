abstract class ApiHeaderModel {
  static const String _xClientType = "bioApp";
  static const String _contentType = "application/json; charset=utf-8";

  static Map<String, dynamic> getHeaders({
    required String bearerToken,
  }) {
    return {
      "Authorization": bearerToken,
      "x-client-type": _xClientType,
      "content-type": _contentType,
    };
  }

  static Map<String, String> paymentHeaders({
    required String? monaKeyID,
    required String? monaCheckoutID,
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
    };
  }
}
