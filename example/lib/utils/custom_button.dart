import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.height = 52,
    this.width,
    this.color,
    required this.label,
    this.onTap,
  });

  final double height;
  final double? width;
  final Color? color;
  final String label;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: context.h(height),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color ?? MonaColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: () {
          onTap?.call();
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.sp(14),
            color: Color(0xFFF4FCF5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
