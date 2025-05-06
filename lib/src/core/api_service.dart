import 'dart:async';
import 'dart:convert';

import 'package:pay_with_mona/src/core/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api_response.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';

import '../core/config.dart';

import 'dart:io';

/// Basic HTTP service using [HttpClient], with curl-style logging
/// and detailed error handling via [APIException].
class ApiService {
  final HttpClient _client = HttpClient();
  final String baseUrl;

  // Configure default timeout
  final Duration timeout;

  // Log verbosity levels
  final bool logRequests;
  final bool logResponses;
  final bool logCurlCommands;

  static const String _defaultBaseUrl = APIConfig.baseUrl;

  ApiService({
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.logRequests = true,
    this.logResponses = true,
    this.logCurlCommands = true,
  }) : baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(r'\/+\\$', '');

  /// POST to [endpoint], passing optional JSON [data] and [headers].
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    if (logRequests) {
      '🚀 POST Request to $uri'.log();
      if (data != null) '📦 Request data: $data'.log();
    }

    if (logCurlCommands) {
      _logCurl('POST', uri, headers: headers, data: data);
    }

    try {
      final request = await _client.openUrl('POST', uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      headers?.forEach(request.headers.set);

      if (data != null) {
        request.add(utf8.encode(jsonEncode(data)));
      }

      final response = await request.close().timeout(
            timeout,
            onTimeout: () =>
                throw TimeoutException('Request timed out', timeout),
          );

      final body = await response.transform(utf8.decoder).join();

      // Log raw response
      if (logResponses) {
        '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
            .log();
      }

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });

      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: body,
      );

      if (!apiResponse.isSuccess) {
        throw APIException(
          'Server responded with error code ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: body,
          requestUrl: uri,
          requestMethod: 'POST',
        );
      }

      return apiResponse;
    } catch (e) {
      final apiEx = APIException.fromHttpError(e, uri: uri, method: 'POST');
      '❌ POST ERROR: ${apiEx.toString()}'.log();
      throw apiEx;
    }
  }

  /// GET from [endpoint], with optional [queryParams] and [headers].
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    if (logRequests) {
      '🔍 GET Request to $uri'.log();
    }

    if (logCurlCommands) {
      _logCurl('GET', uri, headers: headers);
    }

    try {
      final request = await _client.openUrl('GET', uri);
      headers?.forEach(request.headers.set);

      final response = await request.close().timeout(
            timeout,
            onTimeout: () =>
                throw TimeoutException('Request timed out', timeout),
          );

      final body = await response.transform(utf8.decoder).join();

      // Log raw response
      if (logResponses) {
        '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
            .log();
      }

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });

      final apiResponse = ApiResponse(
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: body,
      );

      if (!apiResponse.isSuccess) {
        throw APIException(
          'Server responded with error code ${response.statusCode}',
          statusCode: response.statusCode,
          responseBody: body,
          requestUrl: uri,
          requestMethod: 'GET',
        );
      }

      return apiResponse;
    } catch (e) {
      final apiEx = APIException.fromHttpError(e, uri: uri, method: 'GET');
      '❌ GET ERROR: ${apiEx.toString()}'.log();
      throw apiEx;
    }
  }

  /// Logs a curl command for reproduction, plus pipes to [jq].
  void _logCurl(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
  }) {
    final sb = StringBuffer()
      ..write('🧠 🔍 🧾 HTTPClient ::: CURL -v')
      ..write(' -X $method');

    // Add content-type for POST requests
    if (method == 'POST') {
      sb.write(" -H 'Content-Type: application/json'");
    }

    headers?.forEach((k, v) {
      sb.write(" -H '$k: $v'");
    });

    if (data != null) {
      final payload = jsonEncode(data).replaceAll("'", "\\'");
      sb.write(" -d '$payload'");
    }

    final baseAndPath =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
    final fullUrl =
        uri.query.isNotEmpty ? '$baseAndPath?${uri.query}' : baseAndPath;

    sb
      ..write(" '$fullUrl'")
      ..write(' | jq');

    sb.toString().log();
  }

  /// Truncate long strings for logging to avoid console clutter
  String _truncateForLogging(String text, {int maxLength = 1000}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (${text.length - maxLength} more characters)';
  }
}
