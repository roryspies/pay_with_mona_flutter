// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';

class MerchantPaymentSettingsBottomSheetContent extends StatefulWidget {
  const MerchantPaymentSettingsBottomSheetContent({
    super.key,
    this.transactionAmountInKobo,
  });

  final num? transactionAmountInKobo;

  @override
  State<MerchantPaymentSettingsBottomSheetContent> createState() =>
      _MerchantPaymentSettingsBottomSheetContentState();
}

class _MerchantPaymentSettingsBottomSheetContentState
    extends State<MerchantPaymentSettingsBottomSheetContent> {
  final _sdkNotifier = MonaSDKNotifier();

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Merchant Settings",
                style: TextStyle(
                  fontSize: 21.0,
                  fontWeight: FontWeight.w600,
                  color: MonaColors.textHeading,
                ),
              ),
            ),

            context.sbH(8.0),

            ///
            ...MerchantPaymentSettingsEnum.values.map(
              (currentSetting) {
                final isCurrentOption = currentSetting ==
                    _sdkNotifier.currentMerchantPaymentSettingsEnum;

                return ListTile(
                  onTap: () async {
                    await _sdkNotifier.updateMerchantPaymentSettingsWidget(
                      currentSetting: currentSetting,
                      merchantID: "",
                      transactionAmountInKobo: widget.transactionAmountInKobo,
                      onEvent: (bool isSuccessful) {
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSuccessful
                                  ? 'Setting updated successfully.'
                                  : "Could not update settings",
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "${currentSetting.displayName} ",
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                  trailing: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: Transform.scale(
                      scale: 0.6,
                      child: switch (isCurrentOption) {
                        true => CircleAvatar(
                            backgroundColor:
                                MonaColors.primaryBlue.withOpacity(0.1),
                            child: Icon(
                              Icons.check,
                            ),
                          ),
                        false => CircleAvatar(
                            backgroundColor:
                                MonaColors.primaryBlue.withOpacity(0.1),
                            child: Transform.scale(
                              scale: 0.8,
                              child: CircleAvatar(
                                backgroundColor: MonaColors.neutralWhite,
                              ),
                            ),
                          ),
                      },
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
