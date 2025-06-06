import 'dart:async';
import 'dart:convert';
import 'package:pay_with_mona/src/core/api/api_exceptions.dart';
import 'package:pay_with_mona/src/core/api/api_remote_logger.dart';
import 'package:pay_with_mona/src/core/api/api_response.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'api_config.dart';
import 'dart:io';

/// Basic HTTP service using [HttpClient], with curl-style logging
/// and detailed error handling via [APIException].
class ApiService {
  final HttpClient _client = HttpClient();
  final String baseUrl;
  final APIServiceRemoteLogger? _apiServiceRemoteLogger;

  // Configure default timeout
  final Duration timeout;

  // Log verbosity levels
  final bool logRequests;
  final bool logResponses;
  final bool logCurlCommands;

  // JSON formatting settings for logs
  final bool prettyPrintJson;
  final int jsonIndent;

  static const String _defaultBaseUrl = APIConfig.baseUrl;

  ApiService({
    String? baseUrl,
    this.timeout = const Duration(
      seconds: 60,
    ),
    this.logRequests = true,
    this.logResponses = true,
    this.logCurlCommands = true,
    this.prettyPrintJson = true,
    this.jsonIndent = 2,
    String loggerWebHookURL = APIConfig.loggerWebHook,
    bool enableRemoteLogger = true,
  })  : baseUrl = (baseUrl ?? _defaultBaseUrl),
        _apiServiceRemoteLogger = (enableRemoteLogger)
            ? APIServiceRemoteLogger(
                webhookUrl: loggerWebHookURL,
                enabled: enableRemoteLogger,
              )
            : null;

  /// POST to [endpoint], passing optional JSON [data] and [headers].
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Logging - log request
    await _apiServiceRemoteLogger?.logRequest(
      method: 'POST',
      uri: uri,
      headers: headers,
      data: data,
    );

    if (logRequests) {
      '🚀 POST Request to $uri'.log();
      if (data != null) {
        '📦 Request data: $data'.log();
      }
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

      // Logging - log response
      await _apiServiceRemoteLogger?.logResponse(
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        uri: uri,
        responseBody: body,
      );

      // Log raw response
      if (logResponses) {
        final contentType = response.headers.contentType?.mimeType ?? '';
        if (contentType.contains('json') && prettyPrintJson) {
          try {
            final jsonData = jsonDecode(body);
            '🧾 RESPONSE [${response.statusCode}]:\n${_prettyJson(jsonData)}'
                .log();
          } catch (e) {
            // Fallback to regular logging if we can't parse JSON
            '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
                .log();
            '⚠️ Failed to parse response as JSON: ${e.toString()}'.log();
          }
        } else {
          '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
              .log();
        }
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
        final errorMessage = extractErrorMessage(response.statusCode, body);

        // Logging - log error for unsuccessful responses
        await _apiServiceRemoteLogger?.logError(
          errorType: 'HTTP Error',
          errorMessage: errorMessage,
          uri: uri,
          statusCode: response.statusCode,
          responseBody: body,
        );

        throw APIException(
          errorMessage,
          statusCode: response.statusCode,
          responseBody: body,
          requestUrl: uri,
          requestMethod: 'POST',
        );
      }

      return apiResponse;
    } catch (e) {
      final apiEx = APIException.fromHttpError(e, uri: uri, method: 'POST');

      // Logging - log error
      await _apiServiceRemoteLogger?.logError(
        errorType: e.runtimeType.toString(),
        errorMessage: apiEx.message,
        uri: uri,
        statusCode: apiEx.statusCode,
        responseBody: apiEx.responseBody,
      );

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

    // Logging - log request
    await _apiServiceRemoteLogger?.logRequest(
      method: 'GET',
      uri: uri,
      headers: headers,
    );

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

      // Logging - log response
      await _apiServiceRemoteLogger?.logResponse(
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        uri: uri,
        responseBody: body,
      );

      // Log raw response
      if (logResponses) {
        final contentType = response.headers.contentType?.mimeType ?? '';
        if (contentType.contains('json') && prettyPrintJson) {
          try {
            final jsonData = jsonDecode(body);
            '🧾 RESPONSE [${response.statusCode}]:\n${_prettyJson(jsonData)}'
                .log();
          } catch (e) {
            // Fallback to regular logging if we can't parse JSON
            '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
                .log();
            '⚠️ Failed to parse response as JSON: ${e.toString()}'.log();
          }
        } else {
          '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
              .log();
        }
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
        final errorMessage = extractErrorMessage(response.statusCode, body);

        // Logging - log error for unsuccessful responses
        await _apiServiceRemoteLogger?.logError(
          errorType: 'HTTP Error',
          errorMessage: errorMessage,
          uri: uri,
          statusCode: response.statusCode,
          responseBody: body,
        );

        throw APIException(
          errorMessage,
          statusCode: response.statusCode,
          responseBody: body,
          requestUrl: uri,
          requestMethod: 'GET',
        );
      }

      return apiResponse;
    } catch (e) {
      final apiEx = APIException.fromHttpError(e, uri: uri, method: 'GET');

      // Logging - log error
      await _apiServiceRemoteLogger?.logError(
        errorType: e.runtimeType.toString(),
        errorMessage: apiEx.message,
        uri: uri,
        statusCode: apiEx.statusCode,
        responseBody: apiEx.responseBody,
      );

      '❌ GET ERROR: ${apiEx.toString()}'.log();
      throw apiEx;
    }
  }

  /// PUT to [endpoint], passing optional JSON [data] and [headers].
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    // Logging - log request
    await _apiServiceRemoteLogger?.logRequest(
      method: 'PUT',
      uri: uri,
      headers: headers,
      data: data,
    );

    if (logRequests) {
      '🚀 PUT Request to $uri'.log(); // Fixed: was showing POST
      if (data != null) {
        '📦 Request data: $data'.log();
      }
    }

    if (logCurlCommands) {
      _logCurl('PUT', uri, headers: headers, data: data);
    }

    try {
      final request = await _client.openUrl('PUT', uri);
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

      // Logging - log response
      await _apiServiceRemoteLogger?.logResponse(
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        uri: uri,
        responseBody: body,
      );

      // Log raw response
      if (logResponses) {
        final contentType = response.headers.contentType?.mimeType ?? '';
        if (contentType.contains('json') && prettyPrintJson) {
          try {
            final jsonData = jsonDecode(body);
            '🧾 RESPONSE [${response.statusCode}]:\n${_prettyJson(jsonData)}'
                .log();
          } catch (e) {
            // Fallback to regular logging if we can't parse JSON
            '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
                .log();
            '⚠️ Failed to parse response as JSON: ${e.toString()}'.log();
          }
        } else {
          '🧾 RESPONSE [${response.statusCode}]: ${_truncateForLogging(body)}'
              .log();
        }
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
        final errorMessage = extractErrorMessage(response.statusCode, body);

        // Logging - log error for unsuccessful responses
        await _apiServiceRemoteLogger?.logError(
          errorType: 'HTTP Error',
          errorMessage: errorMessage,
          uri: uri,
          statusCode: response.statusCode,
          responseBody: body,
        );

        throw APIException(
          errorMessage,
          statusCode: response.statusCode,
          responseBody: body,
          requestUrl: uri,
          requestMethod: 'PUT',
        );
      }

      return apiResponse;
    } catch (e) {
      final apiEx = APIException.fromHttpError(e,
          uri: uri, method: 'PUT'); // Fixed: was showing POST

      // Logging - log error
      await _apiServiceRemoteLogger?.logError(
        errorType: e.runtimeType.toString(),
        errorMessage: apiEx.message,
        uri: uri,
        statusCode: apiEx.statusCode,
        responseBody: apiEx.responseBody,
      );

      '❌ PUT ERROR: ${apiEx.toString()}'.log(); // Fixed: was showing POST ERROR
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

    // Add content-type for POST/PUT requests
    if (method == 'POST' || method == 'PUT') {
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
  String _truncateForLogging(String text, {int maxLength = 4000}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... (${text.length - maxLength} more characters)';
  }

  /// Format JSON data with proper indentation for logging
  String _prettyJson(dynamic json, {int level = 0}) {
    if (json == null) return 'null';

    final indent = ' ' * (level * jsonIndent);
    final nextIndent = ' ' * ((level + 1) * jsonIndent);

    if (json is Map) {
      if (json.isEmpty) return '{}';

      final buffer = StringBuffer('{\n');
      var i = 0;

      json.forEach((key, value) {
        if (i > 0) buffer.write(',\n');
        buffer.write(
            '$nextIndent"$key": ${_prettyJson(value, level: level + 1)}');
        i++;
      });

      buffer.write('\n$indent}');
      return buffer.toString();
    } else if (json is List) {
      if (json.isEmpty) return '[]';

      final buffer = StringBuffer('[\n');

      for (var i = 0; i < json.length; i++) {
        if (i > 0) buffer.write(',\n');
        buffer.write('$nextIndent${_prettyJson(json[i], level: level + 1)}');
      }

      buffer.write('\n$indent]');
      return buffer.toString();
    } else if (json is String) {
      // Escape quotes and special characters
      return '"${json.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
    } else if (json is num || json is bool) {
      return json.toString();
    } else {
      return '"$json"';
    }
  }

  /// Extracts the most appropriate error message from an API response
  String extractErrorMessage(int statusCode, String responseBody) {
    String errorMessage = 'Server responded with error code $statusCode';

    // Try to extract error message from response body
    try {
      final Map<String, dynamic> errorData = jsonDecode(responseBody);

      // Check different common error fields
      if (errorData.containsKey('message')) {
        errorMessage = errorData['message'];
      } else if (errorData.containsKey('error')) {
        if (errorData['error'] is String) {
          errorMessage = errorData['error'];
        } else if (errorData['error'] is Map &&
            errorData['error'].containsKey('message')) {
          errorMessage = errorData['error']['message'];
        }
      } else if (errorData.containsKey('errorMessage')) {
        errorMessage = errorData['errorMessage'];
      } else if (errorData.containsKey('detail')) {
        errorMessage = errorData['detail'];
      } else {
        errorMessage = 'Error: ${_truncateForLogging(responseBody)}';
      }
    } catch (e) {
      if (responseBody.isNotEmpty && responseBody.length < 500) {
        errorMessage = 'Error: $responseBody';
      }
    }

    return errorMessage;
  }

  /// Clean up resources
  void dispose() {
    _client.close();
    _apiServiceRemoteLogger?.dispose();
  }
}
