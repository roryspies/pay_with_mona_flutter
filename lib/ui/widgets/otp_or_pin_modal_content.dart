import 'package:flutter/material.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';
import 'package:pay_with_mona/src/widgets/custom_button.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

class OtpOrPinModalContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          //!
          Text(
            "${task.task.taskDescription}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),

          //!
          SizedBox(
            width: double.infinity,
            child: OtpPinField(
              fieldWidth: 40.0,
              fieldHeight: 40.0,
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
