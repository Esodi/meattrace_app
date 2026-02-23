import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'dio_client.dart';
import 'storage_service.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final DioClient _dioClient = DioClient();
  static const String _userProfileKey = 'cached_user_profile';

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  DioClient get dioClient => _dioClient;

  Future<User> login(
    String username,
    String password, {
    String? sessionId,
  }) async {
    try {
      // Log the attempt for debugging
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('🔐 LOGIN ATTEMPT START');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('👤 Username: $username');
      if (sessionId != null) {
        debugPrint('🔑 Session ID: $sessionId');
      }
      debugPrint('🌐 Base URL: ${Constants.baseUrl}');
      debugPrint('📍 Login Endpoint: ${Constants.loginEndpoint}');
      debugPrint('🔗 Full URL: ${Constants.baseUrl}${Constants.loginEndpoint}');

      // Use JSON data for login endpoint (Django TokenObtainPairView expects JSON)
      final loginData = {
        'username': username,
        'password': password,
        if (sessionId != null) 'session_id': sessionId,
      };

      debugPrint('📤 Sending POST request with JSON data...');
      debugPrint('📦 Request body: $loginData');

      final response = await _dioClient.dio.post(
        Constants.loginEndpoint,
        data: loginData,
      );

      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('✅ LOGIN RESPONSE RECEIVED');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Data Type: ${response.data.runtimeType}');
      debugPrint(
        '📦 Response Keys: ${response.data is Map ? (response.data as Map).keys : 'N/A'}',
      );

      final tokens = response.data;
      final accessToken = tokens['access'];
      final refreshToken = tokens['refresh'];

      if (accessToken == null || refreshToken == null) {
        debugPrint('❌ Missing tokens in response!');
        debugPrint(
          '   Access Token: ${accessToken != null ? 'Present' : 'MISSING'}',
        );
        debugPrint(
          '   Refresh Token: ${refreshToken != null ? 'Present' : 'MISSING'}',
        );
        throw Exception('Invalid response: Missing tokens');
      }

      debugPrint('✅ Tokens extracted successfully');
      debugPrint(
        '   Access Token (first 20 chars): ${accessToken.toString().substring(0, 20)}...',
      );

      // Store tokens
      await _dioClient.setAuthTokens(accessToken, refreshToken);
      debugPrint('💾 Tokens stored in SharedPreferences');

      // Get user profile information from login response (includes has_pending_join_request)
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('👤 Parsing user data from login response...');

      final userData = tokens['user'];
      if (userData == null) {
        debugPrint(
          '⚠️ WARNING: No user data in login response, falling back to profile fetch',
        );
        final user = await _getUserProfile(accessToken);
        debugPrint('✅ User profile fetched: ${user.username} (${user.role})');
        debugPrint(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        );
        debugPrint('🎉 LOGIN SUCCESS');
        debugPrint(
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        );
        // Cache user profile for offline access
        await _cacheUserProfile(user);

        return user;
      }

      debugPrint(
        '📦 User data from login: ${userData is Map ? (userData).keys : 'N/A'}',
      );
      debugPrint(
        '🔍 has_pending_join_request: ${userData['has_pending_join_request']}',
      );

      final user = User.fromJson(userData);
      debugPrint('✅ User parsed: ${user.username} (${user.role})');
      debugPrint('⏳ hasPendingJoinRequest: ${user.hasPendingJoinRequest}');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('🎉 LOGIN SUCCESS');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );

      // Cache user profile for offline access
      await _cacheUserProfile(user);

      return user;
    } on DioException catch (e) {
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('❌ LOGIN FAILED - DioException');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('❌ Exception Type: ${e.type}');
      debugPrint('❌ Error Message: ${e.message}');
      debugPrint('❌ Request URI: ${e.requestOptions.uri}');
      debugPrint('❌ Request Method: ${e.requestOptions.method}');
      debugPrint('❌ Request Headers: ${e.requestOptions.headers}');

      if (e.response != null) {
        debugPrint('📄 Response Status: ${e.response?.statusCode}');
        debugPrint('📄 Response Data: ${e.response?.data}');
        debugPrint('📄 Response Headers: ${e.response?.headers}');
      } else {
        debugPrint('⚠️ No response received (connection issue)');
      }

      if (e.error != null) {
        debugPrint('🔴 Underlying Error: ${e.error}');
        debugPrint('🔴 Error Type: ${e.error.runtimeType}');
      }

      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );

      // Provide more specific error messages
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timeout. Server at ${Constants.baseUrl} is not responding.',
        );
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        throw Exception(
          'Cannot connect to server at ${Constants.baseUrl}.\n'
          'Please verify:\n'
          '1. Backend is running\n'
          '2. Your phone can access ${Constants.baseUrl}/health/ in browser\n'
          '3. Firewall is not blocking the connection',
        );
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
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('❌ LOGIN FAILED - Unexpected Error');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      debugPrint('❌ Error: $e');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      throw Exception('Login failed: $e');
    }
  }

  Future<User> register(
    String username,
    String email,
    String password,
    String role, {
    Map<String, dynamic>? additionalData,
    String? sessionId,
  }) async {
    try {
      debugPrint(
        '🔐 [FLUTTER_AUTH] Attempting registration for user: $username with role: $role',
      );
      if (sessionId != null) {
        debugPrint('🔑 [FLUTTER_AUTH] Session ID: $sessionId');
      }
      debugPrint('🌐 [FLUTTER_AUTH] Using base URL: ${Constants.baseUrl}');

      // Clear any existing local data before registration
      debugPrint(
        '🗑️ [FLUTTER_AUTH] Clearing existing local data before registration...',
      );
      final storageService = StorageService();
      await storageService.clearAllLocalData();
      debugPrint('   ✓ Local data cleared');

      final Map<String, dynamic> requestData = {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        if (sessionId != null) 'session_id': sessionId,
      };

      // Add any additional data (for processing units, shops, etc.)
      if (additionalData != null) {
        requestData.addAll(additionalData);
        debugPrint(
          '📦 [FLUTTER_AUTH] Including additional data: ${additionalData.keys.join(", ")}',
        );
        debugPrint('📦 [FLUTTER_AUTH] Additional data values: $additionalData');
      }

      debugPrint(
        '📤 [FLUTTER_AUTH] Sending registration request to: ${Constants.registerEndpoint}',
      );
      final response = await _dioClient.dio.post(
        Constants.registerEndpoint,
        data: requestData,
      );

      debugPrint(
        '✅ [FLUTTER_AUTH] Registration request successful, status: ${response.statusCode}',
      );
      debugPrint('📄 [FLUTTER_AUTH] Response data: ${response.data}');

      final data = response.data;
      final tokens = data['tokens'];
      final accessToken = tokens['access'];
      final refreshToken = tokens['refresh'];

      // Store tokens
      await _dioClient.setAuthTokens(accessToken, refreshToken);
      debugPrint('💾 [FLUTTER_AUTH] Tokens stored successfully');

      // Return user from response
      final userData = data['user'];
      final user = User.fromJson(userData);
      debugPrint(
        '✅ [FLUTTER_AUTH] User registered successfully: ${user.username} (role: ${user.role})',
      );

      // Cache user profile for offline access
      await _cacheUserProfile(user);

      return user;
    } on DioException catch (e) {
      debugPrint(
        '❌ [FLUTTER_AUTH] Registration failed with DioException: ${e.type} - ${e.message}',
      );
      if (e.response != null) {
        debugPrint(
          '📄 [FLUTTER_AUTH] Response status: ${e.response?.statusCode}',
        );
        debugPrint('📄 [FLUTTER_AUTH] Response data: ${e.response?.data}');
      }

      // Provide more specific error messages
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection and try again.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to server. Please check if the backend is running and accessible.',
        );
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('error')) {
          throw Exception(errorData['error']);
        }
        throw Exception('Invalid registration data. Please check your inputs.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Registration failed: ${e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint(
        '❌ [FLUTTER_AUTH] Registration failed with unexpected error: $e',
      );
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🚪 [AUTH_SERVICE] Starting logout process...');

      // 1. Clear authentication tokens
      await _dioClient.clearAuthTokens();
      debugPrint('   ✓ Auth tokens cleared');

      // 2. Clear all local storage (cached data)
      final storageService = StorageService();
      await storageService.clearAllLocalData();
      debugPrint('   ✓ Local data cleared');

      // 3. Clear cached user profile
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      debugPrint('   ✓ Cached profile cleared');

      debugPrint('✅ [AUTH_SERVICE] Logout completed successfully');
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> withdrawAccount() async {
    try {
      debugPrint(
        '🗑️ [AUTH_SERVICE] Withdrawing join request and deleting account...',
      );

      // Call backend to withdraw join request
      await _dioClient.dio.post('${Constants.joinRequestsEndpoint}withdraw/');

      debugPrint('✅ [AUTH_SERVICE] Join request withdrawn successfully');

      // Clear local data and tokens
      await logout();

      debugPrint('✅ [AUTH_SERVICE] Account withdrawal completed');
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Withdraw account error: $e');
      throw Exception('Failed to withdraw account: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _dioClient.getAccessToken();
      if (token == null) {
        debugPrint('ℹ️ No access token found');
        return false;
      }

      // Check if token is expired
      if (_isTokenExpired(token)) {
        debugPrint('⚠️ Access token expired, attempting refresh...');

        // Try to refresh the token
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          debugPrint('✅ Token refreshed successfully');
          return true;
        } else {
          debugPrint('❌ Token refresh failed, session expired');
          // Clear expired tokens
          await _dioClient.clearAuthTokens();
          return false;
        }
      }

      debugPrint('✅ Valid access token found');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking login status: $e');
      return false;
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _dioClient.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('⚠️ No refresh token available');
        return false;
      }

      // Check if refresh token is expired
      if (_isTokenExpired(refreshToken)) {
        debugPrint('⚠️ Refresh token expired');
        return false;
      }

      debugPrint('🔄 Attempting to refresh access token...');
      final response = await _dioClient.dio.post(
        Constants.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'];
      if (newAccessToken == null) {
        debugPrint('❌ No access token in refresh response');
        return false;
      }

      // Update only the access token (keep the same refresh token)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(DioClient.accessTokenKey, newAccessToken);

      debugPrint('✅ Access token refreshed successfully');
      return true;
    } on DioException catch (e) {
      debugPrint(
        '❌ Token refresh failed: ${e.response?.statusCode} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error during token refresh: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await _dioClient.getAccessToken();
      if (token == null) {
        debugPrint('ℹ️ No access token found');
        return null;
      }

      if (_isTokenExpired(token)) {
        debugPrint('⚠️ Access token expired, attempting refresh...');
        final refreshed = await _tryRefreshToken();
        if (!refreshed) {
          debugPrint('❌ Token refresh failed');
          await _dioClient.clearAuthTokens();
          return null;
        }
        // Get the new token after refresh
        final newToken = await _dioClient.getAccessToken();
        if (newToken == null) {
          return null;
        }
        return await _getUserProfile(newToken);
      }

      return await _getUserProfile(token);
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      // Fallback to cached profile if network fails
      return await _getCachedUserProfile();
    }
  }

  Future<void> _cacheUserProfile(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString(_userProfileKey, userJson);
      debugPrint('💾 [AUTH_SERVICE] User profile cached locally');
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Failed to cache user profile: $e');
    }
  }

  Future<User?> _getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userProfileKey);
      if (userJson != null) {
        debugPrint('👤 [AUTH_SERVICE] Loading cached user profile');
        return User.fromJson(json.decode(userJson));
      }
    } catch (e) {
      debugPrint('❌ [AUTH_SERVICE] Failed to load cached profile: $e');
    }
    return null;
  }

  Future<User> _getUserProfile(String accessToken) async {
    try {
      debugPrint(
        '👤 Fetching user profile from: ${Constants.baseUrl}${Constants.userProfileEndpoint}',
      );

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
      debugPrint(
        '❌ Profile fetch failed with DioException: ${e.type} - ${e.message}',
      );
      if (e.response != null) {
        debugPrint(
          '📄 Profile error response: ${e.response?.statusCode} - ${e.response?.data}',
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Timeout while fetching user profile. Please try again.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to get user profile: ${e.message ?? 'Unknown error'}',
        );
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

  // Permission checking methods
  bool hasPermission(User user, String permission, {int? processingUnitId}) {
    // Global admin permissions
    if (user.role.toLowerCase() == 'admin') {
      return true;
    }

    // Check processing unit specific permissions
    if (processingUnitId != null && user.processingUnitMemberships != null) {
      final membership = user.processingUnitMemberships!.firstWhere(
        (m) => m.processingUnitId == processingUnitId && m.isActive,
        orElse: () => ProcessingUnitMembership(
          id: -1,
          processingUnitId: -1,
          processingUnitName: '',
          role: '',
          permissions: '',
          isActive: false,
          isSuspended: false,
          invitedAt: DateTime.now(),
        ),
      );

      if (membership.id != -1) {
        return membership.canRead || membership.canWrite || membership.isAdmin;
      }
    }

    // Default permissions based on role
    final role = user.role.toLowerCase();
    switch (role) {
      case 'processingunit':
      case 'processing_unit':
      case 'processor':
        return permission == 'read' || permission == 'write';
      case 'abbatoir':
        return permission == 'read';
      case 'shop':
      case 'shopowner':
      case 'shop_owner':
        // Shop owners have full permissions for their shop
        return true;
      default:
        return false;
    }
  }

  bool canManageUsers(User user, {int? processingUnitId}) {
    final role = user.role.toLowerCase();

    if (role == 'admin') {
      return true;
    }

    // Shop owners can always manage users
    if (role == 'shop' || role == 'shopowner' || role == 'shop_owner') {
      return true;
    }

    if (processingUnitId != null && user.processingUnitMemberships != null) {
      final membership = user.processingUnitMemberships!.firstWhere(
        (m) => m.processingUnitId == processingUnitId && m.isActive,
        orElse: () => ProcessingUnitMembership(
          id: -1,
          processingUnitId: -1,
          processingUnitName: '',
          role: '',
          permissions: '',
          isActive: false,
          isSuspended: false,
          invitedAt: DateTime.now(),
        ),
      );

      return membership.id != -1 && membership.isAdmin;
    }

    return false;
  }

  bool isOwnerOrManager(User user, {int? processingUnitId}) {
    final role = user.role.toLowerCase();

    if (role == 'admin') {
      return true;
    }

    // Shop owners are owners
    if (role == 'shop' || role == 'shopowner' || role == 'shop_owner') {
      return true;
    }

    if (processingUnitId != null && user.processingUnitMemberships != null) {
      final membership = user.processingUnitMemberships!.firstWhere(
        (m) => m.processingUnitId == processingUnitId && m.isActive,
        orElse: () => ProcessingUnitMembership(
          id: -1,
          processingUnitId: -1,
          processingUnitName: '',
          role: '',
          permissions: '',
          isActive: false,
          isSuspended: false,
          invitedAt: DateTime.now(),
        ),
      );

      return membership.id != -1 &&
          (membership.role.toLowerCase() == 'owner' ||
              membership.role.toLowerCase() == 'manager' ||
              membership.isAdmin);
    }

    return false;
  }
}
