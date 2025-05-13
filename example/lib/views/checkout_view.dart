import 'package:example/services/customer_details_notifier.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/responsive_scaffold.dart';
import 'package:example/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class CheckoutView extends ConsumerWidget {
  const CheckoutView({
    super.key,
    required this.transactionId,
    required this.amount,
  });

  final String transactionId;
  final String amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveScaffold(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
        ),
        backgroundColor: MonaColors.bgGrey,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(context.w(20)),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MonaColors.neutralWhite,
                ),
                child: Column(
                  spacing: context.h(32),
                  children: [
                    Text(
                      "Payment Summary",
                      style: TextStyle(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.w500,
                        color: MonaColors.textHeading,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textHeading,
                          ),
                        ),
                        Text(
                          "₦$amount",
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textHeading,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              context.sbH(8),
              PayWithMona.payWidget(
                payload: MonaCheckOut(
                  firstName: '',
                  lastName: '',
                  dateOfBirth: DateTime.now(),
                  transactionId: transactionId,
                  merchantName: 'NGDeals',
                  primaryColor: Colors.purple,
                  secondaryColor: Colors.indigo,
                  phoneNumber:
                      ref.watch(customerDetailsNotifierProvider).phoneNumber,
                  amount: num.parse(amount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
