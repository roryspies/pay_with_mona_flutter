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

    await launchUrl(
      uri,
      customTabsOptions: CustomTabsOptions.partial(
        configuration: PartialCustomTabsConfiguration(
          activityHeightResizeBehavior:
              CustomTabsActivityHeightResizeBehavior.fixed,
          initialHeight: _callingBuildContext!.screenHeight * 0.95,
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
