import "dart:async";
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_custom_tabs/flutter_custom_tabs.dart";
import "package:pay_with_mona/src/core/api/api_exceptions.dart";
import "package:pay_with_mona/src/core/events/auth_state_stream.dart";
import "package:pay_with_mona/src/core/events/firebase_sse_listener.dart";
import "package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart";
import "package:pay_with_mona/src/core/events/transaction_state_stream.dart";
import "package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart";
import "package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart";
import "package:pay_with_mona/src/features/controller/notifier_enums.dart";
import "package:pay_with_mona/src/core/services/auth_service.dart";
import "package:pay_with_mona/src/core/services/payments_service.dart";
import "package:pay_with_mona/src/models/mona_checkout.dart";
import "package:pay_with_mona/src/models/pending_payment_response_model.dart";
import "package:pay_with_mona/src/utils/extensions.dart";
import "package:pay_with_mona/src/utils/size_config.dart";
import "dart:math" as math;
part "sdk_notifier.helpers.dart";
part "sdk_notifier.listeners.dart";

/// Manages the entire payment workflow, from initiation to completion,
/// including real-time event listening and strong authentication.
///
/// Implements a singleton pattern to ensure a single source of truth
/// throughout the app lifecycle.
class MonaSDKNotifier extends ChangeNotifier {
  /// The single, shared instance of [MonaSDKNotifier].
  static final MonaSDKNotifier _instance = MonaSDKNotifier._internal();

  /// Factory constructor returning the singleton instance.
  factory MonaSDKNotifier({
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
  MonaSDKNotifier._internal()
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

  MonaSDKState _state = MonaSDKState.idle;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;
  PendingPaymentResponseModel? _pendingPaymentResponseModel;
  BankOption? _selectedBankOption;
  CardOption? _selectedCardOption;

  /// Current payment process state.
  MonaSDKState get state => _state;

  /// The method chosen by the user for payment.
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;

  /// Error message, if any, from the last operation.
  String? get errorMessage => _errorMessage;

  /// Identifier of the most recent transaction.
  String? get currentTransactionId => _currentTransactionId;

  PendingPaymentResponseModel? get currentPaymentResponseModel =>
      _pendingPaymentResponseModel;

  BankOption? get selectedBankOption => _selectedBankOption;

  CardOption? get selectedCardOption => _selectedCardOption;

  // Streams
  final _txnStateStream = TransactionStateStream();
  final _authStream = AuthStateStream();
  final _sdkStateStream = MonaSdkStateStream();

  Stream<TransactionState> get txnStateStream => _txnStateStream.stream;
  Stream<AuthState> get authStateStream => _authStream.stream;
  Stream<MonaSDKState> get sdkStateStream => _sdkStateStream.stream;

  /// Clean up SSE listener when this notifier is disposed.
  @override
  void dispose() {
    _firebaseSSE.dispose();
    _txnStateStream.dispose();
    _authStream.dispose();
    _sdkStateStream.dispose();
    super.dispose();
  }

  ///
  /// *** MARK: - In - house setters / update functions
  ///
  /// Sets the internal state and notifies listeners of changes.
  void _updateState(MonaSDKState newState) {
    _state = newState;
    _sdkStateStream.emit(state: newState);
    notifyListeners();
  }

  /// Records an error, updates state, and notifies listeners.
  void _handleError(String message) {
    _errorMessage = message;

    if (message.toLowerCase().contains("please login")) {
      _updateState(MonaSDKState.idle);
      _authStream.emit(state: AuthState.loggedOut);
      return;
    }

    _updateState(MonaSDKState.error);
    _errorMessage?.log();
  }

  /// Stores the transaction ID and notifies listeners .
  void _handleTransactionId(String transactionId) {
    _currentTransactionId = transactionId;
    notifyListeners();
  }

  /// Provides checkout details (e.g., colors, phone number) for UI integration.
  void setMonaCheckOut({
    required MonaCheckOut checkoutDetails,
  }) {
    _monaCheckOut = checkoutDetails;
    notifyListeners();
  }

  /// Retains the [BuildContext] to calculate UI-dependent dimensions.
  void setCallingBuildContext({
    required BuildContext context,
  }) {
    _callingBuildContext = context;
    notifyListeners();
  }

  /// Chooses the payment method (e.g., card, mobile money) before initiating payment.
  void setSelectedPaymentMethod({
    required PaymentMethod method,
  }) {
    clearSelectedPaymentMethod();
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void clearSelectedPaymentMethod() {
    _selectedPaymentMethod = PaymentMethod.none;
    _selectedBankOption = null;
    _selectedCardOption = null;
    notifyListeners();
  }

  void setSelectedBankOption({
    required BankOption bankOption,
  }) {
    _selectedBankOption = () {
      _selectedBankOption = null;
      return bankOption;
    }();
    notifyListeners();
  }

  void setSelectedCardOption({
    required CardOption cardOption,
  }) {
    _selectedCardOption = () {
      _selectedCardOption = null;
      return cardOption;
    }();
    notifyListeners();
  }

  void setPendingPaymentData({
    required PendingPaymentResponseModel pendingPayment,
  }) {
    _pendingPaymentResponseModel = () {
      _pendingPaymentResponseModel = null;
      return pendingPayment;
    }();
    notifyListeners();
  }

  Future<String?> checkIfUserHasKeyID() async => await _secureStorage.read(
        key: SecureStorageKeys.monaCheckoutID,
      );

  ///
  /// *** MARK: -  Major Methods
  Future<void> validatePII({
    String? phoneNumber,
    String? bvn,
    String? dob,
  }) async {
    _updateState(MonaSDKState.loading);

    final response = await _authService.validatePII(
      phoneNumber: phoneNumber,
      bvn: bvn,
      dob: dob,
    );

    if (response == null) {
      _handleError("Failed to validate user PII - Experienced an Error");
      return;
    }

    _updateState(MonaSDKState.idle);
    switch (response["exists"] as bool) {
      /// *** This is a Mona User
      case true:
        setPendingPaymentData(
          pendingPayment: PendingPaymentResponseModel(
            savedPaymentOptions: SavedPaymentOptions.fromJSON(
              json: response["savedPaymentOptions"],
            ),
          ),
        );

        /// *** User has not done key exchange
        if (await checkIfUserHasKeyID() == null) {
          _authStream.emit(state: AuthState.loggedOut);
          return;
        }

        /// *** User has done key exchange
        _authStream.emit(state: AuthState.loggedIn);
        break;

      /// *** Non Mona User
      default:
        _authStream.emit(state: AuthState.notAMonaUser);
        break;
    }
  }

  /// Starts the payment initiation process.
  ///
  /// 1. Updates state to [MonaSDKState.loading].
  /// 2. Calls [_paymentsService.initiatePayment].
  /// 3. Handles failure or missing transaction ID.
  /// 4. Persists user UUID from secure storage.
  /// 5. Retrieves available payment methods.
  Future<void> initiatePayment({
    required num tnxAmountInKobo,
  }) async {
    _updateState(MonaSDKState.loading);

    final (Map<String, dynamic>? success, failure) =
        await _paymentsService.initiatePayment(
      tnxAmountInKobo: tnxAmountInKobo,
    );

    if (failure != null) {
      _handleError("Payment initiation failed. Please try again.");
      throw (failure.message);
    }

    final txId = success?["transactionId"] as String?;
    if (txId == null) {
      _handleError("Invalid response from payment service.");
      return;
    }

    _handleTransactionId(txId);
    _updateState(MonaSDKState.idle);
  }

  /// *** Currently not in use - Keep for a forth night
/*   Future<void> getPaymentMethods() async {
    _updateState(MonaSDKState.loading);

    final userCheckoutID = await checkIfUserHasKeyID();

    if (userCheckoutID == null) {
      _handleError("User identifier not found. Please login again.");
      return;
    }

    try {
      final (paymentDataAndMethods, failure) =
          await _paymentsService.getPaymentMethods(
        transactionId: _currentTransactionId ?? "",
        userEnrolledCheckoutID: userCheckoutID,
      );

      if (failure != null) {
        _handleError("Payment initiation failed. Please try again.");
        _updateState(MonaSDKState.idle);
        return;
      }

      setPendingPaymentData(pendingPayment: paymentDataAndMethods!);
      _updateState(MonaSDKState.success);
    } catch (error, trace) {
      _handleError("Error fetching payment methods: $error ::: $trace");
      return;
    }
  } */

  Future<void> initKeyExchange() async {
    try {
      final sessionID = math.Random.secure().nextInt(999999999).toString();
      await _listenForAuthEvents(sessionID);

      final url = _buildURL(
        sessionID: sessionID,
        method: _selectedPaymentMethod.type,
      );

      await _launchURL(url);
    } catch (error, trace) {
      "initKeyExchange ERROR ::: $error ::: TRACE ::: $trace".log();
      _handleError("Error Initiating Key Exchange");
    }
  }

  /// Orchestrates the in-app payment flow with SSE and strong authentication.
  ///
  /// 1. Opens a custom tab to the payment URL.
  /// 2. Listens for transaction updates and strong auth tokens via SSE.
  Future<void> makePayment({
    required num tnxAmountInKobo,
  }) async {
    _updateState(MonaSDKState.loading);

    // Initialize SSE listener for real-time events
    _firebaseSSE.initialize();

    /// *** This is only for DEMO.
    /// *** Real world scenario, client would attach a transaction ID to this.
    /// *** For now - Check if we have an initiated Transaction ID else do a demo one
    if (_currentTransactionId == null) {
      await initiatePayment(tnxAmountInKobo: tnxAmountInKobo);
    }

    _updateState(MonaSDKState.loading);

    /// *** If the user doesn't have a keyID and they want to use a saved payment method,
    /// *** Key exchange needs to be done, so handle first.
    final doKeyExchange = await checkIfUserHasKeyID() == null &&
        [
          PaymentMethod.savedBank,
          PaymentMethod.savedCard,
        ].contains(_selectedPaymentMethod);

    if (doKeyExchange) {
      await initKeyExchange();
    }

    bool hasError = false;
    bool hasTransactionUpdateError = false;

    /// *** Concurrently listen for transaction completion.
    await Future.wait([
      _listenForPaymentUpdates(hasError),
      _listenForTransactionUpdateEvents(hasTransactionUpdateError),
    ]);

    switch (_selectedPaymentMethod) {
      case PaymentMethod.savedBank || PaymentMethod.savedCard:
        try {
          await _paymentsService.makePaymentRequest(
            onPayComplete: () {
              "Payment Notifier ::: Make Payment Request Complete".log();

              clearSelectedPaymentMethod();
              _currentTransactionId = null;
            },
          );

          _updateState(MonaSDKState.idle);
        } catch (error, trace) {
          _handleError("Error listening for transaction updates.");
          "Payment Notifier ::: makePayment ::: PaymentMethod.savedBank ::: ERROR ::: $error TRACE ::: $trace"
              .log();
        }
        break;

      /// ***
      /// *** At this point, it's a regular payment method with either card or transfer
      /// *** Regardless of if saved methods are available or not.
      default:
        await handleRegularPayment();
        break;
    }
  }

  Future<void> handleRegularPayment() async {
    final sessionID = _generateSessionID();
    await _listenForAuthEvents(sessionID);

    final url = _buildURL(
      sessionID: sessionID,
      method: _selectedPaymentMethod.type,
    );

    await _launchURL(url);
  }

  ///
  /// *** Performs strong authentication using the received SSE token.
  ///
  /// Updates payment methods upon success.
  Future<void> loginWithStrongAuth() async {
    _updateState(MonaSDKState.loading);
    try {
      final response = await _authService.loginWithStrongAuth(
        strongAuthToken: _strongAuthToken ?? "",
        phoneNumber: _monaCheckOut?.phoneNumber ?? "",
      );

      if (response == null) {
        _handleError("Strong authentication failed.");
        return;
      }

      await _authService.signAndCommitAuthKeys(
        deviceAuth: response["deviceAuth"],
        onSuccess: () async {
          final userCheckoutID = await _secureStorage.read(
            key: SecureStorageKeys.monaCheckoutID,
          );

          if (userCheckoutID == null) {
            _handleError("User identifier missing.");
            return;
          }

          await _paymentsService.getPaymentMethods(
            transactionId: _currentTransactionId ?? "",
            userEnrolledCheckoutID: userCheckoutID,
          );

          _updateState(MonaSDKState.success);
          _authStream.emit(state: AuthState.loggedIn);
        },
      );
    } catch (e) {
      _handleError("Unexpected error during authentication.");
    }
  }

  /// Resets the entire SDKNotifier back to its initial, un-initialized state.
  ///
  /// - Clears all stored data and tokens
  /// - Tears down and re-creates SSE listeners & streams
  /// - Returns state to [MonaSDKState.idle] and notifies subscribers
  void invalidate() {
    _firebaseSSE.dispose();
    _txnStateStream.dispose();
    _authStream.dispose();
    _sdkStateStream.dispose();

    _errorMessage = null;
    _currentTransactionId = null;
    _strongAuthToken = null;
    _monaCheckOut = null;
    _callingBuildContext = null;
    _state = MonaSDKState.idle;
    _selectedPaymentMethod = PaymentMethod.none;
    _pendingPaymentResponseModel = null;
    _selectedBankOption = null;
    _selectedCardOption = null;

    notifyListeners();
  }
}
