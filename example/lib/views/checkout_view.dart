import 'package:flutter/material.dart';
import 'package:example/views/customer_info_view.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/payment_option_tile.dart';
import 'package:example/utils/responsive_scaffold.dart';
import 'package:example/utils/size_config.dart';
import 'package:pay_with_mona/pay_with_mona.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final paymentOption = ''.notifier;

  @override
  void dispose() {
    paymentOption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
        ),
        backgroundColor: MonaColors.bgGrey,
        body: SingleChildScrollView(
          child: Column(
            children: [
              CustomerInfoView(),
              context.sbH(8),
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
                          "₦",
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
              PayWithMona.payWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
