import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class SecuredByMona extends StatelessWidget {
  const SecuredByMona({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Secured by",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MonaColors.textHeading,
          ),
        ),

        context.sbW(8.0),

        ///
        SvgPicture.asset(
          "mona_written_logo".svg,
        )
      ],
    );
  }
}
