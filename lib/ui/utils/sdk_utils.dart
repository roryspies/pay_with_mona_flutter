import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pay_with_mona/ui/widgets/sdk_bottom_sheet_container.dart';

abstract class SDKUtils {
  static String formatMoney(double price) {
    final lastValue = (price / 100).toString().split(".").last.toLowerCase();

    final currencyFormatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: (lastValue == "0" || lastValue == "00") ? 0 : 2,
    );

    return currencyFormatter.format(price / 100);
  }

  static Future<bool> showSDKModalBottomSheet({
    required BuildContext callingContext,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showCancelButton = true,
    bool isForCustomTab = false,
    final Function()? onCancelButtonTap,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: callingContext,
      isDismissible: isDismissible,
      isScrollControlled: true,
      enableDrag: enableDrag,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SdkBottomSheetWrapper(
          isForCustomTab: isForCustomTab,
          showCancelButton: showCancelButton,
          onCancelButtonTap: onCancelButtonTap,
          child: child,
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
