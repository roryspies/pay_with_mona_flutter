import 'package:example/services/transaction_state_notifier.dart';
import 'package:example/utils/custom_button.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';
import 'package:example/views/products_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class ResultView extends ConsumerWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionStatusProvider);

    return Scaffold(
      backgroundColor: MonaColors.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            context.sbH(20),

            //
            Container(
              width: double.infinity,
              color: MonaColors.neutralWhite,
              padding: EdgeInsets.all(context.w(20)),
              child: Column(
                spacing: context.h(4),
                children: [
                  SvgPicture.asset(
                    state.transactionStatus.name.svg,
                    height: context.h(48),
                  ),
                  Text(
                    "Payment ${state.transactionStatus.name}",
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            context.sbH(37),

            Container(
              width: double.infinity,
              color: MonaColors.neutralWhite,
              padding: EdgeInsets.all(context.w(20)),
              child: Column(
                spacing: context.h(32),
                children: [
                  Text(
                    "Payment summary",
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ...List.generate(
                    3,
                    (index) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (switch (index) {
                                0 => 'Payment amount',
                                1 => 'Transaction ID  ',
                                _ => 'Order Status',
                              }),
                              style: TextStyle(
                                fontSize: context.sp(12),
                                color: Color(0xFF999999),
                              ),
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Text(
                                  (switch (index) {
                                    0 => "₦${state.amount / 100}",
                                    1 => state.friendlyID,
                                    _ => state.transactionStatus.status,
                                  }),
                                  style: TextStyle(
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF000000)),
                                ),
                                if (state.transactionStatus ==
                                        TransactionStatus.initiated &&
                                    index == 2)
                                  SizedBox(
                                    height: context.h(16),
                                    width: context.h(16),
                                    child: CircularProgressIndicator(
                                      color: MonaColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  //!
                  CustomButton(
                    onTap: () {
                      MonaSDKNotifier().resetSDKState();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => ProductsView()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    label: 'Return to home',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
