// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/notifier_enums.dart';
import 'package:pay_with_mona/src/models/pending_payment_response_model.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/constants/sdk_strings.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/src/widgets/sdk_payment_status_modal.dart';

class ConfirmTransactionModal extends StatefulWidget {
  const ConfirmTransactionModal({
    super.key,
    required this.transactionAmountInKobo,
    required this.selectedPaymentMethod,
    this.showTransactionStatusIndicator = false,
    this.onPay,
  });

  final num transactionAmountInKobo;
  final PaymentMethod selectedPaymentMethod;
  final bool showTransactionStatusIndicator;
  final VoidCallback? onPay;

  @override
  State<ConfirmTransactionModal> createState() =>
      _ConfirmTransactionModalState();
}

class _ConfirmTransactionModalState extends State<ConfirmTransactionModal> {
  final _sdkNotifier = MonaSDKNotifier();
  bool isLoading = false;
  final showTransactionStatusIndicator = ValueNotifier(false);
  BankOption? _bank;
  CardOption? _card;

  @override
  void initState() {
    super.initState();
    switch (widget.selectedPaymentMethod) {
      case PaymentMethod.savedBank:
        _bank = _sdkNotifier.selectedBankOption;
        break;
      case PaymentMethod.savedCard:
        _card = _sdkNotifier.selectedCardOption;
        break;
      default:
        break;
    }

    showTransactionStatusIndicator.value =
        widget.showTransactionStatusIndicator;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _sdkNotifier
          ..txnStateStream.listen(
            (state) async {
              switch (state) {
                case TransactionStateInitiated():
                  "ConfirmTransactionModal :::_sdkNotifier ::: txnStateStream.listen ::: TransactionStateInitiated "
                      .log();
                  showTransactionStatusIndicator.value = true;
                  if (mounted) setState(() {});
                  _sdkNotifier.setShowCancelButton(showCancelButton: false);

                  break;
                default:
                  break;
              }
            },
            onError: (err) {
              ('Error from transactionStateStream: $err').log();
            },
          )
          ..sdkStateStream.listen(
            (state) async {
              switch (state) {
                case MonaSDKState.loading:
                  if (mounted) setState(() => isLoading = true);
                  break;

                default:
                  if (mounted) setState(() => isLoading = false);
                  break;
              }
            },
            onError: (err) {
              ('Error from transactionStateStream: $err').log();
            },
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: MonaColors.textHeading,
    );

    final subtitleStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: MonaColors.textBody,
    );

    return showTransactionStatusIndicator.sync(
      builder: (context, value, child) {
        final showStatusIndicator = value;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            color: showStatusIndicator
                ? MonaColors.bgGrey
                : MonaColors.neutralWhite,
          ),

          ///
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: switch (showStatusIndicator) {
                true => SdkPaymentStatusModal(),

                ///
                false => Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: MonaColors.bgGrey,
                          borderRadius: BorderRadius.circular(
                            8.0,
                          ),
                        ),

                        ///
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Amount to pay",
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: MonaColors.textBody,
                              ),
                            ),

                            ///
                            Text(
                              "${SDKStrings.nairaSymbol}${SDKUtils.formatMoney(double.parse(widget.transactionAmountInKobo.toString()))}",
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.w700,
                                color: MonaColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ///
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Payment Method",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: MonaColors.textHeading,
                                ),
                              ),
                            ),

                            context.sbH(8.0),

                            ListTile(
                              onTap: () {
                                if (isLoading) {
                                  return;
                                }
                                Navigator.of(context).pop();
                              },
                              contentPadding: EdgeInsets.zero,
                              leading: switch (widget.selectedPaymentMethod) {
                                PaymentMethod.savedBank => CircleAvatar(
                                    backgroundColor: MonaColors.neutralWhite,
                                    child: Image.network(
                                      _bank?.logo ?? "",
                                    ),
                                  ),
                                PaymentMethod.savedCard => CircleAvatar(
                                    backgroundColor: MonaColors.neutralWhite,
                                    child: Image.network(
                                      _card?.logo ?? "",
                                    ),
                                  ),
                                _ => CircleAvatar(
                                    backgroundColor: (_sdkNotifier
                                                .merchantBrandingDetails
                                                ?.colors
                                                .primaryColour ??
                                            MonaColors.primaryBlue)
                                        .withOpacity(
                                      0.1,
                                    ),
                                    child:
                                        Icon(widget.selectedPaymentMethod.icon),
                                  ),
                              },

                              /// *** Title
                              title: switch (widget.selectedPaymentMethod) {
                                PaymentMethod.savedBank => Text(
                                    _bank?.bankName ?? "",
                                    style: titleStyle,
                                  ),
                                PaymentMethod.savedCard => Text(
                                    _card?.bankName ?? "",
                                    style: titleStyle,
                                  ),
                                _ => Text(
                                    widget.selectedPaymentMethod.title,
                                    style: titleStyle,
                                  ),
                              },

                              /// *** Subtitle
                              subtitle: switch (widget.selectedPaymentMethod) {
                                PaymentMethod.savedBank => Text(
                                    _bank?.accountNumber ?? "",
                                    style: subtitleStyle,
                                  ),
                                PaymentMethod.savedCard => Text(
                                    _card?.accountNumber ?? "",
                                    style: subtitleStyle,
                                  ),
                                _ => Text(
                                    widget.selectedPaymentMethod.description,
                                    style: subtitleStyle,
                                  ),
                              },

                              /// ***
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Change",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: (_sdkNotifier
                                              .merchantBrandingDetails
                                              ?.colors
                                              .primaryColour ??
                                          MonaColors.primaryBlue),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: (_sdkNotifier.merchantBrandingDetails
                                            ?.colors.primaryColour ??
                                        MonaColors.primaryBlue),
                                  ),
                                ],
                              ),
                            ),

                            context.sbH(8.0),

                            /// ***
                            //!
                            CustomButton(
                              label: "Pay",
                              isLoading: isLoading,
                              onTap: () {
                                if (isLoading) {
                                  return;
                                }

                                if (widget.onPay != null) {
                                  widget.onPay!();
                                  return;
                                }

                                /*  _sdkNotifier
                                  ..setCallingBuildContext(context: context)
                                  ..makePayment(); */
                              },
                            ),

                            //!
                            context.sbH(16.0),

                            PoweredByMona()
                          ],
                        ),
                      ),
                    ],
                  ),
              },
            ),
          ),
        );
      },
    );
  }
}
