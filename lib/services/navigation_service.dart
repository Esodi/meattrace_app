import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
}