import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/widgets/bottom_sheet_top_header.dart';
import 'package:pay_with_mona/ui/widgets/sdk_loader.dart';

class SdkBottomSheetWrapper extends StatelessWidget {
  SdkBottomSheetWrapper({
    super.key,
    required this.child,
    this.showCancelButton = true,
    this.onCancelButtonTap,
    this.isForCustomTab = false,
    this.loadingStateTitle,
  });

  final bool showCancelButton;
  final bool isForCustomTab;
  final Function()? onCancelButtonTap;

  final Widget child;
  final String? loadingStateTitle;
  final sdkNotifier = MonaSDKNotifier();

  @override
  Widget build(BuildContext context) {
    final bgColour =
        sdkNotifier.merchantBrandingDetails?.colors.primaryColour ??
            MonaColors.primaryBlue;
    return Container(
      width: double.infinity,

      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColour,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),

      ///
      child: AnimatedSize(
        duration: const Duration(
          milliseconds: 300,
        ),
        child: Wrap(
          children: [
            BottomSheetTopHeader(
              isForCustomTab: isForCustomTab,
              showCancelButton: showCancelButton,
              onCancelButtonTap: onCancelButtonTap,
            ),

            /// *** Content
            SDKLoader(
              loadingStateTitle: loadingStateTitle,
              child: child,
            ),
          ],
        ),
      ),
    ); /* AnimatedContainer(
      width: double.infinity,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),

      ///
      child: Wrap(
        children: [
          BottomSheetTopHeader(
            isForCustomTab: isForCustomTab,
            showCancelButton: showCancelButton,
            onCancelButtonTap: onCancelButtonTap,
          ),

          /// *** Content
          child,
        ],
      ),
    ); */
  }
}
