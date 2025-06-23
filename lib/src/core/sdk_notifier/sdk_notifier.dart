// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/events/auth_state_stream.dart';
import 'package:pay_with_mona/src/core/events/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/core/events/host_lifecycle_observer.dart';
import 'package:pay_with_mona/src/core/events/models/transaction_task_model.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';
import 'package:pay_with_mona/src/core/events/transaction_state_classes.dart';
import 'package:pay_with_mona/src/core/events/transaction_state_stream.dart';
import 'package:pay_with_mona/src/core/security/payment_encryption/payment_encryption_service.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/mona_sdk_merchant_key_cache.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage.dart';
import 'package:pay_with_mona/src/core/security/secure_storage/secure_storage_keys.dart';
import 'package:pay_with_mona/src/core/services/collections_services.dart';
import 'package:pay_with_mona/src/core/services/crash_monitoring_service.dart';
import 'package:pay_with_mona/src/features/collections/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/collections/widgets/collections_checkout_sheet.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/notifier_enums.dart';
import 'package:pay_with_mona/src/core/services/auth_service.dart';
import 'package:pay_with_mona/src/core/services/payments_service.dart';
import 'package:pay_with_mona/src/models/collection_response.dart';
import 'package:pay_with_mona/src/models/merchant_branding.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';
import 'package:pay_with_mona/src/widgets/confirm_transaction_modal.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'dart:math' as math;

import 'package:pay_with_mona/src/widgets/confirm_key_exchange_modal.dart';
import 'package:pay_with_mona/ui/widgets/otp_or_pin_modal_content.dart';
import 'dart:ui' as dart_app_life_cycle show AppLifecycleState;
part 'sdk_notifier.helpers.dart';
part 'sdk_notifier.listeners.dart';
part 'sdk_notifier.collections.dart';

/// Manages the entire payment workflow, from initiation to completion,
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
    CollectionsService? collectionsService,
  }) {
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

  final _merchantKeyCache = MonaSdkMerchantKeyCache();

  /// Listener for Firebase Server-Sent Events.
  final _firebaseSSE = FirebaseSSEListener();

  late GlobalKey<NavigatorState> _hostAppNavigatorKey;
  GlobalKey<NavigatorState> get hostAppNavKey => _hostAppNavigatorKey;

  String? _errorMessage;
  String? _currentTransactionId;
  String? _currentTransactionFriendlyID;
  String? _strongAuthToken;
  String? _transactionOTP;
  String? _transactionPIN;
  bool showCancelButton = true;
  bool changeSDKStateOnHostAppInForeground = true;
  bool paymentWithPossibleKeyExchange = false;
  String? _cachedMerchantKey;
  MerchantBranding? _merchantBrandingDetails;
  MerchantPaymentSettingsEnum _merchantPaymentSettingsEnum =
      MerchantPaymentSettingsEnum.walletReceiveComplete;
  MonaCheckOut? _monaCheckOut;
  BuildContext get callingContext => _hostAppNavigatorKey.currentState!.context;

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

  MonaCheckOut? get monaCheckout => _monaCheckOut;

  PendingPaymentResponseModel? get currentPaymentResponseModel =>
      _pendingPaymentResponseModel;

  BankOption? get selectedBankOption => _selectedBankOption;

  CardOption? get selectedCardOption => _selectedCardOption;
  MerchantBranding? get merchantBrandingDetails => _merchantBrandingDetails;
  MerchantPaymentSettingsEnum? get currentMerchantPaymentSettingsEnum =>
      _merchantPaymentSettingsEnum;

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

  ///
  /// Retains the [BuildContext] to calculate UI-dependent dimensions...
  /// and pull up UI modals where necessary
  void setHostAppNavigatorKey({
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _hostAppNavigatorKey = navigatorKey;
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

    final banks = _pendingPaymentResponseModel?.savedPaymentOptions?.bank;
    final banksHaveData = banks != null && banks.isNotEmpty;

    if (banksHaveData) {
      setSelectedPaymentMethod(method: PaymentMethod.savedBank);
      if (_selectedBankOption != null) {
        notifyListeners();
        return;
      }

      _selectedBankOption ??= banks.firstWhere(
        (bank) => bank.isPrimary == true && bank.activeIn == null,
        orElse: () => banks.firstWhere(
          (bank) => bank.isPrimary == false,
          orElse: () => banks.first,
        ),
      );
    }
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

  void resetPinAndOTP() {
    _transactionPIN = null;
    _transactionOTP = null;
    notifyListeners();
  }

  void handleNavToConfirmationScreen() {
    _txnStateStream.emit(
      state: TransactionStateNavToResult(
        transactionID: _currentTransactionId,
        friendlyID: _currentTransactionFriendlyID,
        amount: _monaCheckOut?.amount,
      ),
    );
    notifyListeners();
  }

  void setShowCancelButton({
    required bool showCancelButton,
  }) {
    this.showCancelButton = showCancelButton;
    notifyListeners();
  }

  void setPaymentWithPossibleKeyExchange({
    required bool paymentWithPossibleKeyExchange,
  }) {
    this.paymentWithPossibleKeyExchange = paymentWithPossibleKeyExchange;
    notifyListeners();
  }

  void resetPaymentWithPossibleKeyExchange() {
    paymentWithPossibleKeyExchange = false;
  }

  // Enhanced method with better error handling and type safety
  Future<void> updateMerchantPaymentSettingsWidget({
    required String currentSettingsPaymentName,
    required Function(bool isSuccessful) onEvent,
  }) async {
    MerchantPaymentSettingsEnum? oldValue;

    try {
      _sdkStateStream.emit(state: MonaSDKState.loading);

      // Store old value for rollback
      oldValue = _merchantPaymentSettingsEnum;

      // Validate and convert string to enum
      final newSetting =
          MerchantPaymentSettingsEnum.fromString(currentSettingsPaymentName);
      if (newSetting == null) {
        throw ArgumentError(
            'Invalid payment setting: $currentSettingsPaymentName');
      }

      _merchantPaymentSettingsEnum = newSetting;
      notifyListeners();

      // Initiate payment
      final response = await _authService.updateMerchantPaymentSettings(
        merchantAPIKey: await _merchantKeyCache.getValue(
          SecureStorageKeys.merchantAPIKey,
        ),
        successRateType: _merchantPaymentSettingsEnum.paymentName,
      );

      // Handle payment response
      if (response == null) {
        throw Exception("Could not update merchant settings");
      }

      // Success case
      onEvent(true);

      _sdkStateStream.emit(state: MonaSDKState.idle);
    } catch (error, stackTrace) {
      // Log error with more context
      final errorMessage = 'updateMerchantPaymentSettingsWidget failed: $error';
      errorMessage.log();

      // Log stack trace for debugging
      'Stack trace: $stackTrace'.log();

      // Rollback state if we have an old value
      if (oldValue != null) {
        _merchantPaymentSettingsEnum = oldValue;
        notifyListeners();
      }

      // Notify caller of failure
      onEvent(false);

      // Handle error through your error handling system
      _handleError(error.toString());

      // Always ensure we're not stuck in loading state
      _sdkStateStream.emit(state: MonaSDKState.idle);
    }
  }

  Future<void> _setMerchantKey({required String merchantKey}) async {
    await _merchantKeyCache.save({
      SecureStorageKeys.merchantKey: merchantKey,
    });
  }

  Future<String?> _getMerchantKey() async {
    return await _merchantKeyCache.getValue(
      SecureStorageKeys.merchantKey,
    );
  }

  Future<void> setMerchantAPIKey({
    required String merchantAPIKey,
  }) async {
    await _merchantKeyCache.save({
      SecureStorageKeys.merchantAPIKey: merchantAPIKey,
    });
  }

  Future<String?> getMerchantAPIKey() async {
    return await _merchantKeyCache.getValue(
      SecureStorageKeys.merchantAPIKey,
    );
  }

  Future<void> _setMerchantBranding({
    required MerchantBranding merchant,
  }) async {
    final jsonString = jsonEncode(merchant.toJson());
    await _secureStorage.write(
      key: SecureStorageKeys.merchantBranding,
      value: jsonString,
    );
  }

  Future<MerchantBranding?> _getMerchantBranding() async {
    final encodedString = await _secureStorage.read(
      key: SecureStorageKeys.merchantBranding,
    );

    if (encodedString == null) {
      return null;
    }

    return MerchantBranding.fromJSON(json: jsonDecode(encodedString));
  }

  Future<void> initSDK({
    required String merchantKey,
    required GlobalKey<NavigatorState> hostAppNavKey,
  }) async {
    bool succeeded = false;

    // Initialize crash monitoring first
    await CrashMonitoringService.instance.initialize();

    try {
      if (_cachedMerchantKey == merchantKey &&
          _merchantBrandingDetails != null) {
        succeeded = true;
      } else {
        final storedKey = _cachedMerchantKey ?? await _getMerchantKey();

        if (storedKey == merchantKey) {
          _merchantBrandingDetails ??= await _getMerchantBranding();
          succeeded = true;
        } else {
          _cachedMerchantKey = merchantKey;
          await _setMerchantKey(merchantKey: merchantKey);

          final branding =
              await _authService.initMerchant(merchantKey: merchantKey);

          if (branding != null) {
            _merchantBrandingDetails = branding;
            unawaited(_setMerchantBranding(merchant: branding));
            succeeded = true;
          } else {
            _handleError("Failed to initialize SDK");
          }
        }

        if (succeeded) notifyListeners();

        setHostAppNavigatorKey(
          navigatorKey: hostAppNavKey,
        );

        initSDKHostAppLifeCycleListener();
      }
    } catch (e, st) {
      _handleError("Init SDK error $e ::: Stack Trace $st");
    }

    if (succeeded && _merchantBrandingDetails != null) {
      MonaColors.setBranding(
        merchantBrandingColours: _merchantBrandingDetails!.colors,
      );
    }
  }

  Future<void> initSDKHostAppLifeCycleListener() async {
    AppLifecycleMonitor(
      onStateChanged: (state) async {
        /// *** Here, it is assumed, that the only reason the app has come back to foreground is because custom tabs was open and now it has closed.
        /// *** To check if the custom tabs was closed
        if (state == dart_app_life_cycle.AppLifecycleState.resumed) {
          "HOST App is in foreground".log();
          if (paymentWithPossibleKeyExchange) {
            _updateState(MonaSDKState.loading);
            return;
          }

          //_updateState(MonaSDKState.idle);
        } else {
          "HOST App is in background".log();
        }
      },
    );
  }

  Future<void> sdkCloseCustomTabs() async {
    await closeCustomTabs();
  }

  Future<String?> checkIfUserHasKeyID() async => await _secureStorage.read(
        key: SecureStorageKeys.keyID,
      );

  Future<void> confirmLoggedInUser() async {
    final isLoggedIn = await _secureStorage.read(
      key: SecureStorageKeys.keyID,
    );

    if (isLoggedIn != null) {
      _authStream.emit(state: AuthState.loggedIn);
      return;
    } else {
      _authStream.emit(state: AuthState.loggedOut);
    }
  }

  Future<void> validatePII({
    required String userKeyID,
    bool isFromBankCollectionsView = false,
    void Function(String)? onEffect,
  }) async {
    _updateState(MonaSDKState.loading);

    final response = await _authService.validatePII(
      userKeyID: userKeyID,
    );

    if (response == null) {
      onEffect?.call("Failed to validate user PII - Experienced an Error");
      return;
    }

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

    if (isFromBankCollectionsView) {
      _updateState(MonaSDKState.idle);
    }
  }

  ///
  /// *** MARK: -  Major Methods
  /// Starts the payment initiation process.
  ///
  /// 1. Updates state to [MonaSDKState.loading].
  /// 2. Calls [_paymentsService.initiatePayment].
  /// 3. Handles failure or missing transaction ID.
  /// 4. Persists user UUID from secure storage.
  /// 5. Retrieves available payment methods.
  Future<void> initiatePayment({
    required num tnxAmountInKobo,
    required Function(String error) onError,
    required VoidCallback onSuccess,
  }) async {
    _updateState(MonaSDKState.loading);

    final userKeyID = await checkIfUserHasKeyID();

    try {
      if (userKeyID != null && userKeyID.isNotEmpty) {
        await validatePII(
          userKeyID: userKeyID,
        );
      }

      final firstName = _monaCheckOut?.firstName;
      final lastName = _monaCheckOut?.lastName;

      final nameIsNotEmpty = (firstName != null && firstName.isNotEmpty) &&
          (lastName != null && lastName.isNotEmpty);

      final (Map<String, dynamic>? success, failure) =
          await _paymentsService.initiatePayment(
        merchantKey: await _getMerchantKey() ?? "",
        merchantAPIKey: await getMerchantAPIKey() ?? "",
        tnxAmountInKobo: tnxAmountInKobo,

        /// *** Optional Params
        userKeyID: await checkIfUserHasKeyID() ?? "",
        phoneNumber: _monaCheckOut?.phoneNumber,
        bvn: _monaCheckOut?.bvn,
        dob: _monaCheckOut?.dateOfBirth?.toLocal().toIso8601String(),
        firstAndLastName: nameIsNotEmpty
            ? "${_monaCheckOut?.firstName} ${_monaCheckOut?.lastName}"
            : null,
      );

      if (failure != null) {
        _handleError("Payment initiation failed. Please try again.");
        onError(failure.message);
        return;
      }

      final txId = success?["transactionId"] as String?;
      final friendlyID = success?["friendlyID"] as String?;
      if (txId == null || friendlyID == null) {
        _handleError("Invalid response from payment service.");
        onError("Invalid response from payment service.");
        return;
      }

      _handleTransactionId(
        txId,
        friendlyID: friendlyID,
      );

      final paymentMethodsExist = success?["savedPaymentOptions"] != null &&
          (success!["savedPaymentOptions"] as Map<String, dynamic>).isNotEmpty;

      if (paymentMethodsExist) {
        setPendingPaymentData(
          pendingPayment: PendingPaymentResponseModel(
            savedPaymentOptions: SavedPaymentOptions.fromJSON(
              json: success["savedPaymentOptions"],
            ),
          ),
        );
      }
      onSuccess();
      _updateState(MonaSDKState.idle);
      return;
    } catch (error) {
      _updateState(MonaSDKState.idle);
      _handleError(error.toString());
      if (error is Failure) {
        onError(error.message);
      }
      "MonaSDKNotifier ::: initiatePayment ::: ERROR ::: ${error.toString()}"
          .log();
      return;
    }
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
      await _listenForAuthEvents(
        sessionID,
        authCompleter,
        isFromCollections: isFromCollections,
      );

      final url = await _buildURL(
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

    if ((_monaCheckOut?.amount ?? 0) / 100 < 20) {
      _handleError("Transaction amount cannot be less than 20");
      return;
    }

    /// *** This is only for DEMO.
    /// *** Real world scenario, client would attach a transaction ID to this.
    /// *** For now - Check if we have an initiated Transaction ID else do a demo one
    if (_currentTransactionId == null) {
      await initiatePayment(
        tnxAmountInKobo: _monaCheckOut!.amount!,
        onError: (error) {},
        onSuccess: () {},
      );
    }

    _updateState(MonaSDKState.loading);

    /// *** Concurrently listen for transaction completion.
    try {
      await Future.wait(
        [
          //_listenForPaymentUpdates(),
          _listenForTransactionUpdateEvents(),
          _listenForCustomTabEvents()
        ],
      );
    } catch (error) {
      "MonaSDKNotifier ::: makePayment ::: ```Concurrently listen for transaction completion.``` ::: Error ::: $error"
          .log();
      _handleError("Error during payment process: $error");
      return;
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
      await initKeyExchange();

      await Future.delayed(Duration(milliseconds: 500));

      _updateState(MonaSDKState.idle);

      await SDKUtils.showSDKModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        callingContext: callingContext,
        child: ConfirmTransactionModal(
          selectedPaymentMethod: _selectedPaymentMethod,
          transactionAmountInKobo: _monaCheckOut!.amount!,
          onPay: () async {
            await makePayment();
          },
        ),
      );
      return;
    }

    switch (_selectedPaymentMethod) {
      case PaymentMethod.savedBank || PaymentMethod.savedCard:
        try {
          // _updateState(MonaSDKState.loading);
          await _paymentsService.makePaymentRequest(
            paymentType: _selectedPaymentMethod == PaymentMethod.savedBank
                ? null
                : TransactionPaymentTypes.card,
            onPayComplete: (res, payload) async {
              "Payment Notifier ::: Make Payment Request Complete".log();
              _currentTransactionFriendlyID = res["friendlyID"];
              _txnStateStream.emit(
                state: TransactionStateInitiated(
                  transactionID: res["transactionRef"],
                  friendlyID: _currentTransactionFriendlyID,
                  amount: _monaCheckOut?.amount,
                ),
              );

              /* if (doKeyExchange) {
                await SDKUtils.showSDKModalBottomSheet(
                  isDismissible: false,
                  enableDrag: false,
                  callingContext: callingContext,
                  child: ConfirmTransactionModal(
                    showTransactionStatusIndicator: true,
                    selectedPaymentMethod: _selectedPaymentMethod,
                    transactionAmountInKobo: _monaCheckOut!.amount!,
                  ),
                );
              } */
            },
          );
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

    _updateState(MonaSDKState.idle);
  }

  Future<void> handleRegularPayment() async {
    final sessionID = _generateSessionID();
    final authCompleter = Completer<void>();
    await _listenForAuthEvents(sessionID, authCompleter);

    final url = await _buildURL(
      doDirectPayment: await checkIfUserHasKeyID() != null,
      doDirectPaymentWithPossibleAuth: await checkIfUserHasKeyID() == null,
      sessionID: sessionID,
      method: _selectedPaymentMethod,
      bankOrCardId: _selectedPaymentMethod == PaymentMethod.savedBank
          ? _selectedBankOption?.bankId
          : _selectedCardOption?.bankId,
    );

    if (url.toString().contains("sessionId")) {
      setPaymentWithPossibleKeyExchange(
        paymentWithPossibleKeyExchange: true,
      );
    }

    await _launchURL(url);
  }

  ///
  /// *** Performs strong authentication using the received SSE token.
  ///
  /// Updates payment methods upon success.
  Future<void> loginWithStrongAuth({
    bool isFromCollections = false,
  }) async {
    final canEnrollKeysCompleter = Completer<bool>();
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

      SDKUtils.showSDKModalBottomSheet(
        callingContext: callingContext,
        onCancelButtonTap: () {
          if (canEnrollKeysCompleter.isCompleted == false) {
            "ConfirmKeyExchangeModal ::: User Decision: false".log();
            canEnrollKeysCompleter.complete(false);
          }
        },
        child: ConfirmKeyExchangeModal(
          onUserDecision: (bool canEnrolKeys) {
            if (canEnrollKeysCompleter.isCompleted == false) {
              "ConfirmKeyExchangeModal ::: User Decision: $canEnrolKeys".log();
              canEnrollKeysCompleter.complete(canEnrolKeys);
            }
          },
        ),
      );

      final canEnrollKeys = await canEnrollKeysCompleter.future;

      if (canEnrollKeys) {
        _updateState(MonaSDKState.loading);

        "USER ALLOWED TO ENROLL KEYS".log();
        return await _authService.signAndCommitAuthKeys(
          deviceAuth: response["deviceAuth"],
          onSuccess: () async {
            final userCheckoutID = await _secureStorage.read(
              key: SecureStorageKeys.monaCheckoutID,
            );

            if (userCheckoutID == null) {
              _handleError("User identifier missing.");
              return;
            }

            /// *** Close the Modal
            Navigator.of(callingContext).pop();

            _authStream.emit(state: AuthState.loggedIn);

            //_updateState(MonaSDKState.success);
            /* await validatePII(); */

            /* if (!isFromCollections) {
              if (_callingBuildContext != null) {
                Navigator.of(_callingBuildContext!).pop();
              }
              await SDKUtils.showSDKModalBottomSheet(
                isDismissible: false,
                enableDrag: false,
                callingContext: _callingBuildContext!,
                child: ConfirmTransactionModal(
                  selectedPaymentMethod: selectedPaymentMethod,
                  transactionAmountInKobo: _monaCheckOut?.amount ?? 0,
                ),
              );
            } */

            /// *** Close Modal

            //resetSDKState(clearMonaCheckout: false);
          },
        );
      }

      "USER DECLINED TO ENROLL KEYS".log();

      /// *** Close Modal
      Navigator.of(callingContext).pop();
      _authStream.emit(state: AuthState.loggedOut);
      _updateState(MonaSDKState.idle);
      ScaffoldMessenger.of(callingContext).showSnackBar(
        const SnackBar(
          content: Text('Enrollment Declined'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _handleError("Unexpected error during authentication.");
    }
  }

  void addBankAccountForCollections({required String collectionId}) async {
    _updateState(MonaSDKState.loading);

    final url =
        'https://pay.development.mona.ng/collections/enrollment?collectionId=$collectionId';
    await _launchURL(url);
  }

  Future<void> addBankAccountForCheckout() async {
    _updateState(MonaSDKState.loading);

    final url =
        'https://pay.development.mona.ng/checkout/enrollment?transactionId=$_currentTransactionId';

    await _launchURL(url);
  }

  void updateSdkStateToIdle() {
    _updateState(MonaSDKState.idle);
  }

  Future<void> resetSDKState({
    bool clearMonaCheckout = true,
    bool clearPendingPaymentResponseModel = true,
  }) async {
    _errorMessage = null;
    _currentTransactionId = null;
    _strongAuthToken = null;
    if (clearMonaCheckout) _monaCheckOut = null;
    _state = MonaSDKState.idle;
    _selectedPaymentMethod = PaymentMethod.none;
    if (clearPendingPaymentResponseModel) _pendingPaymentResponseModel = null;
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
    _state = MonaSDKState.idle;
    _selectedPaymentMethod = PaymentMethod.none;
    _pendingPaymentResponseModel = null;
    _selectedBankOption = null;
    _selectedCardOption = null;
    _transactionPIN = null;
    _transactionOTP = null;

    notifyListeners();
  }

  Future<void> permanentlyClearKeys() async {
    await AuthService.singleInstance.permanentlyClearKeys();
    _authStream.emit(state: AuthState.loggedOut);
  }
}
