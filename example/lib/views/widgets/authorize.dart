import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    return SafeArea(
      child: Container(
        color: widget.colour,
        child: Column(
          children: [
            /*   if (!widget.isOffline)
              AppNavBar(
                  title: '',
                  onTap: () =>
                      context.router.replaceAll([const LandingRoute()])),
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
                    isLogin: widget.isLogin)), */
          ],
        ),
      ),
    );
  }
}
