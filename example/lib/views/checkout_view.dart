// ignore_for_file: use_build_context_synchronously
import 'package:example/services/customer_details_notifier.dart';
import 'package:example/services/transaction_state_notifier.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/responsive_scaffold.dart';
import 'package:example/utils/size_config.dart';
import 'package:example/views/result_view.dart';
import 'package:example/views/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({
    super.key,
    required this.transactionId,
    required this.amount,
  });

  final String transactionId;
  final num amount;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  late PayWithMona _payWithMona;
  final sdkNotifier = MonaSDKNotifier();
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();

  @override
  void initState() {
    super.initState();
    _payWithMona = PayWithMona.instance;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        // bool isPaymentStatusModalOpen = false;
        sdkNotifier
          ..txnStateStream.listen(
            (state) async {
              ref.read(transactionStatusProvider.notifier).updateState(
                    newState: state,
                  );

              switch (state) {
                case TransactionStateFailed(
                    :final reason,
                    :final transactionID,
                    :final amount,
                  ):
                  ("CheckoutView ❌ Failed: $reason (tx=$transactionID, amount=$amount)")
                      .log();
                  break;

                case TransactionStateCompleted(
                    :final transactionID,
                    :final amount,
                  ):
                  ("CheckoutView ✅ Completed: tx=$transactionID, amount=$amount")
                      .log();
                  break;

                case TransactionStateInitiated(
                    :final transactionID,
                    :final amount,
                  ):
                  ("CheckoutView 🚀 Initiated: tx=$transactionID, amount=$amount")
                      .log();

                  /* if (isPaymentStatusModalOpen == false) {
                    isPaymentStatusModalOpen = true;

                    AppUtils.showAppModalBottomSheet(
                      isDismissible: false,
                      enableDrag: false,
                      callingContext: context,
                      child: PaymentStatusModal(),
                    );
                  } */

                  break;

                case TransactionStateRequestOTPTask(:final task):
                  ("CheckoutView 🔑 Need OTP: ${task.taskDescription}").log();
                  await AppUtils.showOTPModal(
                    context,
                    (String pinOrOTP) {
                      "CheckoutView ::: TransactionStateRequestOTPTask ::: returned value ::: $pinOrOTP"
                          .log();

                      sdkNotifier.sendOTPToServer(pinOrOTP: pinOrOTP);
                    },
                    controller: _otpPinFieldController,
                    task: state,
                  );
                  break;

                case TransactionStateRequestPINTask(:final task):
                  ("CheckoutView 🔒 Need PIN: ${task.fieldName}").log();
                  break;

                case TransactionStateNavToResult():
                  ("TransactionStateNavToResult … waiting …").log();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return ResultView();
                      },
                    ),
                  );
                  break;

                case TransactionStateIdle():
                  ("CheckoutView … waiting …").log();
                  break;

                default:
                  ("CheckoutView … default ::: $state").log();

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
                case MonaSDKState.idle:
                  ('🎉  CheckoutView ==>> SDK is Idle').log();
                  break;
                case MonaSDKState.loading:
                  ('🔄 CheckoutView ==>>  SDK is Loading').log();
                  break;
                case MonaSDKState.error:
                  ('⛔  CheckoutView ==>> SDK Has Errors').log();
                  break;
                case MonaSDKState.success:
                  ('👍  CheckoutView ==>> SDK is in Success state').log();
                  break;
                case MonaSDKState.transactionInitiated:
                  ('🏫  CheckoutView ==>> SDK is in Success state').log();
                  //07078943673
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
                  ('🎉  CheckoutView ==>>  Auth State Logged In').log();
                  break;
                case AuthState.loggedOut:
                  ('👀 CheckoutView ==>>  Auth State Logged Out').log();
                  break;
                case AuthState.error:
                  ('⛔ CheckoutView ==>> Auth Has Error').log();
                  break;
                case AuthState.notAMonaUser:
                  ('👤 CheckoutView ==>> Auth is Not A Mona User').log();
                  break;
                case AuthState.performingLogin:
                  ('🚴‍♀️ CheckoutView ==>> Currently Doing Login with Strong Auth token')
                      .log();
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
    return ResponsiveScaffold(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
        ),
        backgroundColor: MonaColors.bgGrey,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(context.w(20)),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MonaColors.neutralWhite,
                ),
                child: Column(
                  spacing: context.h(32),
                  children: [
                    Text(
                      "Payment Summary",
                      style: TextStyle(
                        fontSize: context.sp(16),
                        fontWeight: FontWeight.w500,
                        color: MonaColors.textHeading,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textHeading,
                          ),
                        ),
                        Text(
                          "₦${AppUtils.formatMoney(double.parse(widget.amount.toString()))}",
                          style: TextStyle(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w500,
                            color: MonaColors.textHeading,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              context.sbH(8),

              /// *** Main Pay Widget
              _payWithMona.payWidget(
                context: context,
                checkoutPayload: MonaCheckOut(
                  firstName: '',
                  lastName: '',
                  dateOfBirth: DateTime.now(),
                  transactionId: widget.transactionId,
                  merchantName: 'NGDeals',
                  primaryColor: Colors.purple,
                  secondaryColor: Colors.indigo,
                  phoneNumber:
                      ref.watch(customerDetailsNotifierProvider).phoneNumber,
                  amount: widget.amount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
