part of 'payment_notifier.dart';

extension PaymentNotifierHelpers on PaymentNotifier {
  Future<bool> validatePhoneNumberAsMonaUser({
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post(
        "/login/validate",
        headers: {
          "Content-Type": "application/json",
        },
        data: {
          'phoneNumber': phoneNumber,
        },
      );

      final responseInMap = response.data as Map<String, dynamic>;
      return responseInMap["success"] as bool;
    } catch (error) {
      "$error".log();
      _setError("An error occurred. Please try again.");
      return false;
    } finally {
      _setState(PaymentState.idle);
    }
  }
}
