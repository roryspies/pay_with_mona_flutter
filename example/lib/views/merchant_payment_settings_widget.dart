import 'package:example/services/secure_storage/secure_storage.dart';
import 'package:example/services/secure_storage/secure_storage_keys.dart';
import 'package:example/utils/custom_button.dart';
import 'package:example/utils/custom_text_field.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';
import 'package:example/views/merchant_payment_settings_bottom_sheet_content.dart';
import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';

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
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();

    appSecureStorage.read(key: SecureStorageKeys.apiKey).then(
      (value) {
        _apiKeyController.text = value ?? '';
      },
    ).catchError(
      (error) {
        ("Error reading API key: $error");
      },
    );
  }

  @override
  void dispose() {
    isMerchantSettingsStatusOpen.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
                        context.sbH(8.0),

                        ///
                        CustomTextField(
                          controller: _apiKeyController,
                          title: "API Key",
                          hintText: "Enter your API key",
                        ),

                        context.sbH(16),

                        CustomButton(
                          label: 'Save',
                          onTap: () {
                            if (_apiKeyController.text.isEmpty) {
                              showSnackBar("Please add an API Key");
                              return;
                            }

                            appSecureStorage
                                .write(
                              key: SecureStorageKeys.apiKey,
                              value: _apiKeyController.text,
                            )
                                .then((_) {
                              showSnackBar("API Key saved successfully!");
                            }).catchError((error) {
                              showSnackBar("Failed to save API Key.");
                            });

                            setState(() {});
                          },
                        ),

                        context.sbH(16),

                        ///
                        CustomButton(
                          label: 'Reset',
                          onTap: () {
                            final secureStorage = SecureStorage();

                            secureStorage
                                .write(key: SecureStorageKeys.apiKey, value: '')
                                .then((_) {
                              _apiKeyController.clear();
                              showSnackBar("API Key deleted successfully!");
                            }).catchError((error) {
                              showSnackBar("Failed to delete API Key.");
                            });

                            setState(() {});
                          },
                        ),

                        context.sbH(40),

                        //!
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Checkout success event",
                            style: TextStyle(
                              fontSize: 14.0,
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
                              isDismissible: true,
                              enableDrag: true,
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
                                    color: MonaColors.primary,
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
