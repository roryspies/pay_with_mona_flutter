import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/payments/controller/payment_notifier.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
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
  final paymentNotifier = PaymentNotifier();

  @override
  void initState() {
    super.initState();
    paymentNotifier.addListener(_onPaymentStateChange);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await paymentNotifier.initiatePayment();
      },
    );
  }

  @override
  void dispose() {
    paymentNotifier.removeListener(_onPaymentStateChange);
    paymentNotifier.disposeSSEListener();
    paymentNotifier.dispose();
    super.dispose();
  }

  /// *** Rebuild UI when state changes
  void _onPaymentStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.neutralWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Method",
            style: TextStyle(
              fontSize: context.sp(16),
              fontWeight: FontWeight.w500,
              color: MonaColors.textHeading,
            ),
          ),

          context.sbH(16.0),

          Column(
            children: PaymentMethod.values.map(
              (paymentMethod) {
                if (paymentMethod == PaymentMethod.none) {
                  return const SizedBox.shrink();
                }

                return PaymentOptionTile(
                  onTap: () {
                    paymentNotifier.setSelectedPaymentType(
                      selectedPaymentMethod: paymentMethod,
                    );
                  },
                  selectedPaymentMethod: paymentNotifier.selectedPaymentMethod,
                  paymentMethod: paymentMethod,
                );
              },
            ).toList(),
          ),

          context.sbH(16.0),

          ///
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: switch (paymentNotifier.state == PaymentState.loading) {
              true => Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    color: MonaColors.primaryBlue,
                  ),
                ),

              ///
              false => SizedBox(
                  width: double.infinity,
                  height: context.h(50),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: paymentNotifier.selectedPaymentMethod ==
                              PaymentMethod.none
                          ? MonaColors.primaryBlue.withAlpha(100)
                          : MonaColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () async {
                      paymentNotifier
                        ..setCallingBuildContext(context: context)
                        ..setMonaCheckOut(checkoutDetails: widget.monaCheckOut)
                        ..makePayment(
                          method: paymentNotifier.selectedPaymentMethod.type,
                        );
                      // final res = await checkForSafariCreatedPasskey();
                      // res.log();
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
            },
          ),
        ],
      ),
    );
  }
}
