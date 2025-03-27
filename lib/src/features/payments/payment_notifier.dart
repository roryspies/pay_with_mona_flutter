import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:pay_with_mona/src/core/firebase_sse_listener.dart';
import 'package:pay_with_mona/src/features/payments/payments_service.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

enum PaymentState { idle, loading, success, error }

class PaymentNotifier extends ChangeNotifier {
  PaymentState _state = PaymentState.idle;
  String? _errorMessage;
  String? _currentTransactionId;

  final PaymentService _paymentsService;
  final FirebaseSSEListener _firebaseSSE = FirebaseSSEListener();

  PaymentState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get currentTransactionId => _currentTransactionId;

  PaymentNotifier({PaymentService? paymentsService})
      : _paymentsService = paymentsService ?? PaymentService();

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
      'hiyaa'.log();
      '$success'.log();

      _setTransactionId(success['transactionId']);
      makePayment(
        transactionId: success['transactionId'],
        method: method,
        context: context,
      );
      _setState(PaymentState.success);
    }
  }

  Future<void> makePayment({
    required String? transactionId,
    required String method,
    required BuildContext context,
  }) async {
    (_currentTransactionId ?? 'isnull').log();
    (transactionId ?? 'isnull').log();
    _setState(PaymentState.loading);

    method.log();

    // final (Map<String, dynamic>? success, failure) =
    //     await _paymentsService.makePayment(
    //   transactionId: '67e481d9af46b1a1f49bd6b6',
    //   method: method,
    // );
    // if (failure != null) {
    //   _setState(PaymentState.success);
    // } else if (success != null) {
    //   '$success'.log();
    //   _setError("Payment failed. Try again.");
    // }

    // method=bank&bankId=

    String url =
        'https://pay.development.mona.ng/$transactionId?embedding=true&sdk=true&mmethod=$method';

    url.log();

    await launchUrl(
      Uri.parse(
          'https://pay.development.mona.ng/$transactionId?embedding=true&sdk=true&mmethod=$method'),
      customTabsOptions: CustomTabsOptions.partial(
        shareState: CustomTabsShareState.off,
        configuration: PartialCustomTabsConfiguration(
          initialHeight: context.screenHeight * 0.7,
          activityHeightResizeBehavior:
              CustomTabsActivityHeightResizeBehavior.adjustable,
        ),
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: MonaColors.primaryBlue,
        ),
        showTitle: false,
      ),
      safariVCOptions: SafariViewControllerOptions.pageSheet(
        configuration: const SheetPresentationControllerConfiguration(
          detents: {
            SheetPresentationControllerDetent.large,
            SheetPresentationControllerDetent.medium,
          },
          prefersScrollingExpandsWhenScrolledToEdge: true,
          prefersGrabberVisible: true,
          prefersEdgeAttachedInCompactHeight: true,
        ),
        preferredBarTintColor: MonaColors.primaryBlue,
        preferredControlTintColor: Colors.white,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
      ),
    );

    _firebaseSSE.startListening(
      transactionId: transactionId!,
      onDataChange: (event) {
        '🔥 [SSEListener] Event Received: $event'.log();
        if (event == 'transaction_completed' || event == 'transaction_failed') {
          _firebaseSSE.dispose();
          closeCustomTabs();
        }
      },
      onError: (error) {
        '❌ [SSEListener] Error: $error'.log();
      },
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
}
