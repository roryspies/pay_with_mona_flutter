import 'package:flutter/material.dart';
import 'package:pay_with_mona/ui/widgets/bottom_sheet_top_header.dart';

class SdkBottomSheetWrapper extends StatelessWidget {
  const SdkBottomSheetWrapper({
    super.key,
    required this.child,
    this.showCancelButton = true,
    this.onCancelButtonTap,
    this.isForCustomTab = false,
  });

  final bool showCancelButton;
  final bool isForCustomTab;
  final Function()? onCancelButtonTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
    );
  }
}
