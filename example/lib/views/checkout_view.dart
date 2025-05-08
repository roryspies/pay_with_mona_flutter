import 'package:flutter/material.dart';
import 'package:example/views/customer_info_view.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/responsive_scaffold.dart';
import 'package:example/utils/size_config.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

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
              PayWithMona.payWidget(
                firstName: "John",
                lastName: "Doe Smith",
                dateOfBirth: DateTime(1995, 2, 1),
                transactionId: "1234567890",
                merchantName: "NGDeals",
                phoneNumber: "2347019017218",
                primaryColor: MonaColors.primaryBlue,
                secondaryColor: MonaColors.neutralWhite,
                bvn: "1234567890",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
