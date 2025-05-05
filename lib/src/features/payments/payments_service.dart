import 'package:dio/dio.dart';
import 'package:pay_with_mona/src/core/api_service.dart';
import 'package:pay_with_mona/src/core/exceptions.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/type_defs.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  FutureOutcome<Map<String, dynamic>> initiatePayment() async {
    try {
      final response = await _apiService.post(
        "/demo/checkout",
        data: {'amount': 3000},
      );

      return right(response.data);
    } on DioException catch (e) {
      final errorMessage = APIException.fromDioError(e).toString();
      "❌ initiatePayment() API Error: $errorMessage".log();
      return left(Failure(errorMessage));
    } on APIException catch (e) {
      "❌ initiatePayment() API Exception: ${e.toString()}".log();
      return left(Failure(e.toString()));
    } catch (e) {
      "❌ initiatePayment() Unexpected Error: ${e.toString()}".log();
      return left(Failure("An unexpected error occurred: $e"));
    }
  }

  FutureOutcome<Map<String, dynamic>> getPaymentMethods({
    required String transactionId,
  }) async {
    try {
      // final apiService = ApiService(baseUrl: 'https://api.development.mona.ng');
      final response = await _apiService.get("/pay", queryParams: {
        'transactionId': transactionId,
      });

      return right(response.data);
    } on DioException catch (e) {
      final errorMessage = APIException.fromDioError(e).toString();
      "❌ getPaymentMethods() API Error: $errorMessage".log();
      return left(Failure(errorMessage));
    } on APIException catch (e) {
      "❌ getPaymentMethods() API Exception: ${e.toString()}".log();
      return left(Failure(e.toString()));
    } catch (e) {
      "❌ getPaymentMethods() Unexpected Error: ${e.toString()}".log();
      return left(Failure("An unexpected error occurred: $e"));
    }
  }

  FutureOutcome<Map<String, dynamic>> makePayment({
    required String transactionId,
    required String method,
  }) async {
    try {
      final apiService = ApiService(baseUrl: 'https://pay.development.mona.ng');
      final response = await apiService.get("/$transactionId", queryParams: {
        'embedding': 'true',
        'sdk': 'true',
        'embeddingUrl': 'http://localhost:4008/',
        'method': method,
        if (method == 'bank') 'bankId': '',
        // ignore: equal_keys_in_map
        'sdk': 'true',
      });

      return right(response.data);
    } on DioException catch (e) {
      final errorMessage = APIException.fromDioError(e).toString();
      "❌ makePayment() API Error: $errorMessage".log();
      return left(Failure(errorMessage));
    } on APIException catch (e) {
      "❌ makePayment() API Exception: ${e.toString()}".log();
      return left(Failure(e.toString()));
    } catch (e) {
      "❌ makePayment() Unexpected Error: ${e.toString()}".log();
      return left(Failure("An unexpected error occurred: $e"));
    }
  }
}
