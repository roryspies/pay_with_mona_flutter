import 'dart:async';
import 'package:pay_with_mona/src/utils/extensions.dart';

/// Defines the possible authentication states of the user.
enum AuthState {
  /// The user is authenticated and logged in
  loggedIn,

  /// The user is not authenticated and logged out
  loggedOut,

  /// An error occurred during authentication
  error,

  /// An error occurred during authentication
  notAMonaUser,
}

/// A singleton that manages a broadcast stream of [AuthState] events.
///
/// This class implements a safe singleton pattern with proper initialization
/// and disposal handling for tracking authentication states across the application.
class AuthStateStream {
  // Private constructor for singleton pattern
  AuthStateStream._();

  // Static instance for singleton access
  static final AuthStateStream _instance = AuthStateStream._();

  // Factory constructor to return the singleton instance
  factory AuthStateStream() => _instance;

  // Logger prefix for easier debugging
  static const _logPrefix = "🔐 AuthStateStream";

  // Stream controller with broadcast capability
  late StreamController<AuthState> _controller;

  // Flag to track initialization state
  bool _isInitialized = false;

  /// Returns the authentication state stream. Initializes the controller if needed.
  Stream<AuthState> get stream {
    _ensureInitialized();
    return _controller.stream;
  }

  /// The current authentication state.
  /// Returns [AuthState.loggedOut] as the default initial state.
  AuthState _currentState = AuthState.loggedOut;

  /// Gets the current authentication state without subscribing to the stream.
  AuthState get currentState => _currentState;

  /// Ensures the stream controller is initialized.
  void _ensureInitialized() {
    if (!_isInitialized || _controller.isClosed) {
      _controller = StreamController<AuthState>.broadcast(
        onListen: () => _log("🔔 Listener attached"),
        onCancel: () => _log("🔕 Listener removed"),
      );
      _isInitialized = true;
      _log("✨ Stream initialized");
    }
  }

  /// Emits a new authentication state to all listeners.
  ///
  /// If the stream is closed, it will be re-initialized automatically.
  /// @param state The new authentication state to emit
  void emit({required AuthState state}) {
    _ensureInitialized();

    _currentState = state;
    _controller.add(state);
    _log("✅ Emitted $state");
  }

  /// Convenience method to emit a logged-in state.
  void logIn() {
    emit(state: AuthState.loggedIn);
  }

  /// Convenience method to emit a logged-out state.
  void logOut() {
    emit(state: AuthState.loggedOut);
  }

  /// Convenience method to emit an error state.
  void emitError() {
    emit(state: AuthState.error);
  }

  /// Checks if the user is currently logged in.
  bool get isLoggedIn => _currentState == AuthState.loggedIn;

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
