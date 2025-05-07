import 'dart:convert';
import 'package:pay_with_mona/src/core/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

/// Service to orchestrate payment‐related endpoints.
class PaymentService {
  // Singleton boilerplate
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  final ApiService _apiService = ApiService();

  /// Initiates a checkout session.
  FutureOutcome<Map<String, dynamic>> initiatePayment() async {
    try {
      final response = await _apiService.post(
        '/demo/checkout',
        data: {'amount': 5000},
      );

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ initiatePayment() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  /// Retrieves available payment methods for a transaction.
  FutureOutcome<PendingPaymentResponseModel> getPaymentMethods({
    required String transactionId,
    required String userEnrolledCheckoutID,
  }) async {
    try {
      final response = await _apiService.get(
        '/pay',
        headers: {
          'cookie': 'mona_checkoutId=$userEnrolledCheckoutID',
        },
        queryParams: {'transactionId': transactionId},
      );

      return right(
        PendingPaymentResponseModel.fromJSON(
          json: jsonDecode(response.body) as Map<String, dynamic>,
        ),
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ getPaymentMethods() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }

  /// Starts the actual payment flow (e.g. redirect to payment gateway).
  FutureOutcome<Map<String, dynamic>> makePayment({
    required String transactionId,
    required String method,
  }) async {
    try {
      // Use a custom base URL for the payment gateway
      final api = ApiService(baseUrl: 'https://pay.development.mona.ng');
      final response = await api.get(
        '/$transactionId',
        queryParams: {
          'embedding': 'true',
          'sdk': 'true',
          'embeddingUrl': 'http://localhost:4008/',
          'method': method,
          if (method == 'bank') 'bankId': '',
        },
      );

      return right(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      final apiEx = APIException.fromHttpError(e);
      '❌ makePayment() Error: ${apiEx.message}'.log();
      return left(Failure(apiEx.message));
    }
  }
}
