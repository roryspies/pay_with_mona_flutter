import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/core/events/auth_state_stream.dart';
import 'package:pay_with_mona/src/core/events/mona_sdk_state_stream.dart';
import 'package:pay_with_mona/src/core/events/transaction_state_stream.dart';
import 'package:pay_with_mona/src/core/services/auth_service.dart';
import 'package:pay_with_mona/src/features/payments/controller/notifier_enums.dart';
import 'package:pay_with_mona/src/features/payments/controller/payment_notifier.dart';
import 'package:pay_with_mona/src/models/mona_checkout.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
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
  final paymentNotifier = PaymentNotifier();

  @override
  void initState() {
    super.initState();
    paymentNotifier.addListener(_onPaymentStateChange);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await paymentNotifier.initiatePayment();
        paymentNotifier
          ..txnStateStream.listen(
            (state) {
              switch (state) {
                case TransactionState.initiated:
                  ('🎉  PayWithMonaWidget ==>>  Transaction started').log();
                  break;
                case TransactionState.completed:
                  ('✅ PayWithMonaWidget ==>>  Transaction completed').log();
                  break;
                case TransactionState.failed:
                  ('⛔  PayWithMonaWidget ==>> Transaction failed').log();
                  break;
              }
            },
            onError: (err) {
              ('Error from transactionStateStream: $err').log();
            },
          )
          ..sdkStateStream.listen(
            (state) {
              switch (state) {
                case MonaSDKState.idle:
                  ('🎉  PayWithMonaWidget ==>> SDK is Idle').log();
                  break;
                case MonaSDKState.loading:
                  ('🔄 PayWithMonaWidget ==>>  SDK is Loading').log();
                  break;
                case MonaSDKState.error:
                  ('⛔  PayWithMonaWidget ==>> SDK Has Errors').log();
                  break;
                case MonaSDKState.success:
                  ('👍  PayWithMonaWidget ==>> SDK is in Success state').log();
                  break;
              }
            },
            onError: (err) {
              ('Error from transactionStateStream: $err').log();
            },
          )
          ..authStateStream.listen(
            (state) {
              switch (state) {
                case AuthState.loggedIn:
                  ('🎉  PayWithMonaWidget ==>>  Auth State Logged In').log();
                  break;
                case AuthState.loggedOut:
                  ('👀 PayWithMonaWidget ==>>  Auth State Logged Out').log();
                  break;
                case AuthState.error:
                  ('⛔  PayWithMonaWidget ==>> Auth Has Error').log();
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
  void dispose() {
    /// *** Considering we're using a singleton class for Payment Notifier
    /// *** Do not dispose the Notifier itself, so that instance isn't gone with the wind.
    paymentNotifier.removeListener(_onPaymentStateChange);
    super.dispose();
  }

  /// *** Rebuild UI when state changes
  void _onPaymentStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    "PayWithMonaWidget BUILD CALLED".log();

    final savedBanks =
        paymentNotifier.currentPaymentResponseModel?.savedPaymentOptions?.bank;
    final savedCards =
        paymentNotifier.currentPaymentResponseModel?.savedPaymentOptions?.card;

    return Container(
      padding: EdgeInsets.all(context.w(16)),
      width: double.infinity,
      decoration: BoxDecoration(
        color: MonaColors.neutralWhite,
      ),
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
                      paymentNotifier.selectedCardOption?.cardId;

                  return ListTile(
                    onTap: () {
                      paymentNotifier.setSelectedPaymentMethod(
                        method: PaymentMethod.card,
                      );

                      paymentNotifier.setSelectedCardOption(
                        cardOption: card,
                      );
                    },

                    /// ***
                    contentPadding: EdgeInsets.zero,
                    /* leading: CircleAvatar(
                      backgroundColor: MonaColors.neutralWhite,
                      child: Image.network(
                        card.cardId  ?? "",
                      ),
                    ), */

                    title: Text(
                      card.cardNetwork ?? "",
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w500,
                        color: MonaColors.textHeading,
                      ),
                    ),

                    subtitle: Text(
                      "Account - ${card.maskedPan}",
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
                          color: (paymentNotifier.selectedPaymentMethod ==
                                      PaymentMethod.savedBank &&
                                  selectedCardID == card.cardId)
                              ? MonaColors.primaryBlue
                              : MonaColors.bgGrey,
                        ),
                      ),
                      child: Center(
                        child: CircleAvatar(
                          radius: context.w(6),
                          backgroundColor:
                              (paymentNotifier.selectedPaymentMethod ==
                                          PaymentMethod.savedBank &&
                                      selectedCardID == card.cardId)
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
                      paymentNotifier.selectedBankOption?.bankId;

                  "Selected Bank ID: $selectedBankID";

                  return ListTile(
                    onTap: () {
                      paymentNotifier.setSelectedPaymentMethod(
                        method: PaymentMethod.savedBank,
                      );

                      paymentNotifier.setSelectedBankOption(
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
                          color: (paymentNotifier.selectedPaymentMethod ==
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
                              (paymentNotifier.selectedPaymentMethod ==
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
                    paymentNotifier.setSelectedPaymentMethod(
                      method: paymentMethod,
                    );
                  },
                  selectedPaymentMethod: paymentNotifier.selectedPaymentMethod,
                  paymentMethod: paymentMethod,
                );
              },
            ).toList(),
          ),

          context.sbH(16.0),

          ///
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: switch (paymentNotifier.state == MonaSDKState.loading) {
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
                      backgroundColor: paymentNotifier.selectedPaymentMethod ==
                              PaymentMethod.none
                          ? MonaColors.primaryBlue.withAlpha(100)
                          : MonaColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () async {
                      paymentNotifier
                        ..setCallingBuildContext(context: context)
                        ..setMonaCheckOut(checkoutDetails: widget.monaCheckOut)
                        ..makePayment();
                    },
                    child: Text(
                      "Proceed to pay ",
                      style: TextStyle(
                        fontSize: context.sp(14),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
            },
          ),

          context.sbH(16),

          Center(
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.singleInstance.clearKeys();
              },
              child: Text(
                "Clear Exchange Keys",
                style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
