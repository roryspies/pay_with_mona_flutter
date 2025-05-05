import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/core/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/core/secure_storage.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/core/auth_service.dart';
import 'package:pay_with_mona/src/core/payments_service.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'dart:math' as math;

class PaymentNotifier extends ChangeNotifier {
  static final _instance = PaymentNotifier._internal();
  factory PaymentNotifier() => _instance;
  PaymentNotifier._internal({
    PaymentService? paymentsService,
    AuthService? authService,
    SecureStorage? secureStorage,
  })  : _paymentsService = paymentsService ?? PaymentService(),
        _authService = authService ?? AuthService(),
        _secureStorage = secureStorage ?? SecureStorage();

  final PaymentService _paymentsService;
  final AuthService _authService;
  String? _errorMessage;
  String? _currentTransactionId;
  String? _strongAuthToken;
  String? _registrationToken;
  MonaCheckOut? _monaCheckOut;
  BuildContext? _callingBuildContext;
  SecureStorage _secureStorage;
  PaymentState _state = PaymentState.idle;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;
  final _firebaseSSE = FirebaseSSEListener();

  /// ***
  PaymentState get state => _state;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  String? get errorMessage => _errorMessage;
  String? get currentTransactionId => _currentTransactionId;

  /// ***
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

  void setRegistrationToken({
    required String regToken,
  }) {
    _registrationToken = (() {
      _strongAuthToken = null;
      return regToken;
    })();

    notifyListeners();
  }

  /// ***
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
            _strongAuthToken = (() {
              _strongAuthToken = null;
              return strongAuthToken;
            })();

            await closeCustomTabs();
            await loginWithStrongAuth();
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

  Future<void> loginWithStrongAuth() async {
    _setState(PaymentState.loading);

    try {
      final response = await _authService.loginWithStrongAuth(
        strongAuthToken: _strongAuthToken ?? "",
        phoneNumber: _monaCheckOut?.phoneNumber ?? "",
      );

      if (response == null) {
        _setError("Login failed. Try again.");
        return;
      }

      "✅ Strong Auth login successful: $response".log();
      await _authService.signAndCommitAuthKeys(
        deviceAuth: response["deviceAuth"],
        onSuccess: () {},
      );
    } catch (error, trace) {
      "❌ loginWithStrongAuth() Error: $error ::: Trace - $trace".log();
      _setError("An error occurred. Please try again.");
    } finally {
      "Login with Strong Auth completed".log();
    }
  }

  Future<void> enrollPassKeys() async {}

  /* Future<void> enrolPasskey2({
    required BuildContext context,
    required WidgetRef ref,
    PageController? setupPageController,
    Function()? onEnrol,
    Function()? onError,
  }) async {
    ref.read(loadingProvider.notifier).start("Please wait....");

    FlutterSecureStorage storage = const FlutterSecureStorage();

    try {
      var onboarding = ref.watch(onboardingProvider);
      String registrationToken = onboarding.registrationToken;
      var registrationOptions = onboarding.registrationOptions;

      Prefs.setString(Prefs.xClientType, 'fidoApp');

      // Initialize Pusher
      var pusher = await PusherUtil.init();
      bool registrationSuccess = false;

      await pusher.subscribe(
        channelName: 'authn_$registrationToken',
        onEvent: (pusherEvent) async {
          try {
            PusherEvent event = pusherEvent as PusherEvent;
            log('event::: $event');

            if (event.eventName == 'pusher:subscription_succeeded') {
              ref.read(loadingProvider.notifier).stop();

              Map options = {
                'registrationToken': registrationToken,
                'registrationOptions': registrationOptions
              };
              String url =
                  '${ref.read(serverEnvironmentToggleProvider).currentEnvironment.payUrl}/register?passkey=${Uri.encodeQueryComponent(jsonEncode(options))}';
              /* String url =
                  '${ENV.payUrl}/register?passkey=${Uri.encodeQueryComponent(jsonEncode(options))}'; */

              final theme = Theme.of(context);
              try {
                await launchUrl(
                  Uri.parse(url),
                  customTabsOptions: CustomTabsOptions.partial(
                    configuration: PartialCustomTabsConfiguration(
                      initialHeight: 20.h,
                      activityHeightResizeBehavior:
                          CustomTabsActivityHeightResizeBehavior.fixed,
                    ),
                    colorSchemes: CustomTabsColorSchemes.defaults(
                      toolbarColor: theme.colorScheme.surface,
                    ),
                    showTitle: true,
                  ),
                  safariVCOptions: SafariViewControllerOptions.pageSheet(
                    configuration:
                        const SheetPresentationControllerConfiguration(
                      detents: {
                        SheetPresentationControllerDetent.large,
                        SheetPresentationControllerDetent.medium,
                      },
                      prefersScrollingExpandsWhenScrolledToEdge: true,
                      prefersGrabberVisible: true,
                      prefersEdgeAttachedInCompactHeight: true,
                    ),
                    preferredBarTintColor: theme.colorScheme.surface,
                    preferredControlTintColor: theme.colorScheme.onSurface,
                    dismissButtonStyle:
                        SafariViewControllerDismissButtonStyle.close,
                  ),
                );

                Future.delayed(const Duration(seconds: 2), () async {
                  onError?.call();
                });
              } catch (e) {
                debugPrint("Launch URL failed: ${e.toString()}");
                onError?.call();
              }
            }

            if (event.eventName == 'registration_success') {
              registrationSuccess = true;
              ref.read(loadingProvider.notifier).stop();
              onEnrol?.call();
              await closeCustomTabs();

              Map<String, dynamic> eventData = jsonDecode(event.data);
              String strongAuthToken = eventData['strongAuthToken'];

              pusher.disconnect();

              String? phone = await storage.read(
                key: Prefs.PHONE,
                iOptions: AppUtil.getIOSOptions(),
                aOptions: AppUtil.getAndroidOptions(),
              );

              await doLoginExistingNN(
                context: context,
                ref: ref,
                strongAuthToken: strongAuthToken,
                setupPageController: setupPageController,
                payload: {
                  'phone': phone,
                },
              );
            }
          } catch (e) {
            debugPrint("Error in Pusher event handler: ${e.toString()}");
            onError?.call();
          }
        },
      );

      await pusher.connect();
    } catch (e) {
      debugPrint("Error in enrolPasskey2: ${e.toString()}");
      onError?.call();
      ref.read(loadingProvider.notifier).stop();
    }
  } */

  /* Future<void> openLoginCustomTab() async {
    try {
      final loginUrl = Uri(
        scheme: 'https',
        host: 'api.development.mona.ng',
        path: '/login',
        queryParameters: {
          'x-strong-auth-token': _strongAuthToken,
          'x-mona-key-exchange': "true",
        },
      );

      await launchUrl(
        loginUrl,
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
  } */
}
