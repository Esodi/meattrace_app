import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/initialization_helper.dart';
import 'user_context_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserContextProvider _userContextProvider = UserContextProvider();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  UserContextProvider get userContext => _userContextProvider;

  // Lazy initializer for background auth check
  late final LazyInitializer<void> _authInitializer;

  AuthProvider() {
    _authInitializer = LazyInitializer(() => _checkLoginStatus());
    // Start initialization in background immediately
    _startBackgroundAuthCheck();
  }

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

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔍 Checking authentication status...');
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        debugPrint('✅ Session token found, fetching user profile...');
        try {
          _user = await _authService.getCurrentUser();
          if (_user != null) {
            _userContextProvider.setCurrentUser(_user!);
            debugPrint('✅ User profile loaded: ${_user!.username} (${_user!.role})');
          } else {
            debugPrint('⚠️ No user profile returned despite valid token');
          }
        } catch (e) {
          debugPrint('❌ Failed to fetch user profile: $e');
          // Clear invalid session
          await _authService.logout();
          _user = null;
          _userContextProvider.clearCurrentUser();
        }
      } else {
        debugPrint('ℹ️ No active session found');
      }
      _error = null;
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Session check error: $e');
      _error = e.toString();
      _user = null;
      _isInitialized = true; // Mark as initialized even on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ensures auth status is checked before proceeding
  Future<void> ensureInitialized() async {
    await _authInitializer.value;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(username, password);
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

  Future<bool> register(String username, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(username, email, password, role);
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
    notifyListeners();
  }
}







