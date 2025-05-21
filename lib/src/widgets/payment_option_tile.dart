// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.paymentMethod,
    required this.selectedPaymentMethod,
    required this.onTap,
  });

  final PaymentMethod paymentMethod;
  final PaymentMethod selectedPaymentMethod;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: MonaColors.primaryBlue.withOpacity(
          0.1,
        ),
        child: Icon(paymentMethod.icon),
      ),
      contentPadding: EdgeInsets.zero,
      title: Text(
        paymentMethod.title,
        style: TextStyle(
          fontSize: context.sp(14),
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        paymentMethod.description,
        style: TextStyle(
          fontSize: context.sp(12),
          fontWeight: FontWeight.w400,
          color: MonaColors.hint,
        ),
      ),
      trailing: AnimatedContainer(
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
                ? MonaColors.primaryBlue
                : MonaColors.bgGrey,
          ),
        ),
        child: Center(
          child: CircleAvatar(
            radius: context.w(6),
            backgroundColor: paymentMethod == selectedPaymentMethod
                ? MonaColors.primaryBlue
                : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
