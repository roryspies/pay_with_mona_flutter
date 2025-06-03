import 'package:flutter/widgets.dart';

typedef AppLifecycleCallback = void Function(AppLifecycleState state);

class AppLifecycleMonitor with WidgetsBindingObserver {
  final AppLifecycleCallback onStateChanged;

  AppLifecycleMonitor({required this.onStateChanged}) {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
