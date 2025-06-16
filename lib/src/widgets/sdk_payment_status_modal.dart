// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/widgets/flowing_progress_bar.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/sdk_utils.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';

class SdkPaymentStatusModal extends StatefulWidget {
  const SdkPaymentStatusModal({super.key});

  @override
  State<SdkPaymentStatusModal> createState() => _SdkPaymentStatusModalState();
}

class _SdkPaymentStatusModalState extends State<SdkPaymentStatusModal>
    with TickerProviderStateMixin {
  final sdkNotifier = MonaSDKNotifier();

  late AnimationController _firstProgressController;
  late AnimationController _secondProgressController;
  late AnimationController _thirdProgressController;

  late Animation<Color?> _firstProgressColorAnimation;
  late Animation<Color?> _secondProgressColorAnimation;
  late Animation<Color?> _thirdProgressColorAnimation;

  bool showPaymentSuccessfulOrFailed = false;
  bool? isPaymentSuccessful;

  int _currentStage = 0;
  num _transactionAmount = 0;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _setupListeners();

    // Start the mock transaction flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstProgressController.forward();
      //sdkNotifier.simulateTransaction();
    });
  }

  void _setupControllers() {
    _firstProgressController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _secondProgressController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _thirdProgressController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
  }

  void _setupAnimations() {
    _firstProgressColorAnimation = ColorTween(
      begin: MonaColors.successColour.withOpacity(0.1),
      end: MonaColors.successColour,
    ).animate(_firstProgressController);

    // We must update the color tween when the payment status changes
    _updateProgressColorAnimations();
  }

  void _updateProgressColorAnimations() {
    final bool success = isPaymentSuccessful ?? true;
    final Color startColor =
        (success ? MonaColors.successColour : MonaColors.errorColour)
            .withOpacity(0.1);
    final Color endColor =
        success ? MonaColors.successColour : MonaColors.errorColour;

    _secondProgressColorAnimation = ColorTween(begin: startColor, end: endColor)
        .animate(_secondProgressController);
    _thirdProgressColorAnimation = ColorTween(begin: startColor, end: endColor)
        .animate(_thirdProgressController);
  }

  void _setupListeners() {
    _firstProgressController.addListener(() => setState(() {}));
    _secondProgressController.addListener(() => setState(() {}));
    _thirdProgressController.addListener(() => setState(() {}));

    _firstProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _currentStage = 1);
      }
    });

    _secondProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _currentStage = 2);
      }
    });

    sdkNotifier.txnStateStream.listen((state) async {
      switch (state) {
        case TransactionStateFailed(:final amount):
          if (!mounted) return;
          setState(() {
            _transactionAmount = amount ?? 0;
            isPaymentSuccessful = false;
            _updateProgressColorAnimations();
          });
          _completeAllAnimations(isCompletedTransaction: false);
          break;
        case TransactionStateCompleted(:final amount):
          if (!mounted) return;
          setState(() {
            _transactionAmount = amount ?? 0;
            isPaymentSuccessful = true;
            _updateProgressColorAnimations();
          });
          _completeAllAnimations();
          break;
        case TransactionStateInitiated(:final amount):
          if (!mounted) return;
          setState(() => _transactionAmount = amount ?? 0);
          break;
        default:
          break;
      }
    });
  }

  void _resetAnimations() {
    _firstProgressController.reset();
    _secondProgressController.reset();
    _thirdProgressController.reset();
    if (mounted) {
      setState(() => _currentStage = 0);
    }
  }

  void _completeAllAnimations({bool isCompletedTransaction = true}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _secondProgressController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _thirdProgressController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => showPaymentSuccessfulOrFailed = true);

    await Future.delayed(const Duration(seconds: 2));
    if (isCompletedTransaction) {
      sdkNotifier.handleNavToConfirmationScreen();
    }
  }

  @override
  void dispose() {
    _firstProgressController.dispose();
    _secondProgressController.dispose();
    _thirdProgressController.dispose();
    sdkNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MonaColors.neutralWhite,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: showPaymentSuccessfulOrFailed
                  ? _buildStatusResult()
                  : _buildProgressTracker(),
            ),
          ),
          const SecuredByMona(),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    // This is the core of the alignment fix.
    // By using CrossAxisAlignment.start and Padding, we can align
    // the progress bars with the vertical center of the circles.
    const double circleRadius = 12.0;
    const double lineWidth = 8.0;
    const double verticalPadding = circleRadius - (lineWidth / 2);

    return Column(
      key: const ValueKey('tracker'),
      children: [
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
        context.sbH(16), // Increased spacing for better look
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // KEY FIX 1
          children: [
            Expanded(
              // Bar 1
              flex: 1,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: verticalPadding), // KEY FIX 2
                child: AnimatedProgressBar(
                  isCurrentStage: _currentStage >= 0,
                  colorAnimation: _firstProgressColorAnimation,
                  controller: _firstProgressController,
                  isFirst: true, // For rounded cap
                ),
              ),
            ),

            // Step 1: Sent
            PaymentStageWidget(
              isPaymentSuccessful: true, // First step is always 'successful'
              isCurrentStage: _currentStage >= 1,
              stageText: "Sent",
            ),

            Expanded(
              // Bar 2
              flex: 2, // Make middle bar longer
              child: Padding(
                padding:
                    const EdgeInsets.only(top: verticalPadding), // KEY FIX 2
                child: _currentStage == 1 &&
                        (isPaymentSuccessful == null ||
                            isPaymentSuccessful == true)
                    ? FlowingProgressBar(
                        // The cool flowing animation
                        baseColor: MonaColors.successColour.withOpacity(0.1),
                        flowColor: MonaColors.successColour,
                      )
                    : AnimatedProgressBar(
                        isCurrentStage: _currentStage >= 1,
                        colorAnimation: _secondProgressColorAnimation,
                        controller: _secondProgressController,
                      ),
              ),
            ),

            // Step 2: Received
            PaymentStageWidget(
              isPaymentSuccessful: isPaymentSuccessful,
              isCurrentStage: _currentStage >= 2,
              stageText: "Received",
            ),

            Expanded(
              // Bar 3
              flex: 1,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: verticalPadding), // KEY FIX 2
                child: AnimatedProgressBar(
                  isCurrentStage: _currentStage >= 2,
                  colorAnimation: _thirdProgressColorAnimation,
                  controller: _thirdProgressController,
                  isLast: true, // For rounded cap
                ),
              ),
            ),
          ],
        ),
        context.sbH(8),
      ],
    );
  }

  Widget _buildStatusResult() {
    final bool success = isPaymentSuccessful ?? false;
    return Column(
      key: const ValueKey('result'),
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.transparent,
          child: SvgPicture.asset(
            success
                ? "sdk_transaction_successful_icon"
                : "sdk_transaction_failed_icon",
          ),
        ),
        context.sbH(8),
        Text(
          success ? "Payment Successful!" : "Payment Failed!",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        context.sbH(8),
        Text(
          success
              ? "Your payment of ₦${SDKUtils.formatMoney(double.parse(_transactionAmount.toString()))} was successful. Mona has sent you a transaction receipt!"
              : "Your payment of ₦${SDKUtils.formatMoney(double.parse(_transactionAmount.toString()))} failed! \nPlease try again or use a different payment method.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: MonaColors.textBody),
        ),
        context.sbH(16),
        CustomButton(
          label: success ? "Return" : "Try Again",
          onTap: () {
            if (!success) {
              _resetAnimations();
              sdkNotifier.resetSDKState();
              // In a real app, you might pop or call a method to restart.
              // For this demo, we'll just rebuild the state.
              setState(() => showPaymentSuccessfulOrFailed = false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _firstProgressController.forward();
                //sdkNotifier.simulateTransaction();
              });
              return;
            }
            // Navigator.of(context).pop();
            print("Returning...");
          },
        )
      ],
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.isCurrentStage,
    required this.colorAnimation,
    required this.controller,
    this.isFirst = false,
    this.isLast = false,
  });

  final bool isCurrentStage;
  final Animation<Color?> colorAnimation;
  final AnimationController controller;
  final bool isFirst;
  final bool isLast;

  static const double _lineWidth = 8.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _lineWidth,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                color: MonaColors.successColour.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  _lineWidth,
                ) /* BorderRadius.horizontal(
                left: isFirst ? const Radius.circular(_lineWidth) : Radius.zero,
                right: isLast ? const Radius.circular(_lineWidth) : Radius.zero,
              ), */
                ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: controller.value,
                child: Container(
                  decoration: BoxDecoration(
                      color: colorAnimation.value,
                      borderRadius: BorderRadius.circular(
                        _lineWidth,
                      ) /* BorderRadius.horizontal(
                      left: isFirst
                          ? const Radius.circular(_lineWidth)
                          : Radius.zero,
                      right: isLast
                          ? const Radius.circular(_lineWidth)
                          : Radius.zero,
                    ), */
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
    this.isPaymentSuccessful,
  });

  final bool isCurrentStage;
  final bool? isPaymentSuccessful;
  final String stageText;

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final double circleRadius;
    Widget? icon;

    if (isCurrentStage) {
      if (isPaymentSuccessful == false) {
        /// *** Explicitly failed
        circleColor = MonaColors.errorColour;
        icon = SvgPicture.asset(
          "close".svg,
          height: 12,
        );
        circleRadius = 12;
      } else {
        /// *** Completed successfully
        circleColor = MonaColors.successColour;
        icon = SvgPicture.asset(
          "mona_tick".svg,
          height: 12,
        );
        circleRadius = 12;
      }
    } else {
      /// *** Not yet at this stage
      circleColor = MonaColors.successColour.withOpacity(
        0.1,
      );
      icon = null;
      circleRadius = 10;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: circleRadius,
            backgroundColor: circleColor,
            child: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 300,
              ),
              child: icon,
            ),
          ),
          context.sbH(8),
          Text(
            stageText,
            style: const TextStyle(
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }
}

// Using the flowing progress bar from your file
/* class FlowingProgressBar extends StatefulWidget {
  const FlowingProgressBar({
    super.key,
    required this.baseColor,
    required this.flowColor,
    this.duration = const Duration(milliseconds: 1500),
    this.stripeWidth = 0.3,
    this.height = 8.0,
    this.borderRadius = 4.0,
  });

  final Color baseColor;
  final Color flowColor;
  final Duration duration;
  final double stripeWidth;
  final double height;
  final double borderRadius;

  @override
  State<FlowingProgressBar> createState() => _FlowingProgressBarState();
}

class _FlowingProgressBarState extends State<FlowingProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(color: widget.baseColor),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final fullWidth = constraints.maxWidth;
                    // Animate a flowing gradient instead of a block
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.baseColor,
                            widget.flowColor,
                            widget.baseColor
                          ],
                          stops: [
                            _animation.value - 0.4,
                            _animation.value,
                            _animation.value + 0.4
                          ],
                          tileMode: TileMode.repeated,
                        ).createShader(bounds);
                      },
                      child: Container(
                        width: fullWidth,
                        height: widget.height,
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} */


/* 
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

  bool showPaymentSuccessfulOrFailed = false;
  bool? isPaymentSuccessful;

  // Track current payment stage 0: not started, 1: sent, 2: received
  int _currentStage = 0;
  num _transactionAmount = 0;

  @override
  void initState() {
    super.initState();

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

    _firstProgressColorAnimation = ColorTween(
      begin: MonaColors.successColour.withOpacity(0.1),
      end: MonaColors.successColour,
    ).animate(_firstProgressController);

    _secondProgressColorAnimation = (isPaymentSuccessful ?? true
            ? ColorTween(
                begin: MonaColors.successColour.withOpacity(0.1),
                end: MonaColors.successColour,
              )
            : ColorTween(
                begin: MonaColors.errorColour.withOpacity(0.1),
                end: MonaColors.errorColour,
              ))
        .animate(_secondProgressController);

    _thirdProgressColorAnimation = (isPaymentSuccessful ?? false
            ? ColorTween(
                begin: MonaColors.successColour.withOpacity(0.1),
                end: MonaColors.successColour,
              )
            : ColorTween(
                begin: MonaColors.errorColour.withOpacity(0.1),
                end: MonaColors.errorColour,
              ))
        .animate(_thirdProgressController);

    _firstProgressController.addListener(() {
      if (mounted) setState(() {});
    });

    _secondProgressController.addListener(() {
      if (mounted) setState(() {});
    });

    _thirdProgressController.addListener(() {
      if (mounted) setState(() {});
    });

    _firstProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _currentStage = 1; // Sent stage
        });
      }
    });

    _secondProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _currentStage = 2;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _firstProgressController.forward();

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

                _transactionAmount = amount ?? 0;
                isPaymentSuccessful = false;
                setState(() {});
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

                _transactionAmount = amount ?? 0;
                isPaymentSuccessful = true;
                setState(() {});
                _completeAllAnimations();
                break;

              case TransactionStateInitiated(
                  :final transactionID,
                  :final amount,
                ):
                ("SdkPaymentStatusModal 🚀 Initiated: tx=$transactionID, amount=$amount)")
                    .log();

                _transactionAmount = amount ?? 0;
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
    if (mounted) {
      setState(() {
        _currentStage = 0;
      });
    }
  }

  void _completeAllAnimations({
    bool isCompletedTransaction = true,
  }) async {
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (mounted) {
          setState(() => _currentStage = 1);
        }

        _secondProgressController.forward(
          from: _secondProgressController.value,
        );

        Future.delayed(
          const Duration(milliseconds: 1500),
          () async {
            if (mounted) {
              setState(() {
                _currentStage = 2;
              });
            }

            _thirdProgressController.forward(
              from: _thirdProgressController.value,
            );

            await Future.delayed(Duration(milliseconds: 500));

            if (mounted) {
              setState(() {
                showPaymentSuccessfulOrFailed = true;
              });
            }

            await Future.delayed(Duration(seconds: 2));

            if (isCompletedTransaction) {
              sdkNotifier.handleNavToConfirmationScreen();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        spacing: 8.0,
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
                        child: switch (isPaymentSuccessful) {
                          true => SvgPicture.asset(
                              "sdk_transaction_successful_icon".svg),
                          false =>
                            SvgPicture.asset("sdk_transaction_failed_icon".svg),
                          null => SizedBox.shrink(),
                        },
                      ),

                      context.sbH(8),

                      ///
                      Text(
                        // Since this branch only runs when showPaymentSuccessfulOrFailed == true,
                        // we know isPaymentSuccessful is non-null here, but the compiler still
                        // wants us to treat it as nullable. So we can use the null-coalescing
                        // operator to default to “false” if somehow it’s still null.
                        (isPaymentSuccessful ?? false)
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
                        (isPaymentSuccessful ?? false)
                            ? "Your payment of ₦${SDKUtils.formatMoney(double.parse(_transactionAmount.toString()))} was successful. Mona has sent you a transaction receipt!"
                            : "Your payment of ₦${SDKUtils.formatMoney(double.parse(_transactionAmount.toString()))} failed! \nPlease try again or use a different payment method.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: MonaColors.textBody,
                        ),
                      ),

                      context.sbH(8),

                      CustomButton(
                        label: (isPaymentSuccessful ?? false)
                            ? "Return"
                            : "Try Again",
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
                          Expanded(
                            child: PaymentStageWidget(
                              isPaymentSuccessful: true,
                              isCurrentStage: _currentStage >= 1,
                              stageText: "Sent",
                            ),
                          ),

                          context.sbW(4),

                          Expanded(
                            flex: 4,
                            child: _currentStage == 1
                                ? FlowingProgressBar(
                                    baseColor: switch (
                                        isPaymentSuccessful ?? true) {
                                      true => MonaColors.successColour
                                          .withOpacity(0.1),
                                      false =>
                                        MonaColors.errorColour.withOpacity(0.1),
                                    },
                                    flowColor: switch (
                                        isPaymentSuccessful ?? true) {
                                      true => MonaColors.successColour,
                                      false => MonaColors.errorColour,
                                    },
                                  )
                                : AnimatedProgressBar(
                                    isCurrentStage: _currentStage >= 1,
                                    colorAnimation:
                                        _secondProgressColorAnimation,
                                    controller: _secondProgressController,
                                  ),
                          ),

                          context.sbW(4),

                          Expanded(
                            child: PaymentStageWidget(
                              isPaymentSuccessful: isPaymentSuccessful,
                              isCurrentStage: _currentStage >= 2,
                              stageText: "Received",
                            ),
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
    this.isPaymentSuccessful,
  });

  final bool isCurrentStage;
  final bool? isPaymentSuccessful;
  final String stageText;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch ((isPaymentSuccessful, isCurrentStage)) {
      (false, _) => MonaColors.errorColour,
      (true, true) => MonaColors.successColour,
      (_, true) => MonaColors.successColour.withOpacity(0.2),
      _ => MonaColors.successColour.withOpacity(0.1),
    };

    final icon = switch ((isPaymentSuccessful, isCurrentStage)) {
      (true, true) => SvgPicture.asset(
          "mona_tick".svg,
          height: 12,
        ),
      (false, true) => SvgPicture.asset(
          "close".svg,
          height: 12,
        ),
      _ => null,
    };

    return Column(
      spacing: 8.0,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: backgroundColor,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: icon,
          ),
        ),

        ///
        Text(
          stageText,
          style: TextStyle(fontSize: 10.0),
        ),
      ],
    );
  }
}
 */