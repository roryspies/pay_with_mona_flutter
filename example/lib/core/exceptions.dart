import 'package:dio/dio.dart';

class APIException implements Exception {
  final String message;
  APIException(this.message);

  @override
  String toString() => message;
  factory APIException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return APIException("Connection timeout");
      case DioExceptionType.receiveTimeout:
        return APIException("Receive timeout");
      case DioExceptionType.badResponse:
        return APIException("Server error: ${error.response?.statusCode}");
      default:
        return APIException("Unexpected error: ${error.message}");
    }
  }
}
