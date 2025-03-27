import 'package:dio/dio.dart';
import 'package:pay_with_mona/src/core/exceptions.dart';
import 'package:pay_with_mona/src/utils/extensions.dart';
import '../core/config.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;

  static const String _defaultBaseUrl = APIConfig.baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl {
    _dio = Dio(BaseOptions(baseUrl: this.baseUrl));
    _dio.interceptors.add(LogInterceptor(responseBody: true));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logCurlCommand(options);
        return handler.next(options);
      },
    ));
  }

  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw APIException.fromDioError(e);
    }
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      throw APIException.fromDioError(e);
    }
  }

  void _logCurlCommand(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write("curl -X ${options.method}");

    // Add headers
    options.headers.forEach((key, value) {
      buffer.write(" -H '$key: $value'");
    });

    // Add request body (if applicable)
    if (options.data != null) {
      final data = options.data is Map ? options.data : options.data.toString();
      buffer.write(" -d '${data.toString()}'");
    }

    // Append URL
    buffer.write(" '${options.uri.toString()}'");

    // Log the cURL command
    "🔵 [API] cURL: ${buffer.toString()}".log();
  }
}
