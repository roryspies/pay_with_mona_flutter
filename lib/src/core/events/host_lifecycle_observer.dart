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



/* 
// A robust AppLifecycleMonitor using WidgetsBindingObserver
class AppLifecycleMonitor with WidgetsBindingObserver {
  final Function(AppLifecycleState state) onStateChanged;
  bool _isObserving = false;

  AppLifecycleMonitor({required this.onStateChanged});

  void start() {
    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
    }
  }

  void dispose() {
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
 */