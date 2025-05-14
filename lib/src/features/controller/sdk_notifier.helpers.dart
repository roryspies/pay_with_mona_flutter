part of "sdk_notifier.dart";

extension SDKNotifierHelpers on MonaSDKNotifier {
  String _generateSessionID() {
    return math.Random.secure().nextInt(999999999).toString();
  }

  ///
  /// *** MARK: Custom Tabs and URL"s
  /// Builds the URL for the in-app payment custom tab.
  String _buildURL({
    required String sessionID,
    PaymentMethod? method,
    String? bankOrCardId,
    bool withRedirect = true,
  }) {
    if (withRedirect && (method == null || method == PaymentMethod.none)) {
      throw MonaSDKError(
        message: "Payment method must be provided when withRedirect is true.",
      );
    }

    final baseUrl = "https://pay.development.mona.ng/login";
    final loginScope = Uri.encodeComponent("67e41f884126830aded0b43c");

    final String? methodType = method?.type;

    // Build extra params for saved methods
    String extraParam = '';
    if (method == PaymentMethod.savedBank ||
        method == PaymentMethod.savedCard) {
      if (bankOrCardId == null || bankOrCardId.isEmpty) {
        throw MonaSDKError(
          message:
              "bankOrCardId must be provided when using savedBank or savedCard.",
        );
      }

      extraParam = "&bankId=$bankOrCardId";
    }

    final redirectParam = withRedirect
        ? "&redirect=${Uri.encodeComponent("https://pay.development.mona.ng/$_currentTransactionId?embedding=true&sdk=true&method=$methodType$extraParam")}"
        : "";

    return "$baseUrl"
        "?loginScope=$loginScope"
        "$redirectParam"
        "&sessionId=${Uri.encodeComponent(sessionID)}";
  }

  /// Launches the payment URL using platform-specific custom tab settings.
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);

    "🚀 Launching payment URL: $url".log();

    assert(
      _callingBuildContext != null,
      "Build context must be set before launching URL",
    );

    final screenHeight = _callingBuildContext!.screenHeight;

    await launchUrl(
      uri,
      customTabsOptions: CustomTabsOptions.partial(
        configuration: PartialCustomTabsConfiguration(
          activityHeightResizeBehavior:
              CustomTabsActivityHeightResizeBehavior.fixed,
          initialHeight: screenHeight,
        ),
      ),
      safariVCOptions: SafariViewControllerOptions.pageSheet(
        configuration: const SheetPresentationControllerConfiguration(
          detents: {SheetPresentationControllerDetent.large},
          prefersEdgeAttachedInCompactHeight: true,
          preferredCornerRadius: 16.0,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> buildBankPaymentPayload() async {
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    return {
      "origin": _selectedBankOption?.bankId ?? "",
      "hasDeviceKey": userCheckoutID != null,
      "transactionId": _currentTransactionId,
      if (_transactionOTP != null) "otp": _transactionOTP,
      if (_transactionPIN != null) "pin": _transactionPIN,
    };
  }

  /// *** TODO: Fix the below to match card payments.
  Future<Map<String, dynamic>> buildCardPaymentPayload() async {
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    return {
      "origin": _selectedCardOption?.bankId ?? "",
      "hasDeviceKey": userCheckoutID != null,
      "destination": {
        "type": "card",
        "typeDetail": "charge",
        "params": {
          "cardNumber": _selectedCardOption?.accountNumber ?? "",
        },
      },
      "amount":
          (num.parse(_pendingPaymentResponseModel?.amount.toString() ?? "0") *
                  100)
              .toInt(),
      "narration": "Payment via Card",
    };
  }

  /// Emits the state and waits for user input via `completeOtpFlow`
  Future<String?> triggerPinOrOTPFlow({
    required PaymentTaskType pinOrOTP,
    required TransactionTaskModel pinOrOTPTask,
  }) {
    _pinOrOTPCompleter = Completer<String>();

    if (pinOrOTP == PaymentTaskType.pin) {
      _txnStateStream.emit(
        state: TransactionStateRequestPINTask(
          task: pinOrOTPTask,
        ),
      );
    } else if (pinOrOTP == PaymentTaskType.otp) {
      _txnStateStream.emit(
        state: TransactionStateRequestOTPTask(
          task: pinOrOTPTask,
        ),
      );
    }

    return _pinOrOTPCompleter!.future;
  }

  /// Call this from your mobile app side when user enters OTP/PIN
  void complete({
    required String pinOrOTP,
  }) {
    if (_pinOrOTPCompleter != null && !_pinOrOTPCompleter!.isCompleted) {
      _pinOrOTPCompleter!.complete(pinOrOTP);
    }
  }

  /// Optionally allow cancelling the flow (user cancelled)
  void cancelOtpFlow() {
    if (_pinOrOTPCompleter != null && !_pinOrOTPCompleter!.isCompleted) {
      // ignore: null_argument_to_non_null_type
      _pinOrOTPCompleter!.complete(null);
    }
  }
}
