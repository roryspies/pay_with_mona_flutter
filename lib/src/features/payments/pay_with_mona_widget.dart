// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/notifier_enums.dart';
import 'package:pay_with_mona/src/core/sdk_notifier/sdk_notifier.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:pay_with_mona/src/widgets/confirm_transaction_modal.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/src/widgets/payment_option_tile.dart';

class PayWithMonaWidget extends StatefulWidget {
  const PayWithMonaWidget({
    super.key,
    //required this.monaCheckOut,
    required this.callingContext,
  });

  final BuildContext callingContext;

  @override
  State<PayWithMonaWidget> createState() => _PayWithMonaWidgetState();
}

class _PayWithMonaWidgetState extends State<PayWithMonaWidget> {
  final sdkNotifier = MonaSDKNotifier();

  @override
  void initState() {
    super.initState();
    sdkNotifier.addListener(_onSDKStateChanged);
  }

  @override
  void dispose() {
    /// *** Considering we're using a singleton class for Payment Notifier
    /// *** Do not dispose the Notifier itself, so that instance isn't gone with the wind.
    sdkNotifier.removeListener(_onSDKStateChanged);
    super.dispose();
  }

  /// *** Rebuild UI when state changes
  void _onSDKStateChanged() => mounted ? setState(() {}) : null;

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

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16.0,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 21.0,
                              backgroundColor: MonaColors.neutralWhite,
                              child: Stack(
                                children: [
                                  //!
                                  Align(
                                    alignment: Alignment.center,
                                    child: CircleAvatar(
                                      backgroundColor: MonaColors.neutralWhite,
                                      child: Image.network(
                                        card.logo ?? "",
                                      ),
                                    ),
                                  ),

                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: CircleAvatar(
                                      radius: 7.0,
                                      backgroundColor: Colors.white,
                                      child: SvgPicture.asset(
                                        "tiny_card_icon".svg,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),

                            context.sbW(16.0),

                            ///
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.bankName ?? "",
                                    style: TextStyle(
                                      fontSize: context.sp(14),
                                      fontWeight: FontWeight.w500,
                                      color: MonaColors.textHeading,
                                    ),
                                  ),
                                  Text(
                                    "Card - ${card.accountNumber}",
                                    style: TextStyle(
                                      fontSize: context.sp(12),
                                      fontWeight: FontWeight.w400,
                                      color: MonaColors.textBody,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ///
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: context.h(24),
                              width: context.w(24),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(context.h(24)),
                                border: Border.all(
                                  width: 1.5,
                                  color: (sdkNotifier.selectedPaymentMethod ==
                                              PaymentMethod.savedBank &&
                                          selectedCardID == card.bankId)
                                      ? (sdkNotifier.merchantBrandingDetails
                                              ?.colors.primaryColour ??
                                          MonaColors.primaryBlue)
                                      : MonaColors.bgGrey,
                                ),
                              ),
                              child: Center(
                                child: CircleAvatar(
                                  radius: context.w(6),
                                  backgroundColor:
                                      (sdkNotifier.selectedPaymentMethod ==
                                                  PaymentMethod.savedBank &&
                                              selectedCardID == card.bankId)
                                          ? (sdkNotifier.merchantBrandingDetails
                                                  ?.colors.primaryColour ??
                                              MonaColors.primaryBlue)
                                          : Colors.transparent,
                                ),
                              ),
                            ),
                          ],
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

                      if (bank.activeIn != null && bank.activeIn! > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16.0,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 21.0,
                                backgroundColor: MonaColors.neutralWhite,
                                child: Stack(
                                  children: [
                                    //!
                                    Align(
                                      alignment: Alignment.center,
                                      child: CircleAvatar(
                                        backgroundColor:
                                            MonaColors.neutralWhite,
                                        child: Image.network(
                                          bank.logo ?? "",
                                        ),
                                      ),
                                    ),

                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: CircleAvatar(
                                        radius: 7.0,
                                        backgroundColor: Colors.white,
                                        child: SvgPicture.asset(
                                          "tiny_bank_icon".svg,
                                        ),
                                        /* backgroundImage: AssetImage(
                                          "tiny_bank_icon".svg,
                                        ), */
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              context.sbW(16.0),

                              ///
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bank.bankName ?? "",
                                      style: TextStyle(
                                        fontSize: context.sp(14),
                                        fontWeight: FontWeight.w500,
                                        color: MonaColors.textHeading,
                                      ),
                                    ),
                                    Text(
                                      "Account - ${bank.accountNumber}",
                                      style: TextStyle(
                                        fontSize: context.sp(12),
                                        fontWeight: FontWeight.w400,
                                        color: MonaColors.textBody,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ///
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 8.0,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(context.h(8)),
                                    color: Color(
                                      0xFFE7E8E6,
                                    )),
                                child: Text(
                                  "Active in ${bank.activeIn} hours",
                                  style: TextStyle(
                                    fontSize: context.sp(12),
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFC6C7C3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () {
                          sdkNotifier.setSelectedPaymentMethod(
                            method: PaymentMethod.savedBank,
                          );

                          sdkNotifier.setSelectedBankOption(
                            bankOption: bank,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16.0,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 21.0,
                                backgroundColor: MonaColors.neutralWhite,
                                child: Stack(
                                  children: [
                                    //!
                                    Align(
                                      alignment: Alignment.center,
                                      child: CircleAvatar(
                                        backgroundColor:
                                            MonaColors.neutralWhite,
                                        child: Image.network(
                                          bank.logo ?? "",
                                        ),
                                      ),
                                    ),

                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: CircleAvatar(
                                        radius: 7.0,
                                        backgroundColor: Colors.white,
                                        child: SvgPicture.asset(
                                          "tiny_bank_icon".svg,
                                        ),
                                        /* backgroundImage: AssetImage(
                                          "tiny_bank_icon".svg,
                                        ), */
                                      ),
                                    )
                                  ],
                                ),
                              ),

                              context.sbW(16.0),

                              ///
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bank.bankName ?? "",
                                      style: TextStyle(
                                        fontSize: context.sp(14),
                                        fontWeight: FontWeight.w500,
                                        color: MonaColors.textHeading,
                                      ),
                                    ),
                                    Text(
                                      "Account - ${bank.accountNumber}",
                                      style: TextStyle(
                                        fontSize: context.sp(12),
                                        fontWeight: FontWeight.w400,
                                        color: MonaColors.textBody,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ///
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                height: context.h(24),
                                width: context.w(24),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(context.h(24)),
                                  border: Border.all(
                                    width: 1.5,
                                    color: (sdkNotifier.selectedPaymentMethod ==
                                                PaymentMethod.savedBank &&
                                            selectedBankID == bank.bankId)
                                        ? (sdkNotifier.merchantBrandingDetails
                                                ?.colors.primaryColour ??
                                            MonaColors.primaryBlue)
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
                                            ? (sdkNotifier
                                                    .merchantBrandingDetails
                                                    ?.colors
                                                    .primaryColour ??
                                                MonaColors.primaryBlue)
                                            : Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
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
                      iconURL: paymentMethod.paymentOptionIconURL,
                      selectedPaymentMethod: sdkNotifier.selectedPaymentMethod,
                      paymentMethod: paymentMethod,
                    );
                  },
                ).toList(),
              ),

              InkWell(
                onTap: () async {
                  await sdkNotifier.addBankAccountForCheckout();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: (sdkNotifier.merchantBrandingDetails
                                  ?.colors.primaryColour ??
                              MonaColors.primaryBlue)
                          .withOpacity(
                        0.05,
                      ),
                      child: SvgPicture.asset(
                        "add_payment_option_button".svg,
                      ),
                    ),

                    ///
                    context.sbW(16.0),

                    ///
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add a payment option",
                            style: TextStyle(
                              fontSize: context.sp(14),
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "Add a bank account or card to pay with",
                            style: TextStyle(
                              fontSize: context.sp(12),
                              fontWeight: FontWeight.w400,
                              color: MonaColors.hint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              context.sbH(16.0),

              ///
              CustomButton(
                label: "",
                isLoading: sdkNotifier.state == MonaSDKState.loading,
                color: (sdkNotifier.selectedPaymentMethod == PaymentMethod.none)
                    ? (sdkNotifier.merchantBrandingDetails?.colors
                                .primaryColour ??
                            MonaColors.primaryBlue)
                        .withAlpha(100)
                    : (sdkNotifier
                            .merchantBrandingDetails?.colors.primaryColour ??
                        MonaColors.primaryBlue),
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
                          backgroundColor: (sdkNotifier.merchantBrandingDetails
                                  ?.colors.primaryColour ??
                              MonaColors.primaryBlue),
                          backgroundImage: switch (
                              sdkNotifier.selectedPaymentMethod ==
                                  PaymentMethod.savedBank) {
                            true => NetworkImage(
                                sdkNotifier.selectedBankOption?.logo ?? "",
                              ),
                            false => NetworkImage(
                                sdkNotifier.selectedCardOption?.logo ?? "",
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
                onTap: () async {
                  if (sdkNotifier.selectedPaymentMethod == PaymentMethod.none) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please select a payment method",
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  if (sdkNotifier.monaCheckout == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Please update Mona Checkout Details",
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final isSavedMethods = [
                    PaymentMethod.savedBank,
                    PaymentMethod.savedCard,
                  ].contains(sdkNotifier.selectedPaymentMethod);

                  if (await sdkNotifier.checkIfUserHasKeyID() != null &&
                      isSavedMethods) {
                    await SDKUtils.showSDKModalBottomSheet(
                      isDismissible: false,
                      enableDrag: false,
                      callingContext: context,
                      child: ConfirmTransactionModal(
                        selectedPaymentMethod:
                            sdkNotifier.selectedPaymentMethod,
                        transactionAmountInKobo:
                            sdkNotifier.monaCheckout!.amount!,
                        onPay: () {
                          sdkNotifier
                              //..setCallingBuildContext(context: context)
                              .makePayment();
                        },
                      ),
                    );
                    return;
                  }

                  sdkNotifier
                      //..setCallingBuildContext(context: context)
                      .makePayment();
                },
              ),

              context.sbH(16),
            ],
          ),
        ),
      ).ignorePointer(
        isLoading: sdkNotifier.state == MonaSDKState.loading,
      ),
    );
  }
}
