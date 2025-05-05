import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/core/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/payments/payments_service.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'dart:math' as math;

part 'payments_notifier.helpers.dart';

class PaymentNotifier extends ChangeNotifier {
  static final PaymentNotifier _instance = PaymentNotifier._internal();
  factory PaymentNotifier() => _instance;
  PaymentNotifier._internal({
    PaymentService? paymentsService,
  }) : _paymentsService = paymentsService ?? PaymentService();

  final PaymentService _paymentsService;
  final _firebaseSSE = FirebaseSSEListener();
  final _apiService = ApiService();
  String? _errorMessage;
  String? _currentTransactionId;
  String? _strongAuthToken;
  MonaCheckOut? _monaCheckOut;
  BuildContext? _callingBuildContext;
  PaymentState _state = PaymentState.idle;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;

  /// ***
  PaymentState get state => _state;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  String? get errorMessage => _errorMessage;
  String? get currentTransactionId => _currentTransactionId;

  Future<void> initiatePayment() async {
    _setState(PaymentState.loading);

    final (Map<String, dynamic>? success, failure) =
        await _paymentsService.initiatePayment();

    if (failure != null) {
      _setError("Payment failed. Try again.");
      return;
    }

    if (success == null || success['transactionId'] == null) {
      _setError("Invalid response from payment service.");
      return;
    }

    _setTransactionId(success['transactionId'] as String);
    "✅ Payment initiated: $success".log();

    _setState(PaymentState.success);
  }

  Future<void> makePayment({
    required String method,
  }) async {
    _setState(PaymentState.loading);
    bool hasError = false;
    bool customPathError = false;

    "✅ Mona user payment initiated".log();

    _firebaseSSE.initialize(
      databaseUrl:
          'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app',
    );

    final sessionID = "${math.Random.secure().nextInt(999999999)}";

    await Future.wait(
      [
        /// *** Listen for transaction events and handle where necessary
        _firebaseSSE.startListening(
          transactionId: _currentTransactionId ?? "",
          onDataChange: (event) {
            '🔥 [SSEListener] Event Received: $event'.log();
            if (event == 'transaction_completed' ||
                event == 'transaction_failed') {
              _firebaseSSE.dispose();
              closeCustomTabs();
            }
          },
          onError: (error) {
            '❌ [SSEListener] Error: $error'.log();
            _setError('');
            hasError = true;
          },
        ),

        /// *** Listen for Strong Auth Events and handle where necessary
        _firebaseSSE.listenToCustomEvents(
          sessionID: sessionID,
          onDataChange: (strongAuthToken) async {
            '🔥 [listenToCustomEvents] Event Received: $strongAuthToken'.log();
            _strongAuthToken = strongAuthToken;
            await closeCustomTabs();
            await openLoginCustomTab();
          },
          onError: (error) {
            '❌ [listenToCustomEvents] Error: $error'.log();
            _setError('');
            customPathError = true;
          },
        )
      ],
    );

    if (hasError || customPathError) {
      return;
    }

    final url =
        "https://pay.development.mona.ng/login?loginScope=${Uri.encodeComponent("67e41f884126830aded0b43c")}&redirect=${Uri.encodeComponent("https://pay.development.mona.ng/${_currentTransactionId ?? ""}?embedding=true&sdk=true&method=${_selectedPaymentMethod.type}")}&sessionId=${Uri.encodeComponent(sessionID)}";

    url.log();

    await launchUrl(
      Uri.parse(url),
      customTabsOptions: CustomTabsOptions.partial(
        shareState: CustomTabsShareState.off,
        configuration: PartialCustomTabsConfiguration(
          initialHeight: _callingBuildContext!.screenHeight * 0.95,
          activityHeightResizeBehavior:
              CustomTabsActivityHeightResizeBehavior.fixed,
        ),
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: _monaCheckOut?.primaryColor,
          navigationBarColor: _monaCheckOut?.primaryColor,
        ),
        showTitle: false,
      ),
      safariVCOptions: SafariViewControllerOptions.pageSheet(
        configuration: const SheetPresentationControllerConfiguration(
          detents: {
            SheetPresentationControllerDetent.large,
          },
          prefersScrollingExpandsWhenScrolledToEdge: true,
          prefersGrabberVisible: false,
          prefersEdgeAttachedInCompactHeight: true,
          preferredCornerRadius: 16.0,
        ),
        preferredBarTintColor: _monaCheckOut?.secondaryColor,
        preferredControlTintColor: _monaCheckOut?.primaryColor,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.done,
      ),
    );
  }

  Future<void> openLoginCustomTab() async {
    try {
      final url = Uri.https(
        'api.development.mona.ng',
        '/login',
        {
          'auth_token': _strongAuthToken,
          'key_exchange': "true",
        },
      );

      final loginUrl = Uri(
        scheme: 'https',
        host: 'api.development.mona.ng',
        path: '/login',
        queryParameters: {
          'x-strong-auth-token': _strongAuthToken,
          'x-mona-key-exchange': "true",
        },
      );

      /* final url =
          "https://api.development.mona.ng/login?strongAuthToken=${Uri.encodeComponent(_strongAuthToken ?? "")}?keyExchange=${Uri.encodeComponent("true")}";
 */
      url.log();
      loginUrl.log();

      await launchUrl(
        loginUrl,
        //Uri.parse(url),
        /* webViewConfiguration: const WebViewConfiguration(
          headers: {
            'x-strong-auth-token': strongAuthToken,
            'x-mona-key-exchange': '$keyExchange',
          },
        ), */
        customTabsOptions: CustomTabsOptions.partial(
          shareState: CustomTabsShareState.off,
          configuration: PartialCustomTabsConfiguration(
            initialHeight: _callingBuildContext!.screenHeight * 0.95,
            activityHeightResizeBehavior:
                CustomTabsActivityHeightResizeBehavior.fixed,
          ),
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: _monaCheckOut?.primaryColor,
            navigationBarColor: _monaCheckOut?.primaryColor,
          ),
          showTitle: false,
        ),
        safariVCOptions: SafariViewControllerOptions.pageSheet(
          configuration: const SheetPresentationControllerConfiguration(
            detents: {
              SheetPresentationControllerDetent.large,
            },
            prefersScrollingExpandsWhenScrolledToEdge: true,
            prefersGrabberVisible: false,
            prefersEdgeAttachedInCompactHeight: true,
            preferredCornerRadius: 16.0,
          ),
          preferredBarTintColor: _monaCheckOut?.secondaryColor,
          preferredControlTintColor: _monaCheckOut?.primaryColor,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.done,
        ),
      );
      "✅ Custom tab opened successfully".log();
    } catch (error, trace) {
      "❌ openLoginCustomTab() Error: $error ::: Trace - $trace".log();
      _setError("An error occurred. Please try again.");
    } finally {
      _setState(PaymentState.idle);
    }
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

  void setMonaCheckOut({
    required MonaCheckOut checkoutDetails,
  }) {
    _monaCheckOut = checkoutDetails;
    notifyListeners();
  }

  void setCallingBuildContext({
    required BuildContext context,
  }) {
    _callingBuildContext = context;
    notifyListeners();
  }

  void setSelectedPaymentType({
    required PaymentMethod selectedPaymentMethod,
  }) {
    _selectedPaymentMethod = selectedPaymentMethod;
    notifyListeners();
  }
}
