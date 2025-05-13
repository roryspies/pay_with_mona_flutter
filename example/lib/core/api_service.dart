import 'package:dio/dio.dart';
import 'package:example/core/exceptions.dart';
import '../core/config.dart';

class ApiService {
  late final Dio _dio;
  final String baseUrl;

  static const String _defaultBaseUrl = APIConfig.baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl {
    _dio = Dio(BaseOptions(baseUrl: this.baseUrl));
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.post(endpoint, data: data);
    } on DioException catch (e) {
      throw APIException.fromDioError(e);
    }
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParams);
    } on DioException catch (e) {
      throw APIException.fromDioError(e);
    }
  }
}
