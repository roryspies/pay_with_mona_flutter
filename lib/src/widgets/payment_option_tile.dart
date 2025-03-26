import 'package:flutter/material.dart';

import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.title,
    required this.descriptiom,
    required this.type,
    required this.icon,
    required this.paymentOption,
  });

  final String title;
  final String descriptiom;
  final String type;
  final Icon icon;
  final ValueNotifier<String> paymentOption;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        paymentOption.value = type;
      },
      child: Row(
        children: [
          icon,
          context.sbW(14.75),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                descriptiom,
                style: TextStyle(
                  fontSize: context.sp(12),
                  fontWeight: FontWeight.w400,
                  color: MonaColors.hint,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedContainer(
            duration: Duration(
              milliseconds: 300,
            ),
            height: context.h(24),
            width: context.w(24),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.h(24)),
                border: Border.all(
                  width: 1.5,
                  color: paymentOption.value == type
                      ? MonaColors.primaryBlue
                      : MonaColors.bgGrey,
                )),
            child: Center(
              child: CircleAvatar(
                radius: context.w(6),
                backgroundColor: paymentOption.value == type
                    ? MonaColors.primaryBlue
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
