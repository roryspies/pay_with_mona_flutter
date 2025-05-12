import 'dart:async';
import 'package:pay_with_mona/src/utils/extensions.dart';

/// Defines the possible states of the Mona SDK.
enum MonaSDKState { idle, loading, success, error }

/// A singleton that manages a broadcast stream of [MonaSDKState] events.
///
/// This class implements a safe singleton pattern with proper initialization
/// and disposal handling for state management across the application.
class MonaSdkStateStream {
  // Private constructor for singleton pattern
  MonaSdkStateStream._();

  // Static instance for singleton access
  static final MonaSdkStateStream _instance = MonaSdkStateStream._();

  // Factory constructor to return the singleton instance
  factory MonaSdkStateStream() => _instance;

  // Logger prefix for easier debugging
  static const _logPrefix = "🧰 MonaSdkStateStream";

  // Stream controller with broadcast capability
  late StreamController<MonaSDKState> _controller;

  // Flag to track initialization state
  bool _isInitialized = false;

  /// Returns the SDK state stream. Initializes the controller if needed.
  Stream<MonaSDKState> get stream {
    _ensureInitialized();
    return _controller.stream;
  }

  /// The current state of the SDK.
  /// Returns [MonaSDKState.idle] if no state has been emitted yet.
  MonaSDKState _currentState = MonaSDKState.idle;
  MonaSDKState get currentState => _currentState;

  /// Ensures the stream controller is initialized.
  void _ensureInitialized() {
    if (!_isInitialized || _controller.isClosed) {
      _controller = StreamController<MonaSDKState>.broadcast(
        onListen: () => _log("🔔 Listener attached"),
        onCancel: () => _log("🔕 Listener removed"),
      );
      _isInitialized = true;
      _log("✨ Stream initialized");
    }
  }

  /// Emits a new state to all listeners.
  ///
  /// If the stream is closed, it will be re-initialized.
  void emit({required MonaSDKState state}) {
    _ensureInitialized();

    _currentState = state;
    _controller.add(state);
    _log("✅ Emitted $state");
  }

  /// Closes the current stream controller.
  ///
  /// The stream can be reused after disposal by accessing [stream]
  /// or calling [emit], which will create a new controller.
  void dispose() {
    if (_isInitialized && !_controller.isClosed) {
      _controller.close();
      _isInitialized = false;
      _log("🧹 Stream disposed");
    }
  }

  /// Logs a message with the class prefix.
  static void _log(String message) => "$_logPrefix ::: $message".log();
}
