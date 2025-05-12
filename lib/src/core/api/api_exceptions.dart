import 'dart:async';
import 'dart:io';

/// A generic API exception for wrapping HTTP/client errors.
class APIException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  final Uri? requestUrl;
  final String? requestMethod;

  APIException(
    this.message, {
    this.statusCode,
    this.responseBody,
    this.requestUrl,
    this.requestMethod,
  });

  @override
  String toString() {
    final buffer = StringBuffer('APIException: $message');
    if (statusCode != null) buffer.write(' (Status: $statusCode)');
    if (requestMethod != null && requestUrl != null) {
      buffer.write('\nRequest: $requestMethod $requestUrl');
    }
    if (responseBody != null && responseBody!.isNotEmpty) {
      // Truncate long response bodies
      final truncatedBody = responseBody!.length > 500
          ? '${responseBody!.substring(0, 500)}...'
          : responseBody;
      buffer.write('\nResponse: $truncatedBody');
    }
    return buffer.toString();
  }

  /// Create a fine-grained exception from lower-level errors.
  factory APIException.fromHttpError(Object error, {Uri? uri, String? method}) {
    if (error is SocketException) {
      return APIException(
        'No Internet connection: ${error.message}',
        requestUrl: uri,
        requestMethod: method,
      );
    }

    if (error is HttpException) {
      return APIException(
        'Failed to connect to server: ${error.message}',
        requestUrl: uri,
        requestMethod: method,
      );
    }

    if (error is FormatException) {
      return APIException(
        'Invalid response format: ${error.message}',
        requestUrl: uri,
        requestMethod: method,
      );
    }

    if (error is TimeoutException) {
      return APIException(
        'Request timed out after ${error.duration?.inSeconds ?? 30} seconds',
        requestUrl: uri,
        requestMethod: method,
      );
    }

    if (error is APIException) {
      // Add request context if missing
      if (error.requestUrl == null && uri != null) {
        return APIException(
          error.message,
          statusCode: error.statusCode,
          responseBody: error.responseBody,
          requestUrl: uri,
          requestMethod: method ?? error.requestMethod,
        );
      }
      return error;
    }

    // Fallback catch-all
    return APIException(
      'Unexpected error: ${error.toString()}',
      requestUrl: uri,
      requestMethod: method,
    );
  }
}

class MonaSDKError implements Exception {
  final String message;
  MonaSDKError({
    required this.message,
  });

  @override
  String toString() => "MonaSDKException: $message";
}
