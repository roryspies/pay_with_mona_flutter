import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/merchant_payment_settings_bottom_sheet_content.dart';

class MerchantPaymentSettingsWidget extends StatefulWidget {
  const MerchantPaymentSettingsWidget({
    super.key,
    this.transactionAmountInKobo,
  });

  final num? transactionAmountInKobo;

  @override
  State<MerchantPaymentSettingsWidget> createState() =>
      _MerchantPaymentSettingsWidgetState();
}

class _MerchantPaymentSettingsWidgetState
    extends State<MerchantPaymentSettingsWidget> {
  final isMerchantSettingsStatusOpen = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          isMerchantSettingsStatusOpen,
        ],
      ),
      builder: (context, _) {
        final isExpanded = isMerchantSettingsStatusOpen.value;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 32,
          ),
          decoration: BoxDecoration(
            color: MonaColors.neutralWhite,
            borderRadius: BorderRadius.circular(
              8.0,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  isMerchantSettingsStatusOpen.value =
                      !isMerchantSettingsStatusOpen.value;
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Merchant Settings",
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        isMerchantSettingsStatusOpen.value =
                            !isMerchantSettingsStatusOpen.value;
                      },
                      icon: switch (isExpanded) {
                        false => Icon(
                            Icons.keyboard_arrow_up,
                          ),
                        true => Icon(
                            Icons.keyboard_arrow_down,
                          )
                      },
                    )
                  ],
                ),
              ),

              ///
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: switch (isExpanded) {
                  false => SizedBox.shrink(),
                  true => Column(
                      children: [
                        context.sbH(8),

                        //!
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Checkout success event",
                            style: TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                        ),

                        context.sbH(8.0),

                        InkWell(
                          onTap: () async {
                            if (widget.transactionAmountInKobo == null ||
                                widget.transactionAmountInKobo! < 20) {
                              Navigator.of(context).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Transaction amount must be at least 20 Naira.",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            await SDKUtils.showSDKModalBottomSheet(
                              callingContext: context,
                              child: MerchantPaymentSettingsBottomSheetContent(
                                transactionAmountInKobo:
                                    widget.transactionAmountInKobo,
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              color: MonaColors.bgGrey,
                              borderRadius: BorderRadius.circular(
                                8.0,
                              ),
                            ),

                            //!
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${MonaSDKNotifier().currentMerchantPaymentSettingsEnum?.displayName}",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.arrow_drop_down_circle_outlined,
                                    color: MonaColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        context.sbH(16),
                      ],
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
