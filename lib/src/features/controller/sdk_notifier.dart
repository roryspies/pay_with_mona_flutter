import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/core/events/auth_state_stream.dart';
import 'package:pay_with_mona/src/core/events/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';
import 'package:pay_with_mona/src/core/events/transaction_state_stream.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/core/services/auth_service.dart';
import 'package:pay_with_mona/src/core/services/payments_service.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'dart:math' as math;
part 'sdk_notifier.helpers.dart';

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

  /// Stores the transaction ID and notifies listeners.
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
  /// *** MARK: - Init SDK & Major Methods
  Future<void> initSDK({
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

        final userHasCheckoutID = await checkIfUserHasKeyID();

        /// *** User has not done key exchange
        if (userHasCheckoutID == null) {
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
    num? tnxAmountInKobo,
  }) async {
    _updateState(MonaSDKState.loading);

    final (Map<String, dynamic>? success, failure) =
        await _paymentsService.initiatePayment(
      tnxAmountInKobo: tnxAmountInKobo ?? 2000,
    );

    if (failure != null) {
      _handleError('Payment initiation failed. Please try again.');
      throw (failure.message);
    }

    final txId = success?['transactionId'] as String?;
    if (txId == null) {
      _handleError('Invalid response from payment service.');
      return;
    }

    _handleTransactionId(txId);
    _updateState(MonaSDKState.idle);

    /// *** @ThatSaxyDev - I doubt we still need this - below, considering we're already using PII
    /// *** Kindly confirm
    //await getPaymentMethods();
  }

  Future<void> getPaymentMethods() async {
    _updateState(MonaSDKState.loading);

    final userCheckoutID = await checkIfUserHasKeyID();

    if (userCheckoutID == null) {
      _handleError('User identifier not found. Please login again.');
      return;
    }

    try {
      final (paymentDataAndMethods, failure) =
          await _paymentsService.getPaymentMethods(
        transactionId: _currentTransactionId ?? '',
        userEnrolledCheckoutID: userCheckoutID,
      );

      if (failure != null) {
        _handleError('Payment initiation failed. Please try again.');
        _updateState(MonaSDKState.idle);
        return;
      }

      setPendingPaymentData(pendingPayment: paymentDataAndMethods!);
      _updateState(MonaSDKState.success);
    } catch (error, trace) {
      _handleError('Error fetching payment methods: $error ::: $trace');
      return;
    }
  }

  /// Orchestrates the in-app payment flow with SSE and strong authentication.
  ///
  /// 1. Opens a custom tab to the payment URL.
  /// 2. Listens for transaction updates and strong auth tokens via SSE.
  Future<void> makePayment() async {
    if (_currentTransactionId == null) {
      _sdkStateStream.emit(state: MonaSDKState.idle);
      await initiatePayment();
      //throw ("No transaction amount or ID yet");
    }

    _updateState(MonaSDKState.loading);

    // Initialize SSE listener for real-time events
    _firebaseSSE.initialize();

    bool hasError = false;
    bool hasTransactionUpdateError = false;
    bool authError = false;

    // Concurrently listen for transaction completion and authentication tokens
    await Future.wait([
      _listenForPaymentUpdates(hasError),
      _listenForTransactionUpdateEvents(hasTransactionUpdateError),
    ]);

    final userHasCheckoutID = await checkIfUserHasKeyID();

    /// *** There is no saved credential, Key Exchange has not been done.
    /// *** Initiate Login and Key Exchange Process.
    if (userHasCheckoutID == null) {
      "MONA SDK ::: makePayment ::: USER HAS NOT DONE KEY EXCHANGE".log();
      return;
    }

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
          _handleError('Error listening for transaction updates.');
          "Payment Notifier ::: makePayment ::: PaymentMethod.savedBank ::: ERROR ::: $error TRACE ::: $trace"
              .log();
        }
        break;

      default:
        final sessionID = math.Random.secure().nextInt(999999999).toString();
        await _listenForAuthEvents(sessionID, authError);

        final url = _buildPaymentUrl(
          sessionID,
          _selectedPaymentMethod.type,
        );
        await _launchPaymentUrl(url);
        break;
    }
  }

  /// *** MARK: Event Listeners
  Future<void> _listenForPaymentUpdates(bool errorFlag) async {
    await _firebaseSSE.listenForPaymentUpdates(
      transactionId: _currentTransactionId ?? '',
      onDataChange: (event) {
        "PAYMENT UPDATE EVENT $event".log();
      },
      onError: (error) {
        _handleError('Error listening for transaction updates.');
        errorFlag = true;
      },
    );
  }

  Future<void> _listenForTransactionUpdateEvents(bool errorFlag) async {
    await _firebaseSSE.listenForTransactionMessages(
      transactionId: _currentTransactionId ?? "",
      onDataChange: (event) async {
        "_listenForTransactionUpdateEvents ::: EVENT $event".log();
        final eventData = jsonDecode(event) as Map<String, dynamic>;
        final theEvent = eventData["event"];

        if (theEvent == "transaction_initiated") {
          "🥰 _listenForTransactionUpdateEvents ::: transaction_initiated"
              .log();
          _txnStateStream.emit(state: TransactionState.initiated);
        }

        if (theEvent == "transaction_failed") {
          "😭 _listenForTransactionUpdateEvents ::: transaction_initiated"
              .log();
          _txnStateStream.emit(state: TransactionState.failed);
        }

        if (theEvent == "transaction_completed") {
          "✅ _listenForTransactionUpdateEvents ::: transaction_initiated".log();
          _txnStateStream.emit(state: TransactionState.completed);
        }
      },
      onError: (error) {
        _handleError('Error during strong authentication.');
        errorFlag = true;
      },
    );
  }

  Future<void> _listenForAuthEvents(String sessionId, bool errorFlag) async {
    await _firebaseSSE.listenToAuthNEvents(
      sessionID: sessionId,
      onDataChange: (event) async {
        if (event.contains("strongAuthToken")) {
          _strongAuthToken =
              (jsonDecode(event) as Map<String, dynamic>)["strongAuthToken"];

          _authStream.emit(state: AuthState.performingLogin);
        }

        await closeCustomTabs();
        await loginWithStrongAuth();
      },
      onError: (error) {
        _handleError('Error during strong authentication.');
        errorFlag = true;
      },
    );
  }

  ///
  /// *** MARK: Custom Tabs and URL's
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
    _updateState(MonaSDKState.loading);
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

          _updateState(MonaSDKState.success);
          _authStream.emit(state: AuthState.loggedIn);
        },
      );
    } catch (e) {
      _handleError('Unexpected error during authentication.');
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
