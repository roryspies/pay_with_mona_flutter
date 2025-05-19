// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/utils/size_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/src/widgets/flowing_progress_bar.dart';

class SdkPaymentStatusModal extends StatefulWidget {
  const SdkPaymentStatusModal({super.key});

  @override
  State<SdkPaymentStatusModal> createState() => _SdkPaymentStatusModalState();
}

class _SdkPaymentStatusModalState extends State<SdkPaymentStatusModal>
    with TickerProviderStateMixin {
  final sdkNotifier = MonaSDKNotifier();

  // Animation controllers for progress bars
  late AnimationController _firstProgressController;
  late AnimationController _secondProgressController;
  late AnimationController _thirdProgressController;

  // Animation for color transitions
  late Animation<Color?> _firstProgressColorAnimation;
  late Animation<Color?> _secondProgressColorAnimation;
  late Animation<Color?> _thirdProgressColorAnimation;

  // Flow animation for the middle bar
  late AnimationController _flowAnimationController;
  late Animation<double> _flowAnimation;

  bool showPaymentSuccessfulOrFailed = false;
  bool isPaymentSuccessful = false;

  // Track current payment stage
  int _currentStage = 0; // 0: not started, 1: sent, 2: received
  num _transactionAmount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _firstProgressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _secondProgressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _thirdProgressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Flow animation for the middle bar (repeating shader effect)
    _flowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _flowAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(_flowAnimationController);

    // Color transitions from light green to dark green
    _firstProgressColorAnimation = ColorTween(
      begin: MonaColors.successColour.withOpacity(0.1),
      end: MonaColors.successColour,
    ).animate(_firstProgressController);

    _secondProgressColorAnimation = ColorTween(
      begin: MonaColors.successColour.withOpacity(0.1),
      end: MonaColors.successColour,
    ).animate(_secondProgressController);

    _thirdProgressColorAnimation = ColorTween(
      begin: MonaColors.successColour.withOpacity(0.1),
      end: MonaColors.successColour,
    ).animate(_thirdProgressController);

    // Set up listeners to update UI when animations run
    _firstProgressController.addListener(() {
      setState(() {});
    });

    _secondProgressController.addListener(() {
      setState(() {});
    });

    _thirdProgressController.addListener(() {
      setState(() {});
    });

    _flowAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flowAnimationController.repeat();
      }
    });

    // When first animation completes, update stage and start flow animation
    _firstProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentStage = 1; // Sent stage
        });
        // Start the flow animation for the middle bar
        _flowAnimationController.forward();
      }
    });

    // When second animation completes, update stage and stop flow animation
    _secondProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentStage = 2;
        });
        // Stop flowing animation
        _flowAnimationController.stop();
      }
    });

    // Start initial animation sequence automatically
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _firstProgressController.forward();

        // Listen for transaction state changes
        sdkNotifier.txnStateStream.listen(
          (state) async {
            switch (state) {
              case TransactionStateFailed(
                  :final reason,
                  :final transactionID,
                  :final amount,
                ):
                ("SdkPaymentStatusModal ❌ Failed: $reason (tx=$transactionID, amount=$amount)")
                    .log();

                _transactionAmount = amount != null ? (amount / 100) : 0;
                _completeAllAnimations(
                  isCompletedTransaction: false,
                );
                break;

              case TransactionStateCompleted(
                  :final transactionID,
                  :final amount,
                ):
                ("SdkPaymentStatusModal ✅ Completed: tx=$transactionID, amount=$amount)")
                    .log();

                _transactionAmount = amount != null ? (amount / 100) : 0;
                isPaymentSuccessful = true;
                _completeAllAnimations();
                break;

              case TransactionStateInitiated(
                  :final transactionID,
                  :final amount,
                ):
                ("SdkPaymentStatusModal 🚀 Initiated: tx=$transactionID, amount=$amount)")
                    .log();

                _transactionAmount = amount != null ? (amount / 100) : 0;
                // Start first animation
                //_startFirstAnimation();
                break;

              default:
                ("SdkPaymentStatusModal … default ::: $state").log();
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

  void _resetAnimations() {
    _firstProgressController.reset();
    _secondProgressController.reset();
    _thirdProgressController.reset();
    _flowAnimationController.reset();
    setState(() {
      _currentStage = 0;
    });
  }

  void _completeAllAnimations({
    bool isCompletedTransaction = true,
  }) async {
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        setState(() => _currentStage = 1);

        _secondProgressController.forward(
          from: _secondProgressController.value,
        );

        Future.delayed(
          const Duration(milliseconds: 1500),
          () async {
            setState(() {
              _currentStage = 2;
            });

            _thirdProgressController.forward(
              from: _thirdProgressController.value,
            );

            await Future.delayed(Duration(milliseconds: 1500));

            showPaymentSuccessfulOrFailed = true;

            await Future.delayed(Duration(milliseconds: 1500));

            if (isCompletedTransaction) {
              sdkNotifier.handleNavToConfirmationScreen();
              /* await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return ResultView();
                  },
                ),
              ); */

              return;
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _firstProgressController.dispose();
    _secondProgressController.dispose();
    _thirdProgressController.dispose();
    _flowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MonaColors.bgGrey,
        borderRadius: BorderRadius.circular(
          8.0,
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MonaColors.neutralWhite,
              borderRadius: BorderRadius.circular(
                8.0,
              ),
            ),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: switch (showPaymentSuccessfulOrFailed) {
                true => Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.transparent,
                        child: SvgPicture.asset(
                          switch (isPaymentSuccessful) {
                            true => "sdk_transaction_successful_icon",
                            false => "sdk_transaction_failed_icon",
                          }
                              .svg,
                        ),
                      ),

                      context.sbH(8),

                      ///
                      Text(
                        isPaymentSuccessful
                            ? "Payment Successful!"
                            : "Payment Failed!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      context.sbH(8),

                      Text(
                        isPaymentSuccessful
                            ? "Your payment of ₦$_transactionAmount was successful. Mona has sent you a transaction receipt!"
                            : "Your payment of ₦$_transactionAmount failed!. Please try again or use a different payment method.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: MonaColors.textBody,
                        ),
                      ),

                      context.sbH(8),

                      CustomButton(
                        label: isPaymentSuccessful ? "Return" : "Try Again",
                        onTap: () {
                          if (isPaymentSuccessful == false) {
                            _resetAnimations();
                            sdkNotifier.resetSDKState(
                              clearMonaCheckout: false,
                              clearPendingPaymentResponseModel: false,
                            );
                            Navigator.of(context).pop();
                            return;
                          }

                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  ),

                /// *** Default
                false => Column(
                    children: [
                      ///
                      Text(
                        "Hang Tight, We're On It!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: MonaColors.textHeading,
                        ),
                      ),

                      context.sbH(8),

                      Text(
                        "Your transfer is on the way—we'll confirm as soon as it lands.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: MonaColors.textBody,
                        ),
                      ),

                      context.sbH(8),

                      Row(
                        children: [
                          Expanded(
                            child: AnimatedProgressBar(
                              isCurrentStage: _currentStage >= 0,
                              colorAnimation: _firstProgressColorAnimation,
                              controller: _firstProgressController,
                            ),
                          ),

                          ///
                          context.sbW(4),

                          // Sent icon
                          PaymentStageWidget(
                            isCurrentStage: _currentStage >= 1,
                            stageText: "Sent",
                          ),

                          context.sbW(4),

                          Expanded(
                            flex: 3,
                            child: _currentStage == 1
                                ? FlowingProgressBar(
                                    flowAnimation: _flowAnimation,
                                    baseColor: MonaColors.successColour
                                        .withOpacity(0.1),
                                    flowColor: MonaColors.successColour,
                                  )
                                : AnimatedProgressBar(
                                    isCurrentStage: _currentStage >= 1,
                                    colorAnimation:
                                        _secondProgressColorAnimation,
                                    controller: _secondProgressController,
                                  ),
                          ),

                          context.sbW(4),

                          PaymentStageWidget(
                            isCurrentStage: _currentStage >= 2,
                            stageText: "Received",
                          ),

                          context.sbW(4),

                          Expanded(
                            child: AnimatedProgressBar(
                              isCurrentStage: _currentStage >= 2,
                              colorAnimation: _thirdProgressColorAnimation,
                              controller: _thirdProgressController,
                            ),
                          ),
                        ],
                      ),

                      context.sbH(8),
                    ],
                  ),
              },
            ),
          ),

          ///
          context.sbH(8),

          ///
          SecuredByMona(),
        ],
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.isCurrentStage,
    required this.colorAnimation,
    required this.controller,
  });

  final bool isCurrentStage;
  final Animation<Color?> colorAnimation;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: MonaColors.successColour.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Animated foreground bar
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: isCurrentStage ? controller.value : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorAnimation.value,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PaymentStageWidget extends StatelessWidget {
  const PaymentStageWidget({
    super.key,
    required this.isCurrentStage,
    required this.stageText,
  });

  final bool isCurrentStage;
  final String stageText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          context.sbH(16),
          CircleAvatar(
            radius: 12,
            backgroundColor: isCurrentStage
                ? MonaColors.successColour
                : MonaColors.successColour.withOpacity(0.2),
            child: AnimatedSwitcher(
              duration: Duration(
                milliseconds: 300,
              ),
              child: isCurrentStage
                  ? SvgPicture.asset(
                      "mona_tick".svg,
                      height: 12,
                    )
                  : null,
            ),
          ),

          //
          context.sbH(4),

          //
          Text(
            stageText,
            style: TextStyle(
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }
}
