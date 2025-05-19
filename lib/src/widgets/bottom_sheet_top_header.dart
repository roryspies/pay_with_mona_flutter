import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class BottomSheetTopHeader extends StatelessWidget {
  const BottomSheetTopHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.h(36),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.primaryBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: SvgPicture.asset(
              'x'.svg,
              height: context.h(20),
            ),
          ), 
          context.sbW(9),
        ],
      ),
    );
  }
}
