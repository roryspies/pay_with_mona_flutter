import 'dart:async';
import 'package:pay_with_mona/src/core/events/transaction_state_classes.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

/// Make TransactionState an abstract base class…

/// A singleton that manages a broadcast stream of [TransactionState] events.
///
/// This class implements a safe singleton pattern with proper initialization
/// and disposal handling for tracking transaction states across the application.
class TransactionStateStream {
  // Private constructor for singleton pattern
  TransactionStateStream._();

  // Static instance for singleton access
  static final TransactionStateStream _instance = TransactionStateStream._();

  // Factory constructor to return the singleton instance
  factory TransactionStateStream() => _instance;

  // Logger prefix for easier debugging
  static const _logPrefix = "💸 TransactionStateStream";

  // Stream controller with broadcast capability
  late StreamController<TransactionState> _controller;

  // Flag to track initialization state
  bool _isInitialized = false;

  /// Returns the transaction state stream. Initializes the controller if needed.
  Stream<TransactionState> get stream {
    _ensureInitialized();
    return _controller.stream;
  }

  /// The current state of the transaction.
  /// Returns [TransactionStateIdle] if no state has been emitted yet.
  TransactionState _currentState = TransactionStateIdle();
  TransactionState get currentState => _currentState;

  /// Ensures the stream controller is initialized.
  void _ensureInitialized() {
    if (!_isInitialized || _controller.isClosed) {
      _controller = StreamController<TransactionState>.broadcast(
        onListen: () => _log("🔔 Listener attached"),
        onCancel: () => _log("🔕 Listener removed"),
      );
      _isInitialized = true;
      _log("✨ Stream initialized");
    }
  }

  /// Emits a new transaction state to all listeners.
  ///
  /// If the stream is closed, it will be re-initialized automatically.
  /// @param state The new transaction state to emit
  void emit({required TransactionState state}) {
    _ensureInitialized();

    _currentState = state;
    _controller.add(state);
    _log("✅ Emitted $state");
  }

  /// Resets the transaction to its initial state (initiated).
  void reset() {
    emit(state: TransactionStateIdle());
    _log("🔄 Transaction state reset");
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
  static void _log(String message) => "$_logPrefix :: $message".log();
}
