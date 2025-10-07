import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/navigation_service.dart';

/// System-level navigation handler for Android back button and other
/// platform-specific navigation events
class SystemNavigationHandler {
  static SystemNavigationHandler? _instance;
  static SystemNavigationHandler get instance => _instance ??= SystemNavigationHandler._();
  
  SystemNavigationHandler._();

  /// Initialize system navigation handling
  void initialize() {
    // Handle Android system back button
    SystemChannels.platform.setMethodCallHandler(_handleSystemNavigation);
  }

  /// Handle system navigation events (primarily Android back button)
  Future<dynamic> _handleSystemNavigation(MethodCall call) async {
    if (call.method == 'SystemNavigator.pop') {
      // Get the current context from the navigator
      final context = NavigationService.instance.navigationHistory.isNotEmpty
          ? null // We'll need to get context from the current route
          : null;
      
      if (context != null) {
        // Use our enhanced navigation service
        final handled = await NavigationService.instance.handleSystemBack(context);
        if (handled) {
          return; // Prevent default system back behavior
        }
      }
    }
    
    // Allow default system behavior if not handled
    return null;
  }

  /// Create a WillPopScope wrapper that handles system back button
  static Widget wrapWithSystemBackHandler({
    required Widget child,
    required BuildContext context,
    String? userType,
    Map<String, dynamic>? preservedState,
    VoidCallback? onWillPop,
  }) {
    return WillPopScope(
      onWillPop: () async {
        // Custom onWillPop takes precedence
        if (onWillPop != null) {
          onWillPop();
          return false;
        }

        // Use our enhanced navigation service
        return await NavigationService.instance.smartNavigateBack(
          context: context,
          userType: userType,
          preservedState: preservedState,
        );
      },
      child: child,
    );
  }
}

/// Extension to easily wrap widgets with system back handling
extension SystemBackHandlerExtension on Widget {
  Widget withSystemBackHandler({
    required BuildContext context,
    String? userType,
    Map<String, dynamic>? preservedState,
    VoidCallback? onWillPop,
  }) {
    return SystemNavigationHandler.wrapWithSystemBackHandler(
      child: this,
      context: context,
      userType: userType,
      preservedState: preservedState,
      onWillPop: onWillPop,
    );
  }
}







