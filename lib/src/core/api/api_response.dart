import 'dart:convert';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';

/// A simple HTTP response wrapper.
class ApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  /// Convenience for decoding a JSON body.
  dynamic get json {
    try {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } on FormatException catch (e) {
      throw APIException('Invalid JSON response: ${e.message}');
    }
  }

  /// Check if response was successful (2xx status code)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Get response as a printable string
  @override
  String toString() => 'ApiResponse(statusCode: $statusCode, body: $body)';
}
