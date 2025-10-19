import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer' as developer;
import '../utils/constants.dart';

class DioClient {
  static String get baseUrl => Constants.baseUrl;
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  late Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<void> setAuthTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(accessTokenKey, accessToken);
    await prefs.setString(refreshTokenKey, refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  Future<void> clearAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding authorization header for authentication endpoints
    if (options.path.contains('/register/') || options.path.contains('/token/')) {
      developer.log('AuthInterceptor: Skipping Authorization header for auth endpoint ${options.path}');
      super.onRequest(options, handler);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(DioClient.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      developer.log('AuthInterceptor: Added Authorization header for ${options.path}');
    } else {
      developer.log('AuthInterceptor: No token found for ${options.path}');
    }
    super.onRequest(options, handler);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('REQUEST[${options.method}] => PATH: ${options.path}');
    developer.log('REQUEST DATA: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    developer.log('RESPONSE DATA: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    developer.log('ERROR MESSAGE: ${err.message}');
    super.onError(err, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Enhanced logging for debugging
    developer.log('=== ERROR INTERCEPTOR DEBUG ===');
    developer.log('Request URL: ${err.requestOptions.uri}');
    developer.log('Request Method: ${err.requestOptions.method}');
    developer.log('Request Headers: ${err.requestOptions.headers}');
    developer.log('Request Data: ${err.requestOptions.data}');
    developer.log('Response Status Code: ${err.response?.statusCode}');
    developer.log('Response Headers: ${err.response?.headers}');
    developer.log('Response Data: ${err.response?.data}');
    developer.log('Response Data Type: ${err.response?.data?.runtimeType}');
    if (err.response?.data is List) {
      developer.log('Data is List with length: ${(err.response?.data as List).length}');
      developer.log('List contents: ${err.response?.data}');
    } else if (err.response?.data is Map) {
      developer.log('Data is Map with keys: ${(err.response?.data as Map).keys}');
      developer.log('Map contents: ${err.response?.data}');
    } else {
      developer.log('Data is neither List nor Map: ${err.response?.data}');
    }
    developer.log('Error Type: ${err.type}');
    developer.log('Error Message: ${err.message}');
    developer.log('================================');

    switch (err.response?.statusCode) {
      case 400:
        // Enhanced error message with full response data
        String errorMessage = 'Bad request';
        if (err.response?.data != null) {
          if (err.response?.data is Map) {
            final data = err.response?.data as Map;
            errorMessage = data['error'] ?? data['message'] ?? data.toString();
          } else {
            errorMessage = err.response?.data.toString() ?? 'Bad request';
          }
        }
        developer.log('BadRequestException: $errorMessage');
        throw BadRequestException(errorMessage);
      case 401:
        // Session expired or invalid token
        developer.log('🔒 Unauthorized: Session expired or invalid token');
        // Clear tokens on 401 (unless it's a refresh token request)
        if (!err.requestOptions.path.contains('/token/refresh/')) {
          _clearTokensAsync();
        }
        throw UnauthorizedException('Your session has expired. Please login again.');
      case 403:
        throw ForbiddenException('Forbidden');
      case 404:
        throw NotFoundException('Not found');
      case 500:
        String errorMessage = 'Internal server error';
        if (err.response?.data != null) {
          final data = err.response!.data;
          if (data is Map) {
            errorMessage = data['error'] ?? data.toString();
          } else if (data is List) {
            errorMessage = data.join(', ');
          } else {
            errorMessage = data.toString();
          }
        }
        throw ServerException(errorMessage);
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          throw NetworkException('Connection timeout. Please try again.');
        } else if (err.type == DioExceptionType.connectionError) {
          throw NetworkException(
            'Connection error. Please check your internet connection.',
          );
        } else {
          throw NetworkException('Network error: ${err.message}');
        }
    }
  }

  // Helper method to clear tokens asynchronously
  void _clearTokensAsync() {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(DioClient.accessTokenKey);
        await prefs.remove(DioClient.refreshTokenKey);
        developer.log('🗑️ Tokens cleared due to 401 error');
      } catch (e) {
        developer.log('❌ Error clearing tokens: $e');
      }
    });
  }
}

// Custom exceptions
class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);

  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);

  @override
  String toString() => message;
}








