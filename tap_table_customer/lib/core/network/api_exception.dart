import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException('Connection timeout. Please try again.');

      case DioExceptionType.sendTimeout:
        return ApiException('Request timeout while sending data.');

      case DioExceptionType.receiveTimeout:
        return ApiException('Response timeout from server.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        String message = 'Unexpected server error';

        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            message = data['message'].toString();
          } else if (data['title'] != null) {
            message = data['title'].toString();
          }
        }

        return ApiException(
          '$message (${statusCode ?? "Unknown"})',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.');

      case DioExceptionType.connectionError:
        return ApiException('No internet connection.');

      case DioExceptionType.badCertificate:
        return ApiException('Invalid SSL certificate.');

      case DioExceptionType.unknown:
        return ApiException(error.message ?? 'Unknown error occurred.');
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  String toString() => message;
}