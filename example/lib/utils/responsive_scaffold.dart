import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final scale = mediaQueryData.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: .99,
    );
    final pixelRatio = mediaQueryData.devicePixelRatio.clamp(1.0, 4.0);

    return MediaQuery(
      data: mediaQueryData.copyWith(
        textScaler: scale,
        devicePixelRatio: pixelRatio,
      ),
      child: child,
    );
  }
}
