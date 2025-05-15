import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';
import 'package:pay_with_mona/src/core/services/auth_service.dart';
import 'package:pay_with_mona/src/features/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/controller/sdk_notifier.dart';
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
  final sdkNotifier = MonaSDKNotifier();

  @override
  void initState() {
    super.initState();
    sdkNotifier
      ..addListener(_onPaymentStateChange)
      ..setMonaCheckOut(checkoutDetails: widget.monaCheckOut);
  }

  @override
  void dispose() {
    /// *** Considering we're using a singleton class for Payment Notifier
    /// *** Do not dispose the Notifier itself, so that instance isn't gone with the wind.
    sdkNotifier.removeListener(_onPaymentStateChange);
    super.dispose();
  }

  /// *** Rebuild UI when state changes
  void _onPaymentStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final savedBanks =
        sdkNotifier.currentPaymentResponseModel?.savedPaymentOptions?.bank;
    final savedCards =
        sdkNotifier.currentPaymentResponseModel?.savedPaymentOptions?.card;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(context.w(16)),
        width: double.infinity,
        decoration: BoxDecoration(
          color: MonaColors.neutralWhite,
        ),
        child: SingleChildScrollView(
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

              if (savedCards != null && savedCards.isNotEmpty) ...[
                Column(
                  children: savedCards.map(
                    (card) {
                      final selectedCardID =
                          sdkNotifier.selectedCardOption?.bankId;

                      return ListTile(
                        onTap: () {
                          sdkNotifier.setSelectedPaymentMethod(
                            method: PaymentMethod.savedCard,
                          );

                          sdkNotifier.setSelectedCardOption(
                            cardOption: card,
                          );
                        },

                        /// ***
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: MonaColors.neutralWhite,
                          child: Image.network(
                            card.logo ?? "",
                          ),
                        ),

                        title: Text(
                          card.accountName ?? "",
                          style: TextStyle(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textHeading,
                          ),
                        ),

                        subtitle: Text(
                          "Card - ${card.accountNumber}",
                          style: TextStyle(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.w400,
                            color: MonaColors.textBody,
                          ),
                        ),

                        trailing: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: context.h(24),
                          width: context.w(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.h(24)),
                            border: Border.all(
                              width: 1.5,
                              color: (sdkNotifier.selectedPaymentMethod ==
                                          PaymentMethod.savedCard &&
                                      selectedCardID == card.bankId)
                                  ? MonaColors.primaryBlue
                                  : MonaColors.bgGrey,
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: context.w(6),
                              backgroundColor:
                                  (sdkNotifier.selectedPaymentMethod ==
                                              PaymentMethod.savedCard &&
                                          selectedCardID == card.bankId)
                                      ? MonaColors.primaryBlue
                                      : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],

              /// *** Saved Banks
              if (savedBanks != null && savedBanks.isNotEmpty) ...[
                Column(
                  children: savedBanks.map(
                    (bank) {
                      final selectedBankID =
                          sdkNotifier.selectedBankOption?.bankId;

                      "Selected Bank ID: $selectedBankID";

                      return ListTile(
                        onTap: () {
                          sdkNotifier.setSelectedPaymentMethod(
                            method: PaymentMethod.savedBank,
                          );

                          sdkNotifier.setSelectedBankOption(
                            bankOption: bank,
                          );
                        },

                        /// ***
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: MonaColors.neutralWhite,
                          child: Image.network(
                            bank.logo ?? "",
                          ),
                        ),

                        title: Text(
                          bank.bankName ?? "",
                          style: TextStyle(
                            fontSize: context.sp(14),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textHeading,
                          ),
                        ),

                        subtitle: Text(
                          "Account - ${bank.accountNumber}",
                          style: TextStyle(
                            fontSize: context.sp(12),
                            fontWeight: FontWeight.w400,
                            color: MonaColors.textBody,
                          ),
                        ),

                        trailing: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: context.h(24),
                          width: context.w(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(context.h(24)),
                            border: Border.all(
                              width: 1.5,
                              color: (sdkNotifier.selectedPaymentMethod ==
                                          PaymentMethod.savedBank &&
                                      selectedBankID == bank.bankId)
                                  ? MonaColors.primaryBlue
                                  : MonaColors.bgGrey,
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: context.w(6),
                              backgroundColor:
                                  (sdkNotifier.selectedPaymentMethod ==
                                              PaymentMethod.savedBank &&
                                          selectedBankID == bank.bankId)
                                      ? MonaColors.primaryBlue
                                      : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],

              Column(
                children: PaymentMethod.values.map(
                  (paymentMethod) {
                    if (paymentMethod == PaymentMethod.none) {
                      return const SizedBox.shrink();
                    }
                    if (paymentMethod == PaymentMethod.savedBank) {
                      return const SizedBox.shrink();
                    }
                    if (paymentMethod == PaymentMethod.savedCard) {
                      return const SizedBox.shrink();
                    }

                    return PaymentOptionTile(
                      onTap: () {
                        sdkNotifier.setSelectedPaymentMethod(
                          method: paymentMethod,
                        );
                      },
                      selectedPaymentMethod: sdkNotifier.selectedPaymentMethod,
                      paymentMethod: paymentMethod,
                    );
                  },
                ).toList(),
              ),

              context.sbH(16.0),

              ///
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: switch (sdkNotifier.state == MonaSDKState.loading) {
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
                          backgroundColor: sdkNotifier.selectedPaymentMethod ==
                                  PaymentMethod.none
                              ? MonaColors.primaryBlue.withAlpha(100)
                              : MonaColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () async {
                          sdkNotifier
                            ..setCallingBuildContext(context: context)
                            ..makePayment();
                        },
                        child: switch ([
                          PaymentMethod.none,
                          PaymentMethod.card,
                          PaymentMethod.transfer
                        ].contains(sdkNotifier.selectedPaymentMethod)) {
                          true => Text(
                              "Proceed to Pay",
                              style: TextStyle(
                                fontSize: context.sp(14),
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          false => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "OneTap   |   ",
                                  style: TextStyle(
                                    fontSize: context.sp(14),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                //!
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: MonaColors.primaryBlue,
                                  backgroundImage: switch (
                                      sdkNotifier.selectedPaymentMethod ==
                                          PaymentMethod.savedBank) {
                                    true => NetworkImage(
                                        sdkNotifier.selectedBankOption?.logo ??
                                            "",
                                      ),
                                    false => NetworkImage(
                                        sdkNotifier.selectedCardOption?.logo ??
                                            "",
                                      ),
                                  },
                                ),

                                //!
                                Text(
                                  switch (sdkNotifier.selectedPaymentMethod ==
                                      PaymentMethod.savedBank) {
                                    true =>
                                      "  ${sdkNotifier.selectedBankOption?.accountNumber}",
                                    false =>
                                      "  ${sdkNotifier.selectedCardOption?.accountNumber}",
                                  },
                                  style: TextStyle(
                                    fontSize: context.sp(14),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              ],
                            ),
                        },
                      ),
                    )
                },
              ),

              context.sbH(16),

              Center(
                child: TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);

                    sdkNotifier.invalidate();
                    await AuthService.singleInstance.permanentlyClearKeys();

                    navigator.pop();
                  },
                  child: Text(
                    "Clear Exchange Keys",
                    style: TextStyle(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              context.sbH(16),
            ],
          ),
        ),
      ),
    );
  }
}
