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

    assert(
      _callingBuildContext != null,
      "Build context must be set before launching URL",
    );

    final screenHeight = _callingBuildContext!.screenHeight;
    final screenWidth = _callingBuildContext!.screenWidth;

    try {
      /* SDKUtils.showSDKModalBottomSheet(
        callingContext: _callingBuildContext!,
        isDismissible: false,
        enableDrag: false,
        isForCustomTab: true,
        onCancelButtonTap: () {
          _updateState(MonaSDKState.idle);
          Navigator.of(_callingBuildContext!).pop();
        },
        child: CustomWebView(
          initialUrl: url,
        ),
      ); */
      /* CustomTabsOptions.partial(
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
        ), */
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

  Future<String?> triggerPinOrOTPFlow({
    required PaymentTaskType pinOrOTP,
    required TransactionTaskModel pinOrOTPTask,
  }) {
    _pinOrOTPCompleter = Completer<String>();
    final otpPinFieldController = GlobalKey<OtpPinFieldState>();

    if (pinOrOTP == PaymentTaskType.pin) {
      _txnStateStream.emit(
        state: TransactionStateRequestPINTask(
          task: pinOrOTPTask,
        ),
      );
    } else if (pinOrOTP == PaymentTaskType.otp) {
      SDKUtils.showSDKModalBottomSheet(
        callingContext: _callingBuildContext!,
        child: OtpOrPinModalContent(
          controller: otpPinFieldController,
          onDone: (pinOrOTP) {
            sendOTPToServer(pinOrOTP: pinOrOTP);
          },
          task: TransactionStateRequestOTPTask(
            task: pinOrOTPTask,
          ),
        ),
      );
    }

    return _pinOrOTPCompleter!.future;
  }

  /// Call this from your mobile app side when user enters OTP/PIN
  void sendOTPToServer({
    required String pinOrOTP,
  }) {
    if (_pinOrOTPCompleter != null && !_pinOrOTPCompleter!.isCompleted) {
      _pinOrOTPCompleter!.complete(pinOrOTP);
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
