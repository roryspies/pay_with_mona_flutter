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
  /// *** MARK: Auth Service Headers
  ///
  static Map<String, String> merchantPaymentSettingsHeaders({
    required String merchantAPIKey,
  }) {
    return {
      "x-client-type": _xClientType,
      "x-api-key": merchantAPIKey,
    };
  }

  static Map<String, String> loginWithStrongAuth({
    required String strongAuthToken,
  }) {
    return {
      "x-client-type": _xClientType,
      "x-strong-auth-token": strongAuthToken,
      "x-mona-key-exchange": "true",
    };
  }

  static Map<String, String> validatePII({
    required String userKeyID,
  }) {
    return {
      "x-client-type": _xClientType,
      "x-mona-key-id": userKeyID,
      "content-Type": "application/json",
    };
  }

  ///
  /// *** MARK: Payment Service Headers
  static Map<String, String> initiatePaymentHeader({
    required String merchantKey,
    String? userKeyID,
  }) {
    return {
      "x-client-type": _xClientType,
      if (userKeyID != null) "x-mona-key-id": userKeyID,
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
