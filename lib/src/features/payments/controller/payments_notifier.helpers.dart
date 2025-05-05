part of 'payment_notifier.dart';

extension PaymentNotifierHelpers on PaymentNotifier {
  Future<PaymentUserType?> validatePhoneNumberAsMonaUser({
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
      final isMonaUser = responseInMap["success"] as bool? ?? false;

      "Is Mona User: $isMonaUser".log();
      if (!isMonaUser) {
        return PaymentUserType.nonMonaUser;
      }

      return PaymentUserType.monaUser;
    } catch (error) {
      "$error".log();
      if (error.toString().toLowerCase().contains("404")) {
        return PaymentUserType.nonMonaUser;
      }

      _setError("An error occurred. Please try again.");
      return null;
    } finally {
      _setState(PaymentState.idle);
    }
  }
}
