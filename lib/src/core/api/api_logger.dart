import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';

class APIServiceRemoteLogger {
  final String webhookUrl;
  final HttpClient _discordClient = HttpClient();
  final bool enabled;

  APIServiceRemoteLogger({
    required this.webhookUrl,
    this.enabled = true,
  });

  Future<void> logRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Map<String, dynamic>? data,
  }) async {
    if (!enabled) return;

    final payload = {
      "content": "🚀 API REQUEST\n"
          "```\n"
          "Method: $method\n"
          "URL: $uri\n"
          "Headers: ${_formatHeaders(headers ?? {})}\n"
          "Data: ${_formatData(data)}\n"
          "```\n"
          "📆 Time: `${toReadableDateAndTime(dateAndTime: DateTime.now())}`",
    };

    await _sendToDiscord(payload);
  }

  Future<void> logResponse({
    required int statusCode,
    required String? statusMessage,
    required Uri uri,
    required String responseBody,
  }) async {
    if (!enabled) return;

    final payload = {
      "content": "✅ API RESPONSE\n"
          "```\n"
          "Status: $statusCode ${statusMessage ?? ''}\n"
          "URL: $uri\n"
          "Response: ${shorten(text: responseBody)}\n"
          "```\n"
          "📆 Time: `${toReadableDateAndTime(dateAndTime: DateTime.now())}`",
    };

    await _sendToDiscord(payload);
  }

  /// Log error information to Discord
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    required Uri uri,
    int? statusCode,
    String? responseBody,
  }) async {
    if (!enabled) return;

    final payload = {
      "content": "❌ API ERROR\n"
          "```\n"
          "Type: $errorType\n"
          "Message: $errorMessage\n"
          "URL: $uri\n"
          "Status Code: ${statusCode ?? 'N/A'}\n"
          "Response: ${responseBody != null ? shorten(text: responseBody) : 'N/A'}\n"
          "```\n"
          "📆 Time: `${toReadableDateAndTime(dateAndTime: DateTime.now())}`",
    };

    await _sendToDiscord(payload);
  }

  /// Send payload to Discord webhook
  Future<void> _sendToDiscord(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse(webhookUrl);
      final request = await _discordClient.openUrl('POST', uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
                'Discord webhook timeout', const Duration(seconds: 10)),
          );

      // Consume the response to avoid memory leaks
      await response.drain();
    } catch (error) {
      "🔔 ERROR SENDING DISCORD MESSAGE ==>> $error".log();
    }
  }

  /// Format headers for display
  String _formatHeaders(Map<String, String> headers) {
    if (headers.isEmpty) return "None";
    return headers.entries.map((e) => "${e.key}: ${e.value}").join("\n");
  }

  /// Format request data for display
  String _formatData(dynamic data) {
    if (data == null) return "None";
    return shorten(text: data.toString());
  }

  /// Shorten text to prevent Discord message limits
  String shorten({
    required String text,
    int maxLength = 1000,
  }) {
    return text.length > maxLength
        ? "${text.substring(0, maxLength)}..."
        : text;
  }

  /// Convert DateTime to readable format
  String toReadableDateAndTime({
    required DateTime dateAndTime,
  }) {
    final localDateTime = dateAndTime.toLocal();
    final formatter = DateFormat("hh:mm a, EEE, dd MMM");
    return formatter.format(localDateTime);
  }

  /// Dispose of resources
  void dispose() {
    _discordClient.close();
  }
}
