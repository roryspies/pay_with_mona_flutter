import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class MyIcon extends StatelessWidget {
  const MyIcon({
    required this.icon,
    this.height,
    this.width,
    this.color,
    this.onTap,
    super.key,
  });

  final String icon;
  final double? height;
  final double? width;
  final Color? color;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: SvgPicture.asset(
        icon.svg,
        // ignore: deprecated_member_use
        color: color,
        height: context.h(height ?? 24),
        width: width,
      ),
    );
  }
}
