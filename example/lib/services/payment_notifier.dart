import 'package:example/services/payments_service.dart';
import 'package:example/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PaymentState { idle, loading, success, error }

class PaymentNotifier extends ChangeNotifier {
  PaymentState _state = PaymentState.idle;
  String? _errorMessage;
  String? _currentTransactionId;

  final PaymentService _paymentsService;

  PaymentState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get currentTransactionId => _currentTransactionId;

  PaymentNotifier({PaymentService? paymentsService})
      : _paymentsService = paymentsService ?? PaymentService();

  Future<String> initiatePayment({
    required num tnxAmountInKobo,
  }) async {
    setState(PaymentState.loading);

    final (Map<String, dynamic>? success, failure) = await _paymentsService
        .initiatePayment(tnxAmountInKobo: tnxAmountInKobo);
    if (failure != null) {
      _setError("Payment failed. Try again.");
      return '';
    } else if (success != null) {
      'hiyaa'.log();
      '$success'.log();

      _setTransactionId(success['transactionId']);

      setState(PaymentState.success);

      return success['transactionId'];
    }

    return '';
  }

  void setState(PaymentState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    setState(PaymentState.error);
  }

  void _setTransactionId(String transactionId) {
    _currentTransactionId = transactionId;
    // MonaSDKNotifier monaSDKNotifier = MonaSDKNotifier();

    // monaSDKNotifier.handleTransactionId(transactionId);
    notifyListeners();
  }
}
