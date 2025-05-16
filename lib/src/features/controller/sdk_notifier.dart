import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/events/auth_state_stream.dart';
import 'package:pay_with_mona/src/core/events/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/core/events/models/transaction_task_model.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';
import 'package:pay_with_mona/src/core/events/transaction_state_classes.dart';
import 'package:pay_with_mona/src/core/events/transaction_state_stream.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart';
import 'package:pay_with_mona/src/core/services/collections_services.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_checkout_sheet.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/core/services/auth_service.dart';
import 'package:pay_with_mona/src/core/services/payments_service.dart';
import 'package:pay_with_mona/src/models/collection_response.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'dart:math' as math;

part 'sdk_notifier.helpers.dart';
part 'sdk_notifier.listeners.dart';

/// Manages the entire payment workflow, from initiation to completion,
/// including real-time event listening and strong authentication.
///
/// Implements a singleton pattern to ensure a single source of truth
/// throughout the app lifecycle.
class MonaSDKNotifier extends ChangeNotifier {
  /// The single, shared instance of [MonaSDKNotifier].
  static final MonaSDKNotifier _instance = MonaSDKNotifier._internal();

  /// Factory constructor returning the singleton instance.
  factory MonaSDKNotifier(
      {PaymentService? paymentsService,
      AuthService? authService,
      SecureStorage? secureStorage,
      CollectionsService? collectionsService}) {
    // Allow dependency injection for testing or customization
    _instance._paymentsService = paymentsService ?? _instance._paymentsService;
    _instance._authService = authService ?? _instance._authService;
    _instance._secureStorage = secureStorage ?? _instance._secureStorage;
    _instance._collectionsService =
        collectionsService ?? _instance._collectionsService;
    return _instance;
  }

  /// Internal constructor initializes default services.
  MonaSDKNotifier._internal()
      : _paymentsService = PaymentService(),
        _authService = AuthService(),
        _secureStorage = SecureStorage(),
        _collectionsService = CollectionsService();

  /// Service responsible for initiating and completing payments.
  late PaymentService _paymentsService;

  /// Service responsible for handling strong authentication.
  late AuthService _authService;

  /// Service responsible for managing collections.
  late CollectionsService _collectionsService;

  /// Secure storage for persisting user identifiers.
  late SecureStorage _secureStorage;

  /// Listener for Firebase Server-Sent Events.
  final FirebaseSSEListener _firebaseSSE = FirebaseSSEListener();

  String? _errorMessage;
  String? _currentTransactionId;
  String? _currentTransactionFriendlyID;
  String? _strongAuthToken;
  String? _transactionOTP;
  String? _transactionPIN;
  MonaCheckOut? _monaCheckOut;
  BuildContext? _callingBuildContext;

  MonaSDKState _state = MonaSDKState.idle;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;
  PendingPaymentResponseModel? _pendingPaymentResponseModel;
  BankOption? _selectedBankOption;
  CardOption? _selectedCardOption;

  ///
  Completer<String>? _pinOrOTPCompleter;

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

    if (message
        .toLowerCase()
        .contains("transaction amount cannot be less than 20")) {
      _updateState(MonaSDKState.idle);
      message.log();
      throw (message);
    }

    _updateState(MonaSDKState.error);
    _errorMessage?.log();
  }

  /// Stores the transaction ID and notifies listeners .
  void _handleTransactionId(String transactionId, {String? friendlyID}) {
    _currentTransactionId = transactionId;
    _currentTransactionFriendlyID = friendlyID;
    notifyListeners();
  }

  /// Provides checkout details (e.g., colors, phone number) for UI integration.
  void setMonaCheckOut({required MonaCheckOut checkoutDetails, F}) {
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

  void setTransactionOTP({
    required String receivedOTP,
  }) {
    _transactionOTP = () {
      _transactionOTP = null;
      return receivedOTP;
    }();
    notifyListeners();
  }

  void setTransactionPIN({
    required String receivedPIN,
  }) {
    _transactionPIN = () {
      _transactionPIN = null;
      return receivedPIN;
    }();
    notifyListeners();
  }

  Future<String?> checkIfUserHasKeyID() async => await _secureStorage.read(
        key: SecureStorageKeys.keyID,
      );

  ///
  /// *** MARK: -  Major Methods
  Future<void> validatePII({
    String? phoneNumber,
    String? bvn,
    String? dob,
    void Function(String)? onEffect,
  }) async {
    _updateState(MonaSDKState.loading);

    final userKeyID = await checkIfUserHasKeyID();

    final response = await _authService.validatePII(
      phoneNumber: phoneNumber,
      bvn: bvn,
      dob: dob,
      userKeyID: userKeyID,
    );

    if (response == null) {
      _handleError("Failed to validate user PII - Experienced an Error");
      onEffect?.call("Failed to validate user PII - Experienced an Error");
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
          onEffect?.call('PII Auth Result - User has not done key exchange');
          return;
        }

        /// *** User has done key exchange
        _authStream.emit(state: AuthState.loggedIn);
        onEffect?.call(
            'PII Auth Result - User logged in and has done key exchange');
        break;

      /// *** Non Mona User
      default:
        _authStream.emit(state: AuthState.notAMonaUser);
        onEffect?.call('PII Auth Result - User is not a mona user');
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
  Future<void> _initiatePayment({
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
    final friendlyID = success?["friendlyID"] as String?;
    if (txId == null || friendlyID == null) {
      _handleError("Invalid response from payment service.");
      return;
    }

    _handleTransactionId(
      txId,
      friendlyID: friendlyID,
    );
    _updateState(MonaSDKState.idle);
  }

  /// Initializes key exchange process by generating a session ID, listening for auth events,
  /// launching the custom tab, and waiting for the auth process to complete.
  ///
  /// Throws [MonaSDKError] if any step fails.
  Future<void> initKeyExchange({
    bool withRedirect = true,
    bool isFromCollections = false,
  }) async {
    try {
      final sessionID = _generateSessionID();
      final authCompleter = Completer<void>();

      /// *** Needed to trigger necessary Key Exchange stuffs.
      await _listenForAuthEvents(sessionID, authCompleter);

      final url = _buildURL(
        isFromCollections: isFromCollections,
        withRedirect: withRedirect,
        sessionID: sessionID,
        method: _selectedPaymentMethod,
        bankOrCardId: _selectedPaymentMethod == PaymentMethod.savedBank
            ? _selectedBankOption?.bankId
            : _selectedCardOption?.bankId,
      );

      await _launchURL(url);
      await authCompleter.future;
    } catch (error, trace) {
      "initKeyExchange ERROR ::: $error ::: TRACE ::: $trace".log();
      _handleError("Error Initiating Key Exchange");
      rethrow;
    }
  }

  /// Orchestrates the in-app payment flow with SSE and strong authentication.
  ///
  /// 1. Opens a custom tab to the payment URL.
  /// 2. Listens for transaction updates and strong auth tokens via SSE.
  Future<void> makePayment() async {
    _updateState(MonaSDKState.loading);

    // Initialize SSE listener for real-time events
    _firebaseSSE.initialize();

    if ((_monaCheckOut!.amount / 100) < 20) {
      _handleError("Transaction amount cannot be less than 20");
      return;
    }

    /// *** This is only for DEMO.
    /// *** Real world scenario, client would attach a transaction ID to this.
    /// *** For now - Check if we have an initiated Transaction ID else do a demo one
    if (_currentTransactionId == null) {
      await _initiatePayment(
        tnxAmountInKobo: _monaCheckOut!.amount,
      );
    }

    _updateState(MonaSDKState.loading);

    /// *** Concurrently listen for transaction completion.
    try {
      await Future.wait(
        [
          _listenForPaymentUpdates(),
          _listenForTransactionUpdateEvents(),
        ],
      );
    } catch (error) {
      "MonaSDKNotifier ::: makePayment ::: ```Concurrently listen for transaction completion.``` ::: Error ::: $error"
          .log();
      _handleError("Error during payment process: $error");
    }

    /// *** If the user doesn't have a keyID and they want to use a saved payment method,
    /// *** Key exchange needs to be done, so handle first.
    final doKeyExchange = await checkIfUserHasKeyID() == null &&
        [
          PaymentMethod.savedBank,
          PaymentMethod.savedCard,
        ].contains(_selectedPaymentMethod);

    /// *** Payment process will be handled here on the web, if there is no checkout ID / Key Exchange done
    /// *** previously
    if (doKeyExchange) {
      "DO KEY EXCHANGE".log();
      await initKeyExchange();
    }

    switch (_selectedPaymentMethod) {
      case PaymentMethod.savedBank || PaymentMethod.savedCard:
        try {
          await _paymentsService.makePaymentRequest(
            paymentType: _selectedPaymentMethod == PaymentMethod.savedBank
                ? null
                : TransactionPaymentTypes.card,
            onPayComplete: (res, payload) {
              "Payment Notifier ::: Make Payment Request Complete".log();

              _currentTransactionFriendlyID = res["friendlyID"];
              _sdkStateStream.emit(state: MonaSDKState.transactionInitiated);

              /* clearSelectedPaymentMethod();
              _currentTransactionId = null;
              _transactionOTP = null;
              _transactionPIN = null; */
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
    final authCompleter = Completer<void>();
    await _listenForAuthEvents(sessionID, authCompleter);

    final url = _buildURL(
      sessionID: sessionID,
      method: _selectedPaymentMethod,
      bankOrCardId: _selectedPaymentMethod == PaymentMethod.savedBank
          ? _selectedBankOption?.bankId
          : _selectedCardOption?.bankId,
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

          _updateState(MonaSDKState.success);
          _authStream.emit(state: AuthState.loggedIn);
          validatePII();
          resetSDKState(clearMonaCheckout: false);
        },
      );
    } catch (e) {
      _handleError("Unexpected error during authentication.");
    }
  }

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
    required List<Map<String, dynamic>> scheduleEntries,
    void Function(Map<String, dynamic>?)? onSuccess,
    void Function()? onFailure,
  }) async {
    _updateState(MonaSDKState.loading);

    _firebaseSSE.initialize();
    try {
      await _collectionsService.createCollectionRequest(
        bankId: bankId,
        maximumAmount: maximumAmount,
        expiryDate: expiryDate,
        startDate: startDate,
        monthlyLimit: monthlyLimit,
        reference: reference,
        type: type,
        frequency: frequency,
        amount: amount,
        merchantId: merchantId,
        scheduleEntries: scheduleEntries,
        onComplete: (res, p) {
          final success = res as Map<String, dynamic>;
          success.log();
          onSuccess?.call(success);
        },
        onError: () {
          _updateState(MonaSDKState.error);
          onFailure?.call();
        },
      );

      _updateState(MonaSDKState.success);
    } catch (e) {
      onFailure?.call();
      e.toString().log();
      _handleError(e.toString());
    }
  }

  Future<void> triggerCollection({
    required String merchantId,
    required int timeFactor,
    void Function(Map<String, dynamic>?)? onSuccess,
    void Function(String)? onError,
  }) async {
    _updateState(MonaSDKState.loading);
    try {
      final (Map<String, dynamic>? success, failure) =
          await _collectionsService.triggerCollection(
        merchantId: merchantId,
        timeFactor: timeFactor,
      );

      if (failure != null) {
        _handleError('Collection trigger failed.');
        onError?.call('Collection trigger failed.');
        // throw (failure.message);
      }

      if (success != null) {
        success.log();

        // Extract transaction ID from the nested response
        String? transactionId;
        if (success['success'] == true &&
            success['data'] is List &&
            (success['data'] as List).isNotEmpty) {
          final firstTransaction = (success['data'] as List).first;
          if (firstTransaction is Map<String, dynamic>) {
            // Get the transactionRef which appears to be the transaction ID
            transactionId = firstTransaction['transactionRef'] as String?;
          }
        }

        if (transactionId != null) {
          _handleTransactionId(transactionId);
          _listenForTransactionUpdateEvents();
        }

        onSuccess?.call(success);
      }

      _updateState(MonaSDKState.success);
    } catch (e) {
      e.toString().log();
      _handleError(e.toString());
      onError?.call('Collection trigger failed.');
    }
  }

  Future<void> createCollectionsNavigation({
    required String maximumAmount,
    required String expiryDate,
    required String startDate,
    required String monthlyLimit,
    required String reference,
    required String type,
    required String frequency,
    required String? amount,
    required String merchantId,
    required String merchantName,
    required CollectionsMethod method,
    required List<Map<String, dynamic>> scheduleEntries,
    void Function(Map<String, dynamic>?)? onSuccess,
  }) async {
    //     if (failure != null) {
    //       _handleError('Collection creation failed.');
    //       throw (failure.message);
    //     }
    showModalBottomSheet(
      context: _callingBuildContext!,
      isScrollControlled: true,
      builder: (_) => Wrap(
        children: [
          CollectionsCheckoutSheet(
            scheduleEntries: scheduleEntries,
            method: method,
            details: Collection(
              maxAmount: maximumAmount,
              expiryDate: expiryDate,
              startDate: startDate,
              monthlyLimit: monthlyLimit,
              schedule: Schedule(
                frequency: frequency,
                type: type,
                entries: [],
              ),
              reference: reference,
              status: '',
              nextCollectionAt: '',
            ),
            merchantName: merchantName,
          ),
        ],
      ),
    );
  }

  Future<void> collectionHandOffToAuth({
    required Function(bool)? onKeyExchange,
  }) async {
    _updateState(MonaSDKState.loading);

    // Initialize SSE listener for real-time events
    _firebaseSSE.initialize();

    _updateState(MonaSDKState.loading);

    /// *** If the user doesn't have a keyID and they want to use a saved payment method,
    /// *** Key exchange needs to be done, so handle first.
    final doKeyExchange = await checkIfUserHasKeyID() == null;

    /// *** Payment process will be handled here on the web, if there is no checkout ID / Key Exchange done
    /// *** previously
    if (doKeyExchange) {
      await initKeyExchange(
        withRedirect: false,
        isFromCollections: true,
      );
      onKeyExchange?.call(true);
    } else {
      onKeyExchange?.call(false);
    }

    _updateState(MonaSDKState.idle);
  }

  void resetSDKState({bool clearMonaCheckout = true}) {
    _errorMessage = null;
    _currentTransactionId = null;
    _strongAuthToken = null;
    if (clearMonaCheckout) _monaCheckOut = null;
    _callingBuildContext = null;
    _state = MonaSDKState.idle;
    _selectedPaymentMethod = PaymentMethod.none;
    _pendingPaymentResponseModel = null;
    _selectedBankOption = null;
    _selectedCardOption = null;
    _transactionPIN = null;
    _transactionOTP = null;

    notifyListeners();
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
    _transactionPIN = null;
    _transactionOTP = null;

    notifyListeners();
  }
}
