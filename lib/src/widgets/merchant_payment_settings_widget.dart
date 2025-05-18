import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/sdk_utils.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class MerchantPaymentSettingsWidget extends StatefulWidget {
  const MerchantPaymentSettingsWidget({super.key});

  @override
  State<MerchantPaymentSettingsWidget> createState() =>
      _MerchantPaymentSettingsWidgetState();
}

class _MerchantPaymentSettingsWidgetState
    extends State<MerchantPaymentSettingsWidget> {
  final _sdkNotifier = MonaSDKNotifier();
  final isMerchantSettingsStatusOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sdkNotifier.addListener(_onSDKStateChange);
    });
  }

  void _onSDKStateChange() {
    if (mounted) setState(() {});
  }

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
                            await SDKUtils.showMerchantSettingsModal(
                              callingContext: context,
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
/* 
class MerchantPaymentSettingsWidget extends StatefulWidget {
  const MerchantPaymentSettingsWidget({super.key});

  @override
  State<MerchantPaymentSettingsWidget> createState() =>
      _MerchantPaymentSettingsWidgetState();
}

class _MerchantPaymentSettingsWidgetState
    extends State<MerchantPaymentSettingsWidget> {
  final _sdkNotifier = MonaSDKNotifier();

  final isMerchantSettingsStatusOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sdkNotifier.addListener(_onSDKStateChange);
    });
  }

  void _onSDKStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return isMerchantSettingsStatusOpen.sync(
      builder: (context, isExpanded, child) {
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
                            await SDKUtils.showMerchantSettingsModal(
                              callingContext: context,
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
                                    "${_sdkNotifier.currentMerchantPaymentSettingsEnum?.displayName}",
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
                                )
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
 */
