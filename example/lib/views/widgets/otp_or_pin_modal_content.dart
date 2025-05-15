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
