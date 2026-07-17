import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../utils/constants.dart';

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

  // Mutex: only one refresh in flight at a time; other 401s wait for it.
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  _ErrorInterceptor(this._dioClient);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      developer.log(
        'ERROR[${err.response?.statusCode}] ${err.requestOptions.method} '
        '${err.requestOptions.uri} — ${err.type}: ${err.message}',
      );
    }

    final isAuthEndpoint =
        err.requestOptions.path.contains(Constants.loginEndpoint) ||
        err.requestOptions.path.contains(Constants.refreshTokenEndpoint);

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      // Attempt transparent token refresh before forcing logout.
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        try {
          // Retry original request with the new access token.
          final prefs = await SharedPreferences.getInstance();
          final newToken = prefs.getString(DioClient.accessTokenKey);
          final opts = err.requestOptions;
          if (newToken != null) {
            opts.headers['Authorization'] = 'Bearer $newToken';
          }
          final response = await _dioClient.dio.fetch(opts);
          handler.resolve(response);
          return;
        } catch (_) {
          // Retry failed — fall through to force logout.
        }
      }
      // Refresh unavailable or retry failed — clear session and notify app.
      await _clearTokens();
      _dioClient._onUnauthorized?.call();
    }

    // Must reject via the handler, not throw: throwing here produces an
    // unhandled Future rejection that Dio never chains into the original
    // request's future, so callers hang until an outer timeout fires
    // instead of seeing the real error immediately.
    handler.reject(err);
  }

  Future<bool> _tryRefreshToken() async {
    // If a refresh is already running, wait for its result.
    if (_isRefreshing) {
      return await (_refreshCompleter?.future ?? Future.value(false));
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _dioClient.getRefreshToken();
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // Use a bare Dio instance to avoid re-triggering this interceptor.
      final tempDio = Dio(
        BaseOptions(
          baseUrl: DioClient.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await tempDio.post(
        Constants.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'] as String?;
      if (newAccessToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(DioClient.accessTokenKey, newAccessToken);

      if (kDebugMode) developer.log('[DioClient] Access token refreshed.');
      _refreshCompleter!.complete(true);
      return true;
    } catch (e) {
      if (kDebugMode) developer.log('[DioClient] Token refresh failed: $e');
      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(DioClient.accessTokenKey);
      await prefs.remove(DioClient.refreshTokenKey);
    } catch (e) {
      if (kDebugMode) developer.log('Error clearing tokens: $e');
    }
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
