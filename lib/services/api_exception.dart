import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic responseData;

  ApiException({
    this.statusCode,
    required this.message,
    this.responseData,
  });

  factory ApiException.fromDioException(DioException e) {
    String message = 'An unknown error occurred';
    if (e.response != null) {
      // Try to parse a meaningful error message from the response
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        message = data['detail'] ?? data['error'] ?? 'An error occurred';
      } else if (data is String) {
        message = data;
      }
    } else {
      message = e.message ?? 'Network error';
    }

    return ApiException(
      statusCode: e.response?.statusCode,
      message: message,
      responseData: e.response?.data,
    );
  }

  @override
  String toString() {
    return 'ApiException: [$statusCode] $message';
  }
}