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
import 'dart:async';

class SdkPaymentStatusModal extends StatefulWidget {
  const SdkPaymentStatusModal({
    super.key,
  });

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

  /// *** --- State variables converted to ValueNotifiers ---
  final ValueNotifier<bool> _showPaymentSuccessfulOrFailed =
      ValueNotifier(false);
  final ValueNotifier<bool?> _isPaymentSuccessful = ValueNotifier(null);
  final ValueNotifier<int> _currentStage = ValueNotifier(0);
  final ValueNotifier<num> _transactionAmount = ValueNotifier(0);

  /// *** --- Timer for auto-navigation ---
  Timer? _autoNavigationTimer;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _setupListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstProgressController.forward();
    });
  }

  void _setupControllers() {
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
    final bool success = _isPaymentSuccessful.value ?? true;
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
    // We no longer need addListener(setState) as ListenableBuilders will handle UI updates.

    _firstProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentStage.value = 1;
      }
    });

    _secondProgressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentStage.value = 2;
      }
    });

    /// *** SDK TXN STATE STREAM LISTENER
    sdkNotifier.txnStateStream.listen(
      (state) async {
        if (!mounted) return;
        switch (state) {
          case TransactionStateFailed(:final amount):
            _transactionAmount.value = amount ?? 0;
            _isPaymentSuccessful.value = false;
            _updateProgressColorAnimations();
            _completeAllAnimations(isCompletedTransaction: false);
            break;
          case TransactionStateCompleted(:final amount):
            _transactionAmount.value = amount ?? 0;
            _isPaymentSuccessful.value = true;
            _updateProgressColorAnimations();
            _completeAllAnimations();
            break;
          case TransactionStateInitiated(:final amount):
            _transactionAmount.value = amount ?? 0;
            break;
          default:
            break;
        }
      },
    );
  }

  void _resetAnimations() {
    _firstProgressController.reset();
    _secondProgressController.reset();
    _thirdProgressController.reset();
    _currentStage.value = 0;
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
    _showPaymentSuccessfulOrFailed.value = true;

    /// ***
    if (isCompletedTransaction) {
      /// *** Start a timer to navigate automatically after 2 seconds
      _autoNavigationTimer = Timer(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            sdkNotifier.handleNavToConfirmationScreen();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    // Cancel timer on dispose
    _autoNavigationTimer?.cancel();
    _firstProgressController.dispose();
    _secondProgressController.dispose();
    _thirdProgressController.dispose();

    /// *** Dispose all ValueNotifiers
    _showPaymentSuccessfulOrFailed.dispose();
    _isPaymentSuccessful.dispose();
    _currentStage.dispose();
    _transactionAmount.dispose();
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
            // Use the .sync() extension for a single ValueNotifier
            child: _showPaymentSuccessfulOrFailed.sync(
              builder: (context, showResult, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: showResult
                      ? _buildStatusResult()
                      : _buildProgressTracker(),
                );
              },
            ),
          ),
          context.sbH(16.0),
          const PoweredByMona(),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    const double circleRadius = 12.0;
    const double lineWidth = 8.0;
    const double verticalPadding = circleRadius - (lineWidth / 2);

    return [
      _currentStage,
      _isPaymentSuccessful,
      _firstProgressController,
      _secondProgressController,
      _thirdProgressController,
    ].multiSync(
      builder: (context, child) {
        final currentStage = _currentStage.value;
        final isPaymentSuccessful = _isPaymentSuccessful.value;

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
            context.sbH(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: verticalPadding),
                    child: AnimatedProgressBar(
                      isCurrentStage: currentStage >= 0,
                      colorAnimation: _firstProgressColorAnimation,
                      controller: _firstProgressController,
                      isFirst: true,
                    ),
                  ),
                ),
                PaymentStageWidget(
                  isPaymentSuccessful: true,
                  isCurrentStage: currentStage >= 1,
                  stageText: "Sent",
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: verticalPadding),
                    child: currentStage == 1 &&
                            (isPaymentSuccessful == null ||
                                isPaymentSuccessful == true)
                        ? FlowingProgressBar(
                            baseColor:
                                MonaColors.successColour.withOpacity(0.1),
                            flowColor: MonaColors.successColour,
                          )
                        : AnimatedProgressBar(
                            isCurrentStage: currentStage >= 1,
                            colorAnimation: _secondProgressColorAnimation,
                            controller: _secondProgressController,
                          ),
                  ),
                ),
                PaymentStageWidget(
                  isPaymentSuccessful: isPaymentSuccessful,
                  isCurrentStage: currentStage >= 2,
                  stageText: "Received",
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: verticalPadding),
                    child: AnimatedProgressBar(
                      isCurrentStage: currentStage >= 2,
                      colorAnimation: _thirdProgressColorAnimation,
                      controller: _thirdProgressController,
                      isLast: true,
                    ),
                  ),
                ),
              ],
            ),
            context.sbH(8),
          ],
        );
      },
    );
  }

  Widget _buildStatusResult() {
    return [
      _isPaymentSuccessful,
      _transactionAmount,
    ].multiSync(
      builder: (context, child) {
        final success = _isPaymentSuccessful.value ?? false;
        final transactionAmount = _transactionAmount.value;

        return Column(
          key: const ValueKey('result'),
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              child: SvgPicture.asset(
                (success
                        ? "sdk_transaction_successful_icon"
                        : "sdk_transaction_failed_icon")
                    .svg,
              ),
            ),
            context.sbH(8),

            ///
            Text(
              success ? "Payment Successful!" : "Payment Failed!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            context.sbH(8),

            ///
            Text(
              success
                  ? "Your payment of ₦${SDKUtils.formatMoney(double.parse(transactionAmount.toString()))} was successful. Mona has sent you a transaction receipt!"
                  : "Your payment of ₦${SDKUtils.formatMoney(double.parse(transactionAmount.toString()))} failed! \nPlease try again or use a different payment method.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: MonaColors.textBody),
            ),

            ///
            context.sbH(16),

            ///
            CustomButton(
              label: success ? "Return" : "Try Again",
              onTap: () {
                if (!success) {
                  // / ***--- Handle "Try Again" ---
                  Navigator.of(context).pop();
                  _resetAnimations();
                  sdkNotifier.resetSDKState(
                    clearMonaCheckout: false,
                    clearPendingPaymentResponseModel: false,
                  );
                  _showPaymentSuccessfulOrFailed.value = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _firstProgressController.forward();
                  });
                  return;
                }

                /// *** --- Handle "Return" ---
                /// *** Cancel timer if active
                _autoNavigationTimer?.cancel();

                /// *** Navigate immediately
                sdkNotifier.handleNavToConfirmationScreen();
              },
            )
          ],
        );
      },
    );
  }
}

// These widgets remain unchanged as they were already well-structured.
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
              ),
            ),
          ),
          // This AnimatedBuilder correctly listens to the controller for progress updates.
          // The color is updated when the parent rebuilds and provides a new colorAnimation.
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
                    ),
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
    Widget? icon;

    if (isCurrentStage) {
      if (isPaymentSuccessful == false) {
        /// *** Explicitly failed
        circleColor = MonaColors.errorColour;
        icon = SvgPicture.asset(
          "close".svg,
          height: 12,
        );
      } else {
        /// *** Completed successfully
        circleColor = MonaColors.successColour;
        icon = SvgPicture.asset(
          "mona_tick".svg,
          height: 12,
        );
      }
    } else {
      /// *** Not yet at this stage
      circleColor = MonaColors.successColour.withOpacity(
        0.1,
      );
      icon = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
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
