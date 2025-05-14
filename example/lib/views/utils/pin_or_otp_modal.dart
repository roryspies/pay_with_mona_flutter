import 'package:example/utils/mona_colors.dart';
import 'package:example/utils/size_config.dart';
import 'package:example/views/widgets/authorize.dart';
import 'package:flutter/material.dart';

class AppUtils {
  static Future<void> requestPin(
    BuildContext context,
    String title,
    Map<String, dynamic> payload, {
    required Function callback,
    Map<String, dynamic>? config,
  }) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(0),
          backgroundColor: Colors.white,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Container(
              width: width(context),
              color: MonaColors.primary,
              child: Authorize(
                title: title,
                subtitle: config!['subtitle'],
                pinLength: config['pinLen'],
                colour: config['colour'],
                onInput: (inputPin) {
                  callback(inputPin);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
