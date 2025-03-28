import 'package:flutter/material.dart';

import 'package:pay_with_mona/src/features/payments/payment_notifier.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/payment_option_tile.dart';

class PayWithMonaWidget extends StatefulWidget {
  const PayWithMonaWidget({
    super.key,
    required this.monaCheckOut,
  });

  final MonaCheckOut monaCheckOut;

  @override
  State<PayWithMonaWidget> createState() => _PayWithMonaWidgetState();
}

class _PayWithMonaWidgetState extends State<PayWithMonaWidget> {
  final paymentOption = 'transfer'.notifier;
  final paymentNotifier = PaymentNotifier();

  @override
  void initState() {
    super.initState();
    paymentNotifier.addListener(_onPaymentStateChange);
  }

  @override
  void dispose() {
    paymentNotifier.removeListener(_onPaymentStateChange);
    paymentNotifier.dispose();
    paymentOption.dispose();
    paymentNotifier.disposeSSEListener();
    super.dispose();
  }

  void _onPaymentStateChange() {
    setState(() {}); // Rebuild UI when state changes
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(20)),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.neutralWhite,
      ),
      child: paymentOption.sync(
        builder: (context, value, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: context.h(32),
            children: [
              Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: context.sp(16),
                  fontWeight: FontWeight.w500,
                  color: MonaColors.textHeading,
                ),
              ),
              Column(
                spacing: context.h(24),
                children: [
                  PaymentOptionTile(
                    title: "Pay by Transfer",
                    descriptiom: "Pay for your order with cash on delivery",
                    icon: Icon(Icons.money),
                    type: 'transfer',
                    paymentOption: paymentOption,
                  ),
                  PaymentOptionTile(
                    title: "Pay by Card",
                    descriptiom: "Visa, Verve and Mastercard accepted",
                    icon: Icon(Icons.credit_card),
                    type: 'card',
                    paymentOption: paymentOption,
                  ),
                ],
              ),
              paymentNotifier.state == PaymentState.loading
                  ? Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        color: MonaColors.primaryBlue,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: context.h(50),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: paymentOption.value.isEmpty
                              ? MonaColors.primaryBlue.withAlpha(100)
                              : MonaColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () async {
                          await paymentNotifier.makePayment(
                            monaCheckOut: widget.monaCheckOut,
                            method: paymentOption.value,
                            context: context,
                          );
                        },
                        child: Text(
                          "Proceed to pay ",
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
            ],
          );
        },
      ),
    );
  }
}
