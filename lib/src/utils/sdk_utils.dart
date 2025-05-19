import 'package:flutter/material.dart';

class SDKUtils {
  //TransferStatusModal()
  static Future<void> showMerchantSettingsModal({
    required BuildContext callingContext,
    required Widget child,
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
          child: Wrap(
            children: [
              child,
            ],
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
