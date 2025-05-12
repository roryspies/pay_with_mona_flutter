part of "sdk_notifier.dart";

extension SDKNotifierCollectionHelpers on MonaSDKNotifier {
  Future<void> createCollections({
    required String bankId,
    required String maximumAmount,
    required String expiryDate,
    required String startDate,
    required String monthlyLimit,
    required String reference,
    required String type,
    required String frequency,
    required String? amount,
    required String merchantId,
  }) async {
    _updateState(MonaSDKState.loading);
    try {
      // Initialize SSE listener for real-time events
      _firebaseSSE.initialize();

      final doKeyExchange = await checkIfUserHasKeyID() == null;

      if (doKeyExchange) {
        await initKeyExchange();
      }

      'CCKEYEX'.log();

      bool hasError = false;
      bool hasTransactionUpdateError = false;

      /// *** Concurrently listen for transaction completion.
      // await Future.wait([
      //   _listenForPaymentUpdates(hasError),
      //   _listenForTransactionUpdateEvents(hasTransactionUpdateError),
      // ]);

      final secureStorage = SecureStorage();
      final monaKeyID = await secureStorage.read(
            key: SecureStorageKeys.keyID,
          ) ??
          "";
      final userCheckoutID = await secureStorage.read(
            key: SecureStorageKeys.monaCheckoutID,
          ) ??
          "";

      final nonce = UUIDGenerator.v4();
      final timestamp =
          DateTime.now().toLocal().millisecondsSinceEpoch.toString();

      final payload = {
        "bankId": bankId,
        "maximumAmount": maximumAmount,
        "expiryDate": expiryDate,
        "startDate": startDate,
        "monthlyLimit": monthlyLimit,
        "reference": reference,
        "schedule": {
          "type": type,
          "frequency": frequency,
          "amount": amount,
          if (type == 'SCHEDULED')
            "entries": [
              {
                "date": "2025-06-15T00:00:00.000Z",
                "amount": "2000",
              },
              {
                "date": "2025-07-01T00:00:00.000Z",
                "amount": "3000",
              }
            ]
        }
      };

      "REQUESTING TO SIGN COLLECTIONS ==>> PAY LOAD TO BE SIGNED ==>> $payload"
          .log();

      String? signature = await _signRequest(
        payload,
        nonce,
        timestamp,
        monaKeyID,
      );

      if (signature == null) {
        "collections SIGNATURE IS NULL OR CANCELLED".log();

        return;
      }

      final (Map<String, dynamic> success, failure) = ({}, Failure(''));
      //     await _collectionsService.createCollections(
      //   payload: payload,
      //   merchantId: merchantId,
      //   signature: signature,
      //   monaKeyId: monaKeyID,
      //   monaCheckoutID: userCheckoutID,
      //   nonce: nonce,
      //   timestamp: timestamp,
      // );

      _handleError('Collection creation failed.');
      throw (failure.message);

      success.log();

      _updateState(MonaSDKState.success);
    } catch (e) {
      e.toString().log();
      _handleError(e.toString());
    }
  }

  ///
  /// *** SIGN A TRANSACTION / PAYMENT REQUEST USING BIOMETRICS
  Future<String?> _signRequest(
    Map<String, dynamic> payload,
    String nonce,
    String timestamp,
    String userCheckoutID,
  ) async {
    final encodedPayload = base64Encode(utf8.encode(jsonEncode(payload)));

    Map<String, dynamic> data = {
      "method": base64Encode(utf8.encode("POST")),
      "uri": base64Encode(utf8.encode("/pay")),
      "body": encodedPayload,
      "params": base64Encode(utf8.encode(jsonEncode({}))),
      "nonce": base64Encode(utf8.encode(nonce)),
      "timestamp": base64Encode(utf8.encode(timestamp)),
      "keyId": base64Encode(utf8.encode(userCheckoutID)),
    };

    final dataString = base64Encode(utf8.encode(json.encode(data)));
    final hash = sha256.convert(utf8.encode(dataString)).toString();

    final String? signature = await BiometricService().signTransaction(
      hashedTXNData: hash,
    );

    return signature;
  }
}
