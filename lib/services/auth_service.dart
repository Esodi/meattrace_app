import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      // Log the attempt for debugging
      debugPrint('🔐 Attempting login for user: $username');
      debugPrint('🌐 Using base URL: ${Constants.baseUrl}');
      
      // Use FormData for login endpoint (TokenObtainPairView expects form data)
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      debugPrint('📤 Sending login request to: ${Constants.baseUrl}${Constants.loginEndpoint}');
      
      final response = await _dioClient.dio.post(
        Constants.loginEndpoint,
        data: formData,
      );

      debugPrint('✅ Login request successful, status: ${response.statusCode}');
      
      final tokens = response.data;
      final accessToken = tokens['access'];
      final refreshToken = tokens['refresh'];

      if (accessToken == null || refreshToken == null) {
        throw Exception('Invalid response: Missing tokens');
      }

      // Store tokens
      await _dioClient.setAuthTokens(accessToken, refreshToken);
      debugPrint('💾 Tokens stored successfully');

      // Get user profile information
      debugPrint('👤 Fetching user profile...');
      final user = await _getUserProfile(accessToken);
      debugPrint('✅ User profile fetched successfully: ${user.username}');

      return user;
    } on DioException catch (e) {
      debugPrint('❌ Login failed with DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('📄 Response status: ${e.response?.statusCode}');
        debugPrint('📄 Response data: ${e.response?.data}');
      }
      
      // Provide more specific error messages
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Please check if the backend is running and accessible.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password.');
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('non_field_errors')) {
          throw Exception(errorData['non_field_errors'][0]);
        }
        throw Exception('Invalid login credentials.');
      } else {
        throw Exception('Login failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ Login failed with unexpected error: $e');
      throw Exception('Login failed: $e');
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
      return await _getUserProfile(token);
    }
    return null;
  }

  Future<User> _getUserProfile(String accessToken) async {
    try {
      debugPrint('👤 Fetching user profile from: ${Constants.baseUrl}${Constants.userProfileEndpoint}');
      
      // Create a temporary Dio instance with the token for this request
      final tempDio = Dio(
        BaseOptions(
          baseUrl: Constants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Get user profile from the dedicated endpoint
      final response = await tempDio.get(Constants.userProfileEndpoint);
      debugPrint('✅ Profile response status: ${response.statusCode}');
      debugPrint('📄 Profile data: ${response.data}');
      
      final profileData = response.data;

      if (profileData == null) {
        throw Exception('Empty profile response');
      }

      return User.fromJson(profileData);
    } on DioException catch (e) {
      debugPrint('❌ Profile fetch failed with DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('📄 Profile error response: ${e.response?.statusCode} - ${e.response?.data}');
      }
      
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout while fetching user profile. Please try again.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to get user profile: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('❌ Profile fetch failed with unexpected error: $e');
      throw Exception('Failed to get user profile: $e');
    }
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







