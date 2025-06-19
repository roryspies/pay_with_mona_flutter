import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/ui/constants/sdk_strings.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class PoweredByMona extends StatelessWidget {
  const PoweredByMona({
    super.key,
    this.title,
  });

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title ?? SDKStrings.poweredBy,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MonaColors.textHeading,
                ),
              ),

              context.sbW(4.0),

              ///
              SvgPicture.asset(
                SDKStrings.monaLogoWritten.svg,
              ),
            ],
          ),
          context.sbH(16.0)
        ],
      ),
    );
  }
}
