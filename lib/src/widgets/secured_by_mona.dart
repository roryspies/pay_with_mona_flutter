import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class SecuredByMona extends StatelessWidget {
  const SecuredByMona({
    super.key,
    this.title,
  });

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title ?? "Secured by",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MonaColors.textHeading,
          ),
        ),

        context.sbW(4.0),

        ///
        SvgPicture.asset(
          "mona_written_logo".svg,
        )
      ],
    );
  }
}
