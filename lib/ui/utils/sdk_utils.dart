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

/*   static Future<bool> showSDKModalBottomSheet({
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
 */
  static Future<bool?> showSDKModalBottomSheet({
    required BuildContext callingContext,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isForCustomTab = false,
    bool showCancelButton = false,
    VoidCallback? onCancelButtonTap,
    Color backgroundColor = Colors.white,
  }) {
    return showGeneralDialog<bool>(
      context: callingContext,
      barrierDismissible: isDismissible,
      barrierLabel:
          MaterialLocalizations.of(callingContext).modalBarrierDismissLabel,
      transitionDuration: const Duration(
        milliseconds: 300,
      ),

      pageBuilder: (ctx, anim, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: SdkBottomSheetWrapper(
              isForCustomTab: isForCustomTab,
              showCancelButton: showCancelButton,
              onCancelButtonTap: onCancelButtonTap,
              child: child,
            ),
          ),
        );
      },

      ///
      transitionBuilder: (ctx, animation, secondaryAnimation, page) {
        // Slide from bottom (Offset(0,1) → Offset(0,0)) + fade (0→1)
        final slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: animation,
            child: page,
          ),
        );
      },
    );
  }

  static void popMultiple(BuildContext context, int count) {
    if (count <= 0) return;

    int popped = 0;
    Navigator.of(context).popUntil((_) => popped++ >= count);
  }
}
