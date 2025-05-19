import 'package:flutter/material.dart';

class SDKUtils {
  static Future<bool> showSDKModalBottomSheet({
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
