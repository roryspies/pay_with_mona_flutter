import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class BottomSheetTopHeader extends StatefulWidget {
  const BottomSheetTopHeader({
    super.key,
    this.showCancelButton = true,
    this.onCancelButtonTap,
  });

  final bool showCancelButton;
  final Function()? onCancelButtonTap;

  @override
  State<BottomSheetTopHeader> createState() => _BottomSheetTopHeaderState();
}

class _BottomSheetTopHeaderState extends State<BottomSheetTopHeader> {
  final sdkNotifier = MonaSDKNotifier();

  @override
  void initState() {
    super.initState();
    sdkNotifier.addListener(_onSdkStateChange);
  }

  void _onSdkStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showCancelButton =
        sdkNotifier.showCancelButton == false ? false : widget.showCancelButton;

    return Container(
      height: context.h(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.primaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),

      ///***
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "lagos_city".png,
              fit: BoxFit.fitWidth,
            ),
          ),

          ///
          if (showCancelButton) ...[
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: InkWell(
                onTap: widget.onCancelButtonTap ??
                    () => Navigator.of(context).pop(),
                child: CircleAvatar(
                  radius: 12,
                  child: SvgPicture.asset(
                    'x'.svg,
                    height: context.h(21),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
