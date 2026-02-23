import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/initialization_helper.dart';
import 'user_context_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserContextProvider _userContextProvider;

  AuthProvider(this._userContextProvider) {
    _authInitializer = LazyInitializer(() => _checkLoginStatus());
    _startBackgroundAuthCheck();
    _setupAutoLogout();
  }
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _isOfflineMode = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isOfflineMode => _isOfflineMode;
  UserContextProvider get userContext => _userContextProvider;

  // Lazy initializer for background auth check
  late final LazyInitializer<void> _authInitializer;

  Future<void> _startBackgroundAuthCheck() async {
    try {
      await _authInitializer.value;
    } catch (e) {
      // Handle initialization errors silently for now
      debugPrint('Auth initialization error: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    if (_isInitialized) return; // Already initialized

    debugPrint('🔍 [AUTH_PROVIDER] Checking authentication status...');

    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        debugPrint(
          '✅ [AUTH_PROVIDER] Session token found, fetching user profile...',
        );
        try {
          // Attempt to fetch profile from network
          _user = await _authService.getCurrentUser();

          if (_user != null) {
            _userContextProvider.setCurrentUser(_user!);

            // Check if we were forced to fallback to cache in AuthService
            // (AuthService getCurrentUser returns cached on error)
            // We can check connectivity here as well for better accuracy
            _isOfflineMode = false; // Reset to false by default

            debugPrint(
              '✅ [AUTH_PROVIDER] User profile loaded: ${_user!.username}',
            );
          }
        } catch (e) {
          debugPrint('❌ [AUTH_PROVIDER] Failed to fetch user profile: $e');

          // If getCurrentUser threw an error despite its own fallback,
          // we are definitely in trouble. But since our AuthService
          // getCurrentUser catches its own error and returns from cache,
          // we might not reach here unless cache also fails or logout happened.

          if (_user == null) {
            await _authService.logout();
            _userContextProvider.clearCurrentUser();
          } else {
            // We have a user from cache
            _isOfflineMode = true;
          }
        }
      } else {
        debugPrint('ℹ️ [AUTH_PROVIDER] No active session found');
      }
      _error = null;
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ [AUTH_PROVIDER] Session check error: $e');
      _error = e.toString();
      _user = null;
      _isInitialized = true;
    } finally {
      // Only notify at the very end of initialization
      _isLoading = false;
      debugPrint(
        '🔔 [AUTH_PROVIDER] Initialization finished, notifying listeners',
      );
      notifyListeners();
    }
  }

  /// Ensures auth status is checked before proceeding
  Future<void> ensureInitialized() async {
    await _authInitializer.value;
  }

  Future<bool> login(
    String username,
    String password, {
    String? sessionId,
  }) async {
    debugPrint('🔐 [AUTH_PROVIDER] Starting login process for user: $username');
    if (sessionId != null) {
      debugPrint('🆔 [AUTH_PROVIDER] Using session ID: $sessionId');
    }

    // Set loading state
    _isLoading = true;
    _error = null;
    notifyListeners();

    final startTime = DateTime.now();

    try {
      debugPrint(
        '🔄 [AUTH_PROVIDER] Calling _authService.login() with 30s timeout...',
      );

      // Add timeout to prevent infinite hanging
      _user = await _authService
          .login(username, password, sessionId: sessionId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint(
                '⏱️ [AUTH_PROVIDER] Login request timed out after 30 seconds',
              );
              throw Exception(
                'Login request timed out. Please check your connection and try again.',
              );
            },
          );

      final duration = DateTime.now().difference(startTime);
      debugPrint(
        '✅ [AUTH_PROVIDER] _authService.login() completed in ${duration.inMilliseconds}ms',
      );

      if (_user != null) {
        debugPrint(
          '👤 [AUTH_PROVIDER] Setting current user: ${_user!.username} (${_user!.role})',
        );
        _userContextProvider.setCurrentUser(_user!);
        _error = null;
        debugPrint(
          '⏳ [AUTH_PROVIDER] hasPendingJoinRequest: ${_user!.hasPendingJoinRequest}',
        );
        debugPrint(
          '📌 [AUTH_PROVIDER] pendingJoinRequestUnitName: ${_user!.pendingJoinRequestUnitName}',
        );
        debugPrint(
          '📌 [AUTH_PROVIDER] pendingJoinRequestRole: ${_user!.pendingJoinRequestRole}',
        );
      } else {
        debugPrint('⚠️ [AUTH_PROVIDER] Login returned null user');
        _error = 'Login failed: No user data received';
      }

      debugPrint('🎉 [AUTH_PROVIDER] Login successful, clearing loading state');
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint(
        '❌ [AUTH_PROVIDER] Login failed after ${duration.inMilliseconds}ms: $e',
      );
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String role, {
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        username,
        email,
        password,
        role,
        additionalData: additionalData,
      );
      if (_user != null) {
        _userContextProvider.setCurrentUser(_user!);
      }
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _userContextProvider.clearCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _isLoading = false; // Also clear loading state
    notifyListeners();
  }

  void _setupAutoLogout() {
    _authService.dioClient.setOnUnauthorizedCallback(_handleUnauthorized);
  }

  void _handleUnauthorized() {
    debugPrint('🚪 Automatic logout triggered due to token expiration');
    // Clear user state
    _user = null;
    _userContextProvider.clearCurrentUser();
    _error = 'Session expired. Please login again.';
    notifyListeners();
  }

  Future<bool> refreshProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.getCurrentUser();
      if (updatedUser != null) {
        _user = updatedUser;
        _userContextProvider.setCurrentUser(_user!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> withdrawAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.withdrawAccount();
      _user = null;
      _userContextProvider.clearCurrentUser();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
