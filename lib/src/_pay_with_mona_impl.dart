part of "pay_with_mona.dart";

class _MonaSDKImpl extends PayWithMona {
  _MonaSDKImpl._();

  static Future<_MonaSDKImpl> initialize(
      {required String merchantKey,
      required GlobalKey<NavigatorState> hostAppNavKey}) async {
    await MonaSDKNotifier().initSDK(
      merchantKey: merchantKey,
      hostAppNavKey: hostAppNavKey,
    );

    return _MonaSDKImpl._();
  }

  @override
  Widget payWidget({
    required BuildContext context,
  }) {
    return PayWithMonaWidget(
      callingContext: context,
    );
  }

  @override
  Future<void> showDataShareSheet({
    required BuildContext context,
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime dateOfBirth,
    required String transactionId,
    required String merchantName,
    required Color primaryColor,
    required Color secondaryColor,
    required String phoneNumber,
    String? bvn,
  }) async {
    final widget = DataShareSheet();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Wrap(
        children: [
          widget,
        ],
      ),
    );
  }
}
