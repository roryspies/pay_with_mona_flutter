// import 'package:dio/dio.dart';
// import 'package:mobile_device_identifier/mobile_device_identifier.dart';
// import 'package:pay_with_mona/src/core/api_service.dart';
// import 'package:pay_with_mona/src/core/exceptions.dart';
// import 'package:pay_with_mona/src/utils/extensions.dart';
// import 'package:pay_with_mona/src/utils/type_defs.dart';

// class AuthService {
//   final ApiService _apiService = ApiService();
//   final ApiService _apiService2 = ApiService(baseUrl: 'https://pay.mona.ng');

//   // final Future<String?> getDeviceId = MobileDeviceIdentifier().getDeviceId();

//   FutureOutcome<Map<String, dynamic>> checkForMonaUser({
//     required String phoneNumber,
//   }) async {
//     try {
//       final response = await _apiService.post(
//         "/login/$phoneNumber",
//       );

//       return right(response.data);
//     } on DioException catch (e) {
//       final errorMessage = APIException.fromDioError(e).toString();
//       "❌ checkForMonaUser() API Error: $errorMessage".log();
//       return left(Failure(errorMessage));
//     } on APIException catch (e) {
//       "❌ checkForMonaUser() API Exception: ${e.toString()}".log();
//       return left(Failure(e.toString()));
//     } catch (e) {
//       "❌ checkForMonaUser() Unexpected Error: ${e.toString()}".log();
//       return left(Failure("An unexpected error occurred: $e"));
//     }
//   }

//   FutureOutcome<Map<String, dynamic>> fetchLoginScope({
//     required String merchantId,
//     required String keyId,
//   }) async {
//     try {
//       final response = await _apiService.get(
//         "/login",
//         headers: {
//           'x-mona-login-scope': '67ebcdd1f8664035e708b057',
//           'mona_checkoutId': keyId,
//         },
//       );

//       return right(response.data);
//     } on DioException catch (e) {
//       final errorMessage = APIException.fromDioError(e).toString();
//       "❌ checkForMonaUser() API Error: $errorMessage".log();
//       return left(Failure(errorMessage));
//     } on APIException catch (e) {
//       "❌ checkForMonaUser() API Exception: ${e.toString()}".log();
//       return left(Failure(e.toString()));
//     } catch (e) {
//       "❌ checkForMonaUser() Unexpected Error: ${e.toString()}".log();
//       return left(Failure("An unexpected error occurred: $e"));
//     }
//   }

//   FutureOutcome<Map<String, dynamic>> getRegistrationOptions({
//     required String paymentUserId,
//   }) async {
//     try {
//       final response = await _apiService.get(
//         "/auth/key/registration",
//         queryParams: {
//           'paymentUserId': paymentUserId,
//         },
//       );

//       return right(response.data);
//     } on DioException catch (e) {
//       final errorMessage = APIException.fromDioError(e).toString();
//       "❌ initiatePayment() API Error: $errorMessage".log();
//       return left(Failure(errorMessage));
//     } on APIException catch (e) {
//       "❌ initiatePayment() API Exception: ${e.toString()}".log();
//       return left(Failure(e.toString()));
//     } catch (e) {
//       "❌ initiatePayment() Unexpected Error: ${e.toString()}".log();
//       return left(Failure("An unexpected error occurred: $e"));
//     }
//   }

//   FutureOutcome<Map<String, dynamic>> loadSavedOptions({
//     required String paymentUserId,
//     required String publicKey,
//   }) async {
//     try {
//       final response = await _apiService.get(
//         "/pay",
//         headers: {
//           'x-payment-user-id': paymentUserId,
//           'x-public-key': publicKey,
//         },
//       );

//       return right(response.data);
//     } on DioException catch (e) {
//       final errorMessage = APIException.fromDioError(e).toString();
//       "❌ initiatePayment() API Error: $errorMessage".log();
//       return left(Failure(errorMessage));
//     } on APIException catch (e) {
//       "❌ initiatePayment() API Exception: ${e.toString()}".log();
//       return left(Failure(e.toString()));
//     } catch (e) {
//       "❌ initiatePayment() Unexpected Error: ${e.toString()}".log();
//       return left(Failure("An unexpected error occurred: $e"));
//     }
//   }
// }
