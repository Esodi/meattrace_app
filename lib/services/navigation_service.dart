import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Enum representing different navigation contexts in the app
enum NavigationContext {
  home,
  list,
  detail,
  form,
  settings,
  scan,
  transfer,
  order,
  inventory,
  unknown,
}

/// Enum representing back button navigation context (root vs navigated access)
enum BackNavigationContext {
  root,           // Home screen as app entry point
  navigated,      // Navigated to from another screen
  deepLink,       // Opened via deep link
}

/// Comprehensive navigation service with error handling, state preservation,
/// and fallback mechanisms for robust back button functionality
class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();
  
  NavigationService._();

  // Navigation history tracking
  final List<String> _navigationHistory = [];
  final Map<String, Map<String, dynamic>> _preservedStates = {};
  
  // Default fallback routes for different user types
  static const Map<String, String> _defaultFallbacks = {
    'farmer': '/farmer-home',
    'processor': '/processor-home',
    'shop': '/shop-home',
    'default': '/home',
  };

  /// Navigate back with comprehensive error handling and fallback mechanisms
  Future<bool> navigateBack({
    required BuildContext context,
    String? fallbackRoute,
    Map<String, dynamic>? preservedState,
    String? userType,
  }) async {
    try {
      // Save current state if provided
      if (preservedState != null) {
        await _saveCurrentState(context, preservedState);
      }

      // Check if we can pop the current route
      if (context.canPop()) {
        context.pop();
        _updateNavigationHistory(context);
        return true;
      }

      // If we can't pop, try to navigate to a fallback route
      return await _navigateToFallback(
        context,
        fallbackRoute,
        userType,
      );
    } catch (e) {
      // If all else fails, navigate to fallback
      return await _navigateToFallback(
        context,
        fallbackRoute,
        userType,
      );
    }
  }

  /// Navigate to fallback route with error handling
  Future<bool> _navigateToFallback(
    BuildContext context,
    String? fallbackRoute,
    String? userType,
  ) async {
    try {
      final route = fallbackRoute ?? 
                   _defaultFallbacks[userType ?? 'default'] ?? 
                   _defaultFallbacks['default']!;
      
      context.go(route);
      return true;
    } catch (e) {
      // Last resort - try to navigate to root
      try {
        context.go('/');
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  /// Save current page state for restoration
  Future<void> _saveCurrentState(
    BuildContext context,
    Map<String, dynamic> state,
  ) async {
    try {
      final currentRoute = GoRouterState.of(context).uri.toString();
      _preservedStates[currentRoute] = state;
      
      // Also save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'navigation_state_$currentRoute',
        json.encode(state),
      );
    } catch (e) {
      // Ignore storage errors - state preservation is not critical
    }
  }

  /// Save state for a route
  Future<void> saveState(String route, Map<String, dynamic> state) async {
    try {
      _preservedStates[route] = state;

      // Also save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'navigation_state_$route',
        json.encode(state),
      );
    } catch (e) {
      // Ignore storage errors - state preservation is not critical
    }
  }

  /// Restore saved state for a route
  Future<Map<String, dynamic>?> restoreState(String route) async {
    try {
      // First check in-memory cache
      if (_preservedStates.containsKey(route)) {
        return _preservedStates[route];
      }

      // Then check persistent storage
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('navigation_state_$route');
      if (stateJson != null) {
        final state = json.decode(stateJson) as Map<String, dynamic>;
        _preservedStates[route] = state;
        return state;
      }
    } catch (e) {
      // Ignore restoration errors
    }
    return null;
  }

  /// Clear saved state for a route
  Future<void> clearState(String route) async {
    try {
      _preservedStates.remove(route);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('navigation_state_$route');
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Update navigation history tracking
  void _updateNavigationHistory(BuildContext context) {
    try {
      final currentRoute = GoRouterState.of(context).uri.toString();
      _navigationHistory.add(currentRoute);
      
      // Keep only last 10 routes to prevent memory issues
      if (_navigationHistory.length > 10) {
        _navigationHistory.removeAt(0);
      }
    } catch (e) {
      // Ignore history tracking errors
    }
  }

  /// Get navigation history
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// Check if navigation back is possible
  bool canNavigateBack(BuildContext context) {
    try {
      return context.canPop() || _navigationHistory.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the back navigation context (root vs navigated access)
  BackNavigationContext getBackNavigationContext(BuildContext context) {
    try {
      final canPop = context.canPop();
      final hasHistory = _navigationHistory.isNotEmpty;

      debugPrint('🔍 [NavigationService] getBackNavigationContext:');
      debugPrint('   - canPop: $canPop');
      debugPrint('   - hasHistory: $hasHistory');
      debugPrint('   - navigationHistory length: ${_navigationHistory.length}');

      if (canPop || hasHistory) {
        debugPrint('   → Returning: BackNavigationContext.navigated');
        return BackNavigationContext.navigated;
      }
      debugPrint('   → Returning: BackNavigationContext.root');
      return BackNavigationContext.root;
    } catch (e) {
      debugPrint('   → Error getting context: $e, returning root');
      return BackNavigationContext.root;
    }
  }

  /// Get the current navigation context based on the route
  NavigationContext getNavigationContext(BuildContext context) {
    try {
      final currentRoute = GoRouterState.of(context).uri.toString();

      if (currentRoute.contains('/home') || currentRoute == '/') {
        return NavigationContext.home;
      } else if (currentRoute.contains('/list') || currentRoute.contains('/history')) {
        return NavigationContext.list;
      } else if (currentRoute.contains('/detail') || currentRoute.contains('/trace')) {
        return NavigationContext.detail;
      } else if (currentRoute.contains('/create') || currentRoute.contains('/register') ||
                 currentRoute.contains('/edit') || currentRoute.contains('/form')) {
        return NavigationContext.form;
      } else if (currentRoute.contains('/settings') || currentRoute.contains('/config')) {
        return NavigationContext.settings;
      } else if (currentRoute.contains('/scan') || currentRoute.contains('/qr')) {
        return NavigationContext.scan;
      } else if (currentRoute.contains('/transfer') || currentRoute.contains('/select')) {
        return NavigationContext.transfer;
      } else if (currentRoute.contains('/order') || currentRoute.contains('/place')) {
        return NavigationContext.order;
      } else if (currentRoute.contains('/inventory')) {
        return NavigationContext.inventory;
      }

      return NavigationContext.unknown;
    } catch (e) {
      return NavigationContext.unknown;
    }
  }

  /// Smart navigation that considers user context and app state
  Future<bool> smartNavigateBack({
    required BuildContext context,
    String? userType,
    Map<String, dynamic>? preservedState,
  }) async {
    // Determine the best fallback based on user type and current context
    String? fallbackRoute;
    
    if (userType != null) {
      fallbackRoute = _defaultFallbacks[userType];
    } else {
      // Try to infer user type from current route
      final currentRoute = GoRouterState.of(context).uri.toString();
      if (currentRoute.contains('farmer')) {
        fallbackRoute = _defaultFallbacks['farmer'];
      } else if (currentRoute.contains('processor')) {
        fallbackRoute = _defaultFallbacks['processor'];
      } else if (currentRoute.contains('shop')) {
        fallbackRoute = _defaultFallbacks['shop'];
      }
    }

    return await navigateBack(
      context: context,
      fallbackRoute: fallbackRoute,
      preservedState: preservedState,
      userType: userType,
    );
  }

  /// Handle system back button (Android)
  Future<bool> handleSystemBack(BuildContext context) async {
    return await smartNavigateBack(context: context);
  }

  /// Smart navigation back that considers the current navigation context
  Future<bool> smartNavigateBackWithContext({
    required BuildContext context,
    String? userType,
    Map<String, dynamic>? preservedState,
  }) async {
    final currentContext = getNavigationContext(context);

    // Define context-specific fallback routes
    String? contextFallbackRoute;
    switch (currentContext) {
      case NavigationContext.detail:
        // From detail screens, go back to list or home
        contextFallbackRoute = _getListRouteForUserType(userType);
        break;
      case NavigationContext.form:
        // From forms, go back to list or home
        contextFallbackRoute = _getListRouteForUserType(userType);
        break;
      case NavigationContext.scan:
        // From scan screens, go back to home
        contextFallbackRoute = _getHomeRouteForUserType(userType);
        break;
      case NavigationContext.transfer:
        // From transfer screens, go back to inventory
        contextFallbackRoute = _getInventoryRouteForUserType(userType);
        break;
      case NavigationContext.order:
        // From order screens, go back to home
        contextFallbackRoute = _getHomeRouteForUserType(userType);
        break;
      case NavigationContext.settings:
        // From settings, go back to home
        contextFallbackRoute = _getHomeRouteForUserType(userType);
        break;
      case NavigationContext.list:
      case NavigationContext.inventory:
        // From lists, go back to home
        contextFallbackRoute = _getHomeRouteForUserType(userType);
        break;
      case NavigationContext.home:
      case NavigationContext.unknown:
        // From home or unknown, use default fallback
        contextFallbackRoute = _defaultFallbacks[userType ?? 'default'];
        break;
    }

    return await navigateBack(
      context: context,
      fallbackRoute: contextFallbackRoute,
      preservedState: preservedState,
      userType: userType,
    );
  }

  /// Smart navigation back that considers back navigation context (root vs navigated)
  Future<bool> smartNavigateBackWithBackContext({
    required BuildContext context,
    required BackNavigationContext backContext,
    String? userType,
    Map<String, dynamic>? preservedState,
  }) async {
    debugPrint('🚀 [NavigationService] smartNavigateBackWithBackContext:');
    debugPrint('   - backContext: $backContext');
    debugPrint('   - userType: $userType');

    // For root access, return false to let screen handle exit logic
    if (backContext == BackNavigationContext.root) {
      debugPrint('   → Root context detected, returning false for exit handling');
      return false;
    }

    // For navigated access, perform normal smart navigation
    debugPrint('   → Navigated context detected, performing smart navigation');
    return await smartNavigateBack(
      context: context,
      userType: userType,
      preservedState: preservedState,
    );
  }

  /// Get appropriate list route for user type
  String? _getListRouteForUserType(String? userType) {
    switch (userType) {
      case 'farmer':
        return '/farmer/livestock-history';
      case 'processor':
        return '/processor/inventory';
      case 'shop':
        return '/shop/products';
      default:
        return '/home';
    }
  }

  /// Get appropriate home route for user type
  String? _getHomeRouteForUserType(String? userType) {
    switch (userType) {
      case 'farmer':
        return '/farmer-home';
      case 'processor':
        return '/processor-home';
      case 'shop':
        return '/shop-home';
      default:
        return '/home';
    }
  }

  /// Get appropriate inventory route for user type
  String? _getInventoryRouteForUserType(String? userType) {
    switch (userType) {
      case 'farmer':
        return '/farmer/livestock-history';
      case 'processor':
        return '/processor/inventory';
      case 'shop':
        return '/shop/products';
      default:
        return '/home';
    }
  }

  /// Clear all navigation data (useful for logout)
  Future<void> clearAllNavigationData() async {
    try {
      _navigationHistory.clear();
      _preservedStates.clear();
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('navigation_state_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

/// Extension to add navigation helpers to BuildContext
extension NavigationExtension on BuildContext {
  /// Enhanced back navigation with error handling
  Future<bool> navigateBackSafely({
    String? fallbackRoute,
    Map<String, dynamic>? preservedState,
    String? userType,
  }) async {
    return await NavigationService.instance.navigateBack(
      context: this,
      fallbackRoute: fallbackRoute,
      preservedState: preservedState,
      userType: userType,
    );
  }

  /// Smart back navigation that considers context
  Future<bool> smartNavigateBack({
    String? userType,
    Map<String, dynamic>? preservedState,
  }) async {
    return await NavigationService.instance.smartNavigateBack(
      context: this,
      userType: userType,
      preservedState: preservedState,
    );
  }

  /// Smart back navigation that considers navigation context
  Future<bool> smartNavigateBackWithContext({
    String? userType,
    Map<String, dynamic>? preservedState,
  }) async {
    return await NavigationService.instance.smartNavigateBackWithContext(
      context: this,
      userType: userType,
      preservedState: preservedState,
    );
  }

  /// Smart back navigation that considers back navigation context (root vs navigated)
  Future<bool> smartNavigateBackWithBackContext({
    required BackNavigationContext backContext,
    String? userType,
    Map<String, dynamic>? preservedState,
  }) async {
    return await NavigationService.instance.smartNavigateBackWithBackContext(
      context: this,
      backContext: backContext,
      userType: userType,
      preservedState: preservedState,
    );
  }
}







