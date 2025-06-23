// ignore_for_file: deprecated_member_use
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

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
          mainAxisSize: MainAxisSize.min,
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
                final isCurrentOption = currentSetting.paymentName ==
                    _sdkNotifier
                        .currentMerchantPaymentSettingsEnum!.paymentName;

                return ListTile(
                  onTap: () async {
                    await _sdkNotifier.updateMerchantPaymentSettingsWidget(
                      currentSettingsPaymentName: currentSetting.name,
                      onEvent: (bool isSuccessful) {
                        Navigator.of(context).pop();

                        if (isSuccessful) {
                          return;
                        }

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
                                MonaColors.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.check,
                            ),
                          ),
                        false => CircleAvatar(
                            backgroundColor:
                                MonaColors.primary.withOpacity(0.1),
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

enum MerchantPaymentSettingsEnum {
  monaSuccess,
  debitSuccess,
  walletReceiveInProgress,
  walletReceiveComplete;

  String get displayName {
    switch (this) {
      case monaSuccess:
        return "Mona success";
      case debitSuccess:
        return "Debit success";
      case walletReceiveInProgress:
        return "Wallet receive in progress";
      case walletReceiveComplete:
        return "Wallet receive completed";
    }
  }

  String get paymentName {
    switch (this) {
      case monaSuccess:
        return "mona_success";
      case debitSuccess:
        return "debit_success";
      case walletReceiveInProgress:
        return "wallet_received";
      case walletReceiveComplete:
        return "wallet_completed";
    }
  }
}
