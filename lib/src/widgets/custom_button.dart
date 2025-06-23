// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.height = 52,
    this.width,
    this.color,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.child,
  });

  final double height;
  final double? width;
  final Color? color;
  final String label;
  final bool isLoading;
  final Widget? child;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final sdkNotifier = MonaSDKNotifier();
    final targetColor =
        sdkNotifier.merchantBrandingDetails?.colors.primaryColour ??
            MonaColors.primaryBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: width ?? double.infinity,
      height: context.h(height),
      decoration: BoxDecoration(
        color: isLoading ? targetColor.withOpacity(0.7) : targetColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        ///
        onPressed: isLoading ? null : onTap,
        child: switch (isLoading) {
          true => Transform.scale(
              scale: 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: MonaColors.neutralWhite,
              ),
            ),
          _ => child ??
              Text(
                label,
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: const Color(0xFFF4FCF5),
                  fontWeight: FontWeight.w500,
                ),
              ),
        },
      ),
    ).ignorePointer(
      isLoading: isLoading,
    );
  }
}

/* 
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.height = 52,
    this.width,
    this.color,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  final double height;
  final double? width;
  final Color? color;
  final String label;
  final bool isLoading;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final targetColor = color ?? MonaColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: width ?? double.infinity,
      height: context.h(height),
      decoration: BoxDecoration(
        color: isLoading ? targetColor.withOpacity(0.7) : targetColor,
        borderRadius: BorderRadius.circular(4),
      ),

      ///
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          ///
          onPressed: isLoading ? null : onTap,

          ///
          child: switch (isLoading) {
            true => Transform.scale(
                scale: 0.4,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: MonaColors.neutralWhite,
                ),
              ),
            _ => Text(
                label,
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: const Color(0xFFF4FCF5),
                  fontWeight: FontWeight.w500,
                ),
              ),
          }),
    );
  }
}
 */
