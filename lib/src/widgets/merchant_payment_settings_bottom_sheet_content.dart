// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';

class MerchantPaymentSettingsBottomSheetContent extends StatefulWidget {
  const MerchantPaymentSettingsBottomSheetContent({super.key});

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
    _sdkNotifier.addListener(_onSDKStateChange);
  }

  void _onSDKStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Merchant Settings",
                  style: TextStyle(
                    fontSize: 21.0,
                    fontWeight: FontWeight.w500,
                    color: MonaColors.textHeading,
                  ),
                ),
              ),
              CircleAvatar(
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.close,
                  ),
                ),
              )
            ],
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
                trailing: isCurrentOption
                    ? CircleAvatar(
                        backgroundColor:
                            MonaColors.primaryBlue.withOpacity(0.1),
                        child: Icon(
                          Icons.check,
                        ),
                      )
                    : null,
              );
            },
          )
        ],
      ),
    );
  }
}
