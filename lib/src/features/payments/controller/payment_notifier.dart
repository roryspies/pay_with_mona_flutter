import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pay_with_mona/src/core/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/payments/payments_service.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class PaymentNotifier extends ChangeNotifier {
  final PaymentService _paymentsService;
  final _firebaseSSE = FirebaseSSEListener();
  String? _errorMessage;
  String? _currentTransactionId;
  PaymentState _state = PaymentState.idle;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;

  /// ***
  PaymentState get state => _state;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  String? get errorMessage => _errorMessage;
  String? get currentTransactionId => _currentTransactionId;

  PaymentNotifier({
    PaymentService? paymentsService,
  }) : _paymentsService = paymentsService ?? PaymentService();

  Future<void> initiatePayment({
    required String method,
    required BuildContext context,
  }) async {
    _setState(PaymentState.loading);

    final (Map<String, dynamic>? success, failure) =
        await _paymentsService.initiatePayment();
    if (failure != null) {
      _setError("Payment failed. Try again.");
    } else if (success != null) {
      '$success'.log();

      _setTransactionId(success['transactionId']);

      _setState(PaymentState.success);
    }
  }

  Future<void> makePayment({
    required MonaCheckOut monaCheckOut,
    required String method,
    required BuildContext context,
  }) async {
    _setState(PaymentState.loading);

    String transactionId = monaCheckOut.transactionId;

    bool hasError = false;

    _firebaseSSE.initialize(
        databaseUrl:
            'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app');

    _firebaseSSE.startListening(
      transactionId: transactionId,
      onDataChange: (event) {
        /// *** TODO: grab the data map, not just event string
        '🔥 [SSEListener] Event Received: $event'.log();
        if (event == 'transaction_completed' || event == 'transaction_failed') {
          _firebaseSSE.dispose();
          closeCustomTabs();
        }
      },
      onError: (error) {
        '❌ [SSEListener] Error: $error'.log();
        _setError('');
        hasError = true;
      },
    );

    if (hasError) {
      return;
    }

    // Fetch device info
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    // Fetch app version and build number
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    Map<String, Object>? data;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      data = {
        "sessionId": '',
        "countryCode": '+234',
        "deviceInfo": {
          "name": androidInfo.product,
          "system": "Android ${androidInfo.version.release}",
          "model": androidInfo.model,
          "brand": androidInfo.brand,
          "isLowRamDevice": androidInfo.isLowRamDevice,
          "version": appVersion,
        },
      };
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      data = {
        "sessionId": '',
        "countryCode": '+234',
        "deviceInfo": {
          "name": iosInfo.name,
          "system": "iOS ${iosInfo.systemVersion}",
          "model": iosInfo.model,
          "brand": iosInfo.modelName,
          "isLowRamDevice": false,
          "version": appVersion,
        },
      };
    }

    data.toString().log();
    String deviceInfoQuery = base64Encode(utf8.encode(jsonEncode(data)));

    String url =
        'https://pay.development.mona.ng/$transactionId?embedding=true&sdk=true&method=$method&deviceInfo=$deviceInfoQuery';

    // method=bank&bankId=

    url.log();

    await launchUrl(
      Uri.parse(url),
      customTabsOptions: CustomTabsOptions.partial(
        shareState: CustomTabsShareState.off,
        configuration: PartialCustomTabsConfiguration(
          initialHeight: context.screenHeight * 0.95,
          activityHeightResizeBehavior:
              CustomTabsActivityHeightResizeBehavior.fixed,
        ),
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: monaCheckOut.primaryColor,
          navigationBarColor: monaCheckOut.primaryColor,
        ),
        showTitle: false,
      ),
      safariVCOptions: SafariViewControllerOptions.pageSheet(
        configuration: const SheetPresentationControllerConfiguration(
          detents: {
            SheetPresentationControllerDetent.large,
            // SheetPresentationControllerDetent.medium,
          },
          prefersScrollingExpandsWhenScrolledToEdge: true,
          prefersGrabberVisible: false,
          prefersEdgeAttachedInCompactHeight: true,
        ),
        preferredBarTintColor: monaCheckOut.primaryColor,
        preferredControlTintColor: monaCheckOut.primaryColor,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.done,
      ),
    );

    _setState(PaymentState.success);
  }

  void disposeSSEListener() {
    _firebaseSSE.dispose();
  }

  void _setState(PaymentState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(PaymentState.error);
  }

  void _setTransactionId(String transactionId) {
    _currentTransactionId = transactionId;
    notifyListeners();
  }

  void updateSelectedPaymentType({
    required PaymentMethod selectedPaymentMethod,
  }) {
    _selectedPaymentMethod = selectedPaymentMethod;
    notifyListeners();
  }
}
