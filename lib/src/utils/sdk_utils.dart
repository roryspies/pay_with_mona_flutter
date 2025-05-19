import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/merchant_payment_settings_bottom_sheet_content.dart';

class SDKUtils {
  static Future<void> showMerchantSettingsModal({
    required BuildContext callingContext,
  }) async {
    await showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: true,
      context: callingContext,
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
            height: context.screenHeight * 0.4,
            width: double.infinity,
            child: MerchantPaymentSettingsBottomSheetContent(),
          ),
        );
      },
    );
  }
}

void popMultiple(BuildContext context, int count) {
  if (count <= 0) return;

  int popped = 0;
  Navigator.of(context).popUntil((_) => popped++ >= count);
}
