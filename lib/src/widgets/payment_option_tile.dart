// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.paymentMethod,
    required this.selectedPaymentMethod,
    required this.onTap,
    required this.iconURL,
  });

  final PaymentMethod paymentMethod;
  final PaymentMethod selectedPaymentMethod;
  final VoidCallback onTap;
  final String iconURL;

  @override
  Widget build(BuildContext context) {
    final sdkNotifier = MonaSDKNotifier();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 16.0,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  (sdkNotifier.merchantBrandingDetails?.colors.primaryColour ??
                          MonaColors.primaryBlue)
                      .withOpacity(
                0.05,
              ),
              child: SvgPicture.asset(
                iconURL.svg,
              ),
            ),

            context.sbW(16.0),

            ///
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paymentMethod.title,
                    style: TextStyle(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    paymentMethod.description,
                    style: TextStyle(
                      fontSize: context.sp(12),
                      fontWeight: FontWeight.w400,
                      color: MonaColors.hint,
                    ),
                  ),
                ],
              ),
            ),

            ///
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
                  color: paymentMethod == selectedPaymentMethod
                      ? (sdkNotifier
                              .merchantBrandingDetails?.colors.primaryColour ??
                          MonaColors.primaryBlue)
                      : MonaColors.bgGrey,
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: context.w(6),
                  backgroundColor: paymentMethod == selectedPaymentMethod
                      ? (sdkNotifier
                              .merchantBrandingDetails?.colors.primaryColour ??
                          MonaColors.primaryBlue)
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
