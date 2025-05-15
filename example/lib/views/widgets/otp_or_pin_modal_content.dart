import 'package:example/utils/custom_button.dart';
import 'package:example/utils/extensions.dart';
import 'package:example/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

class OtpOrPinModalContent extends ConsumerWidget {
  const OtpOrPinModalContent({
    super.key,
    required this.controller,
    required this.task,
    required this.onDone,
  });

  final GlobalKey<OtpPinFieldState> controller;
  final TransactionStateRequestOTPTask task;
  final Function(String) onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          context.sbH(16.0),

          //!
          Text(
            "${task.task.taskDescription}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),

          context.sbH(16.0),

          //!
          SizedBox(
            width: double.infinity,
            child: OtpPinField(
              key: controller,
              maxLength: task.task.fieldLength ?? 4,
              otpPinFieldDecoration:
                  OtpPinFieldDecoration.defaultPinBoxDecoration,
              onSubmit: (String text) {
                "onSubmit OTP $text".log();
                Navigator.of(context).pop();
                onDone(text.trim());
              },
              onChange: (String text) {
                "onChange OTP $text".log();
              },
            ),
          ),

          context.sbH(16.0),

          CustomButton(
            label: "Close",
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/* 
class Authorize extends ConsumerStatefulWidget {
  final Function onInput;
  final int pinLength;
  final bool hasError;
  final String errorMsg;
  final String title;
  final String subtitle;
  final bool isLogin;
  final bool isOffline;
  final Color colour;

  const Authorize(
      {this.title = 'Enter your Passcode',
      this.subtitle = '',
      required this.onInput,
      this.pinLength = 4,
      this.hasError = false,
      this.errorMsg = '',
      this.isLogin = false,
      this.isOffline = false,
      this.colour = Colors.transparent,
      super.key});

  @override
  PinInputState createState() => PinInputState();
}

class PinInputState extends ConsumerState<Authorize> {
  final cFormatter = NumberFormat.simpleCurrency(name: '', decimalDigits: 2);
  String pin = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.colour,
      child: Column(
        children: [
          if (!widget.isOffline)
            AppNavBar(
                title: '',
                onTap: () => context.router.replaceAll([const LandingRoute()])),
          TopAppBar(
            title: widget.title,
            subTitle: widget.subtitle,
          ),
          SizedBox(height: 5.h),
          Expanded(
              child: PinInput(
                  onInput: (p) => widget.onInput(p),
                  errorMsg: widget.errorMsg,
                  hasError: widget.hasError,
                  pinLength: widget.pinLength,
                  isLogin: widget.isLogin)),
        ],
      ),
    );
  }
}
 */
