import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final DioClient _dioClient = DioClient();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<User> login(String username, String password) async {
    try {
      final response = await _dioClient.dio.post(
        Constants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      final tokens = response.data;
      final accessToken = tokens['access'];
      final refreshToken = tokens['refresh'];

      // Store tokens
      await _dioClient.setAuthTokens(accessToken, refreshToken);

      // Decode access token to get user info
      final payload = _decodeToken(accessToken);
      final user = User.fromJson(payload);

      return user;
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<User> register(String username, String email, String password, String role) async {
    try {
      final response = await _dioClient.dio.post(
        Constants.registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final data = response.data;
      final tokens = data['tokens'];
      final accessToken = tokens['access'];
      final refreshToken = tokens['refresh'];

      // Store tokens
      await _dioClient.setAuthTokens(accessToken, refreshToken);

      // Return user from response
      final userData = data['user'];
      final user = User.fromJson(userData);

      return user;
    } on DioException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.clearAuthTokens();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _dioClient.getAccessToken();
    return token != null && !_isTokenExpired(token);
  }

  Future<User?> getCurrentUser() async {
    final token = await _dioClient.getAccessToken();
    if (token != null && !_isTokenExpired(token)) {
      final payload = _decodeToken(token);
      return User.fromJson(payload);
    }
    return null;
  }

  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }

  bool _isTokenExpired(String token) {
    try {
      final payload = _decodeToken(token);
      final exp = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < now;
    } catch (e) {
      return true;
    }
  }
}