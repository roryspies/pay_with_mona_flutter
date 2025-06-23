// ignore_for_file: deprecated_member_use

part of "sdk_notifier.dart";

extension SDKNotifierHelpers on MonaSDKNotifier {
  String _generateSessionID() {
    return math.Random.secure().nextInt(999999999).toString();
  }

  ///
  /// *** MARK: Custom Tabs and URL"s
  /// Builds the URL for the in-app payment custom tab.
  Future<String> _buildURL({
    required String sessionID,
    PaymentMethod? method,
    String? bankOrCardId,
    bool withRedirect = true,
    bool isFromCollections = false,
    bool doDirectPayment = false,
    bool doDirectPaymentWithPossibleAuth = false,
  }) async {
    final merchantKey = await _getMerchantKey();
    final loginScope = Uri.encodeComponent(merchantKey!);
    final encodedSessionID = Uri.encodeComponent(sessionID);
    final transactionID = _currentTransactionId ?? '';
    final encodedTransactionID = Uri.encodeComponent(transactionID);

    if (doDirectPayment) {
      final methodType = Uri.encodeComponent(method?.type ?? '');
      return "https://pay.development.mona.ng/$transactionID"
          "?embedding=true&sdk=true&method=$methodType";
    }

    if (doDirectPaymentWithPossibleAuth) {
      final methodType = Uri.encodeComponent(method?.type ?? '');
      return "https://pay.development.mona.ng/$transactionID"
          "?embedding=true&sdk=true&method=$methodType"
          "&loginScope=$loginScope"
          "&sessionId=$encodedSessionID";
    }

    if (isFromCollections) {
      return "https://pay.development.mona.ng/collections"
          "?loginScope=$loginScope"
          "&sessionId=$encodedSessionID";
    }

    if (withRedirect && (method == null || method == PaymentMethod.none)) {
      throw MonaSDKError(
        message: "Payment method must be provided when withRedirect is true.",
      );
    }

    final methodType = method?.type;
    String extraParam = '';

    if (method == PaymentMethod.savedBank ||
        method == PaymentMethod.savedCard) {
      if (bankOrCardId == null || bankOrCardId.isEmpty) {
        throw MonaSDKError(
          message:
              "bankOrCardId must be provided when using savedBank or savedCard.",
        );
      }
      extraParam = "&bankId=${Uri.encodeComponent(bankOrCardId)}";
    }

    final redirectURL = "https://pay.development.mona.ng/$transactionID"
        "?embedding=true&sdk=true&method=${Uri.encodeComponent(methodType ?? '')}$extraParam";

    final redirectParam =
        withRedirect ? "&redirect=${Uri.encodeComponent(redirectURL)}" : "";

    return "https://pay.development.mona.ng/login"
        "?loginScope=$loginScope"
        "$redirectParam"
        "&sessionId=$encodedSessionID"
        "&transactionId=$encodedTransactionID";
  }

  /// Launches the payment URL using platform-specific custom tab settings.
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);

    "🚀 Launching payment URL: $url".log();

    final screenHeight = callingContext.screenHeight;
    final screenWidth = callingContext.screenWidth;

    try {
      await launchUrl(
        uri,
        customTabsOptions: CustomTabsOptions.partial(
          showTitle: true,
          closeButton: CustomTabsCloseButton(),
          configuration: PartialCustomTabsConfiguration(
            initialHeight: screenHeight * 0.9,
            initialWidth: screenWidth,
            activitySideSheetMaximizationEnabled: true,
            activitySideSheetDecorationType:
                CustomTabsActivitySideSheetDecorationType.shadow,
            activitySideSheetRoundedCornersPosition:
                CustomTabsActivitySideSheetRoundedCornersPosition.top,
            cornerRadius: 16,
          ),
        ), //CustomTabsOptions(),
        safariVCOptions: SafariViewControllerOptions.pageSheet(
          configuration: const SheetPresentationControllerConfiguration(
            detents: {
              SheetPresentationControllerDetent.large,
            },
            prefersEdgeAttachedInCompactHeight: true,
            preferredCornerRadius: 16.0,
            prefersScrollingExpandsWhenScrolledToEdge: true,
            prefersGrabberVisible: true,
          ),
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      "Could not launch URL: $e".log();
    }
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

  Future<Map<String, dynamic>> buildCardPaymentPayload() async {
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    return {
      "bankId": _selectedCardOption?.bankId ?? "",
      "hasDeviceKey": userCheckoutID != null,
      "transactionId": _currentTransactionId,
    };
  }

  /// Triggers either a PIN or OTP flow, showing a bottom-sheet modal and
  /// returning the user-entered (and optionally encrypted) PIN/OTP.
  ///
  /// - [pinOrOtpType] determines whether we request a PIN or OTP.
  /// - [taskModel] contains metadata about the transaction task (e.g., whether to encrypt).
  ///
  /// Returns a Future that completes with the (possibly encrypted) PIN/OTP string.
  Future<String?> triggerPinOrOTPFlow({
    required PaymentTaskType pinOrOtpType,
    required TransactionTaskModel taskModel,
  }) {
    // Create a new completer for this flow:
    _pinOrOTPCompleter = Completer<String>();
    final controller = GlobalKey<OtpPinFieldState>();

    // Emit the appropriate transaction state so listeners know whether
    // we're asking for a PIN vs. an OTP:
    final emittedState = (pinOrOtpType == PaymentTaskType.pin)
        ? TransactionStateRequestPINTask(task: taskModel)
        : TransactionStateRequestOTPTask(task: taskModel);
    _txnStateStream.emit(state: emittedState);

    // Show the same modal widget for both PIN and OTP; we configure
    // its "task" parameter based on pinOrOtpType:
    SDKUtils.showSDKModalBottomSheet(
      callingContext: callingContext,
      child: OtpOrPinModalContent(
        controller: controller,
        // When the user taps "Submit", we encrypt if needed and call
        // the shared handler below:
        onDone: (userInput) async {
          final payload = taskModel.encrypted ?? true
              ? await CryptoUtil.encryptWithPublicKey(data: userInput)
              : userInput;

          _completePinOrOtpFlow(
            pinOrOtpType: pinOrOtpType,
            encryptedInput: payload,
          );
        },
        task: TransactionStateRequestOTPTask(
          task: taskModel,
        ),
      ),
    );

    return _pinOrOTPCompleter!.future;
  }

  /// Completes the PIN/OTP flow by filling the completer and emitting a loading state.
  /// Internally routes to either sendPINToServer or sendOTPToServer for clarity.
  void _completePinOrOtpFlow({
    required PaymentTaskType pinOrOtpType,
    required String encryptedInput,
  }) {
    if (_pinOrOTPCompleter == null || _pinOrOTPCompleter!.isCompleted) return;

    // Complete the future so that whoever awaited triggerPinOrOtpFlow()
    // now gets the value:
    _pinOrOTPCompleter!.complete(encryptedInput);

    // Emit a loading state so that UI (or any global listener) knows
    // we're in a "waiting for server response" phase:
    _sdkStateStream.emit(state: MonaSDKState.loading);

    // Route to the appropriate downstream call if you still need to call
    // separate server methods. If both methods do the same thing under the hood,
    // you can consolidate them into one. Here, we assume they are distinct.
    if (pinOrOtpType == PaymentTaskType.pin) {
      sendPINToServer(pinOrOtp: encryptedInput);
    } else {
      sendOTPToServer(pinOrOtp: encryptedInput);
    }
  }

  /// Call this from your mobile app side when user-entered OTP arrives.
  void sendOTPToServer({required String pinOrOtp}) {
    // Note: we guard against multiple completions by re-checking `.isCompleted`.
    if (_pinOrOTPCompleter != null && !_pinOrOTPCompleter!.isCompleted) {
      _pinOrOTPCompleter!.complete(pinOrOtp);
      _sdkStateStream.emit(state: MonaSDKState.loading);
    }
  }

  /// Call this from your mobile app side when user-entered PIN arrives.
  void sendPINToServer({required String pinOrOtp}) {
    if (_pinOrOTPCompleter != null && !_pinOrOTPCompleter!.isCompleted) {
      _pinOrOTPCompleter!.complete(pinOrOtp);
      _sdkStateStream.emit(state: MonaSDKState.loading);
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
