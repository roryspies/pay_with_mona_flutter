/// Exception thrown when biometric operations fail.
///
/// This exception wraps any underlying error or stack trace that occurred
/// during a biometric operation, allowing callers to inspect both the
/// high-level message and the original error context.
class BiometricException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// The original error object that triggered this exception, if any.
  final dynamic originalError;

  /// The stack trace from the original error, if available.
  final StackTrace? stackTrace;

  /// Creates a [BiometricException].
  ///
  /// [message]: a descriptive error message for logging or user feedback.
  /// [originalError]: the original error thrown by underlying APIs, for debugging.
  /// [stackTrace]: the stack trace captured at the point of failure.
  BiometricException(
    this.message, [
    this.originalError,
    this.stackTrace,
  ]);

  @override
  String toString() {
    final buffer = StringBuffer()..write('BiometricException: $message');

    if (originalError != null) {
      buffer.write(' | originalError: $originalError');
    }

    if (stackTrace != null) {
      buffer
        ..write('\nStackTrace:\n')
        ..write(stackTrace.toString());
    }

    return buffer.toString();
  }
}
