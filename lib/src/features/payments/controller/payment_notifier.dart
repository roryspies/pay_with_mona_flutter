import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/core/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/core/secure_storage.dart';
import 'package:pay_with_mona/src/core/secure_storage_keys.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/core/auth_service.dart';
import 'package:pay_with_mona/src/core/payments_service.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'dart:math' as math;

/// Manages the entire payment workflow, from initiation to completion,
/// including real-time event listening and strong authentication.
///
/// Implements a singleton pattern to ensure a single source of truth
/// throughout the app lifecycle.
class PaymentNotifier extends ChangeNotifier {
  /// The single, shared instance of [PaymentNotifier].
  static final PaymentNotifier _instance = PaymentNotifier._internal();

  /// Factory constructor returning the singleton instance.
  factory PaymentNotifier({
    PaymentService? paymentsService,
    AuthService? authService,
    SecureStorage? secureStorage,
  }) {
    // Allow dependency injection for testing or customization
    _instance._paymentsService = paymentsService ?? _instance._paymentsService;
    _instance._authService = authService ?? _instance._authService;
    _instance._secureStorage = secureStorage ?? _instance._secureStorage;
    return _instance;
  }

  /// Internal constructor initializes default services.
  PaymentNotifier._internal()
      : _paymentsService = PaymentService(),
        _authService = AuthService(),
        _secureStorage = SecureStorage();

  /// Service responsible for initiating and completing payments.
  late PaymentService _paymentsService;

  /// Service responsible for handling strong authentication.
  late AuthService _authService;

  /// Secure storage for persisting user identifiers.
  late SecureStorage _secureStorage;

  /// Listener for Firebase Server-Sent Events.
  final FirebaseSSEListener _firebaseSSE = FirebaseSSEListener();

  String? _errorMessage;
  String? _currentTransactionId;
  String? _strongAuthToken;
  MonaCheckOut? _monaCheckOut;
  BuildContext? _callingBuildContext;

  PaymentState _state = PaymentState.idle;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;

  /// Current payment process state.
  PaymentState get state => _state;

  /// The method chosen by the user for payment.
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  /// Error message, if any, from the last operation.
  String? get errorMessage => _errorMessage;

  /// Identifier of the most recent transaction.
  String? get currentTransactionId => _currentTransactionId;

  /// Clean up SSE listener when this notifier is disposed.
  @override
  void dispose() {
    _firebaseSSE.dispose();
    super.dispose();
  }

  /// Sets the internal state and notifies listeners of changes.
  void _updateState(PaymentState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Records an error, updates state, and notifies listeners.
  void _handleError(String message) {
    _errorMessage = message;
    _updateState(PaymentState.error);
  }

  /// Stores the transaction ID and notifies listeners.
  void _handleTransactionId(String transactionId) {
    _currentTransactionId = transactionId;
    notifyListeners();
  }

  /// Provides checkout details (e.g., colors, phone number) for UI integration.
  void setMonaCheckOut({required MonaCheckOut checkoutDetails}) {
    _monaCheckOut = checkoutDetails;
    notifyListeners();
  }

  /// Retains the [BuildContext] to calculate UI-dependent dimensions.
  void setCallingBuildContext({required BuildContext context}) {
    _callingBuildContext = context;
    notifyListeners();
  }

  /// Chooses the payment method (e.g., card, mobile money) before initiating payment.
  void setSelectedPaymentMethod({required PaymentMethod method}) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  /// Starts the payment initiation process.
  ///
  /// 1. Updates state to [PaymentState.loading].
  /// 2. Calls [_paymentsService.initiatePayment].
  /// 3. Handles failure or missing transaction ID.
  /// 4. Persists user UUID from secure storage.
  /// 5. Retrieves available payment methods.
  Future<void> initiatePayment() async {
    _updateState(PaymentState.loading);

    final (Map<String, dynamic>? success, failure) =
        await _paymentsService.initiatePayment();

    if (failure != null) {
      _handleError('Payment initiation failed. Please try again.');
      return;
    }

    final txId = success?['transactionId'] as String?;
    if (txId == null) {
      _handleError('Invalid response from payment service.');
      return;
    }

    _handleTransactionId(txId);
    final userCheckoutID = await _secureStorage.read(
      key: SecureStorageKeys.monaCheckoutID,
    );

    if (userCheckoutID == null) {
      _handleError('User identifier not found. Please log in again.');
      return;
    }

    "UUID ::: $userCheckoutID".log();

    // Fetch available payment methods for the transaction
    await _paymentsService.getPaymentMethods(
      transactionId: txId,
      userEnrolledCheckoutID: userCheckoutID,
    );

    _updateState(PaymentState.success);
  }

  /// Orchestrates the in-app payment flow with SSE and strong authentication.
  ///
  /// 1. Opens a custom tab to the payment URL.
  /// 2. Listens for transaction updates and strong auth tokens via SSE.
  Future<void> makePayment({required String method}) async {
    _updateState(PaymentState.loading);

    // Initialize SSE listener for real-time events
    _firebaseSSE.initialize(
      databaseUrl:
          'https://mona-money-default-rtdb.europe-west1.firebasedatabase.app',
    );

    final sessionID = math.Random.secure().nextInt(999999999).toString();
    bool hasError = false;
    bool authError = false;

    // Concurrently listen for transaction completion and authentication tokens
    await Future.wait([
      _listenForTransactionEvents(hasError),
      _listenForAuthEvents(sessionID, authError),
    ]);

    // ignore: dead_code
    if (hasError || authError) return;

    final url = _buildPaymentUrl(sessionID, method);
    await _launchPaymentUrl(url);
  }

  Future<void> _listenForTransactionEvents(bool errorFlag) async {
    await _firebaseSSE.startListening(
      transactionId: _currentTransactionId ?? '',
      onDataChange: (event) {
        if (event == 'transaction_completed' || event == 'transaction_failed') {
          _firebaseSSE.dispose();
          closeCustomTabs();
        }
      },
      onError: (error) {
        _handleError('Error listening for transaction updates.');
        errorFlag = true;
      },
    );
  }

  Future<void> _listenForAuthEvents(String sessionId, bool errorFlag) async {
    await _firebaseSSE.listenToCustomEvents(
      sessionID: sessionId,
      onDataChange: (token) async {
        _strongAuthToken = token;
        await closeCustomTabs();
        await loginWithStrongAuth();
      },
      onError: (error) {
        _handleError('Error during strong authentication.');
        errorFlag = true;
      },
    );
  }

  /// Builds the URL for the in-app payment custom tab.
  String _buildPaymentUrl(String sessionID, String method) {
    final redirect = Uri.encodeComponent(
      'https://pay.development.mona.ng/$_currentTransactionId?embedding=true&sdk=true&method=$method',
    );

    return 'https://pay.development.mona.ng/login'
        '?loginScope=${Uri.encodeComponent('67e41f884126830aded0b43c')}'
        '&redirect=$redirect'
        '&sessionId=${Uri.encodeComponent(sessionID)}';
  }

  /// Launches the payment URL using platform-specific custom tab settings.
  Future<void> _launchPaymentUrl(String url) async {
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

  /// Performs strong authentication using the received SSE token.
  ///
  /// Updates payment methods upon success.
  Future<void> loginWithStrongAuth() async {
    _updateState(PaymentState.loading);
    try {
      final response = await _authService.loginWithStrongAuth(
        strongAuthToken: _strongAuthToken ?? '',
        phoneNumber: _monaCheckOut?.phoneNumber ?? '',
      );
      if (response == null) {
        _handleError('Strong authentication failed.');
        return;
      }

      await _authService.signAndCommitAuthKeys(
        deviceAuth: response['deviceAuth'],
        onSuccess: () async {
          final userCheckoutID = await _secureStorage.read(
            key: SecureStorageKeys.monaCheckoutID,
          );

          if (userCheckoutID == null) {
            _handleError('User identifier missing.');
            return;
          }

          await _paymentsService.getPaymentMethods(
            transactionId: _currentTransactionId ?? '',
            userEnrolledCheckoutID: userCheckoutID,
          );

          _updateState(PaymentState.success);
        },
      );
    } catch (e) {
      _handleError('Unexpected error during authentication.');
    }
  }
}
