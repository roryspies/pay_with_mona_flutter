import 'package:dio/dio.dart';
import 'package:example/core/api_service.dart';
import 'package:example/core/exceptions.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/type_defs.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  FutureOutcome<Map<String, dynamic>> initiatePayment({
    required num tnxAmountInKobo,
  }) async {
    try {
      final response = await _apiService.post(
        "/demo/checkout",
        data: {
          'amount': tnxAmountInKobo,
        },
      );

      tnxAmountInKobo.log();

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
}
