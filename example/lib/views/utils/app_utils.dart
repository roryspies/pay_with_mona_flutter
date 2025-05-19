import 'package:example/utils/size_config.dart';
import 'package:example/views/widgets/otp_or_pin_modal_content.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class AppUtils {
  static String formatMoney(double price) {
    final lastValue = (price / 100).toString().split(".").last.toLowerCase();

    // Use NumberFormat to format the number as currency
    final currencyFormatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: (lastValue == "0" || lastValue == "00") ? 0 : 2,
    );

    return currencyFormatter.format(price / 100);
  }

  static Future<void> showOTPModal(
    BuildContext ctx,
    Function(String) onOtp, {
    required GlobalKey<OtpPinFieldState> controller,
    required TransactionStateRequestOTPTask task,
    bool isFromBusinessPaymentNotifier = false,
    VoidCallback? onManual,
    VoidCallback? sideEffect,
  }) async {
    await showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: true,
      context: ctx,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),

      //!
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: context.screenHeight * 0.3,
            width: double.infinity,
            child: OtpOrPinModalContent(
              controller: controller,
              task: task,
              onDone: onOtp,
            ),
          ),
        );
      },
    );
  }

  static Future<bool> showAppModalBottomSheet({
    required BuildContext callingContext,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: callingContext,
      isDismissible: isDismissible,
      isScrollControlled: true,
      enableDrag: enableDrag,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Wrap(children: [child]),
        );
      },
    );

    return result == true;
  }

  static void popMultiple(BuildContext context, int count) {
    if (count <= 0) return;

    int popped = 0;
    Navigator.of(context).popUntil((_) => popped++ >= count);
  }
}
