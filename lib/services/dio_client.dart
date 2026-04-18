import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../utils/constants.dart';
import 'api_exception.dart';

class DioClient {
  static String get baseUrl => Constants.baseUrl;
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  late Dio _dio;
  VoidCallback? _onUnauthorized;

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

    _dio.interceptors.add(_AuthInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(_LoggingInterceptor());
    }
    _dio.interceptors.add(_ErrorInterceptor(this));
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

  void setOnUnauthorizedCallback(VoidCallback callback) {
    _onUnauthorized = callback;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/register/') ||
        options.path.contains('/token/')) {
      super.onRequest(options, handler);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(DioClient.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint(
      '╔════════════════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ 📤 HTTP REQUEST');
    debugPrint(
      '╠════════════════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ Method: ${options.method}');
    debugPrint('║ URL: ${options.uri}');
    debugPrint('║ Headers: ${options.headers}');
    debugPrint('║ Data Type: ${options.data.runtimeType}');
    debugPrint('║ Data: ${options.data}');
    debugPrint(
      '╚════════════════════════════════════════════════════════════════════════════',
    );

    developer.log('REQUEST[${options.method}] => PATH: ${options.path}');
    developer.log('REQUEST DATA: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '╔════════════════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ 📥 HTTP RESPONSE');
    debugPrint(
      '╠════════════════════════════════════════════════════════════════════════════',
    );
    debugPrint('║ Status: ${response.statusCode}');
    debugPrint('║ URL: ${response.requestOptions.uri}');
    debugPrint('║ Data Type: ${response.data.runtimeType}');
    debugPrint('║ Data: ${response.data}');
    debugPrint(
      '╚════════════════════════════════════════════════════════════════════════════',
    );

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
  final DioClient _dioClient;

  _ErrorInterceptor(this._dioClient);
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        'ERROR[${err.response?.statusCode}] ${err.requestOptions.method} '
        '${err.requestOptions.uri} — ${err.type}: ${err.message}',
      );
    }

    if (err.response?.statusCode == 401) {
      _clearTokensAsync();
      _dioClient._onUnauthorized?.call();
    }

    throw ApiException.fromDioException(err);
  }

  // Helper method to clear tokens asynchronously
  void _clearTokensAsync() {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(DioClient.accessTokenKey);
        await prefs.remove(DioClient.refreshTokenKey);
      } catch (e) {
        if (kDebugMode) {
          developer.log('Error clearing tokens: $e');
        }
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
