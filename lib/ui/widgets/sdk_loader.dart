// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class SDKLoader extends StatelessWidget {
  SDKLoader({
    super.key,
    this.loadingStateTitle = "Processing",
  });

  final String loadingStateTitle;
  final _monaSDKNotifier = MonaSDKNotifier();

  @override
  Widget build(BuildContext context) {
    final progressIndicatorColour =
        _monaSDKNotifier.merchantBrandingDetails?.colors.primaryColour ??
            MonaColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ///
          context.sbH(48.0),

          CircleAvatar(
            radius: 24,
            backgroundColor: progressIndicatorColour.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                strokeWidth: 4.0,
                color: progressIndicatorColour,
                strokeCap: StrokeCap.round,
                backgroundColor: progressIndicatorColour.withOpacity(0.15),
              ),
            ),
          ),

          ///
          context.sbH(16.0),

          Text(
            loadingStateTitle,
            style: TextStyle(
              color: MonaColors.textBody,
              fontWeight: FontWeight.w400,
            ),
          ),

          ///
          context.sbH(48.0),

          PoweredByMona()
        ],
      ),
    );
  }
}
