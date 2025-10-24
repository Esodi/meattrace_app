import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_theme.dart';

/// Comprehensive notification service for displaying user feedback
/// Supports success, error, warning, and info messages with various display styles
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Show a success notification
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      message: message,
      title: title,
      type: NotificationType.success,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show an error notification
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      message: message,
      title: title,
      type: NotificationType.error,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show a warning notification
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      message: message,
      title: title,
      type: NotificationType.warning,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show an info notification
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      message: message,
      title: title,
      type: NotificationType.info,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show a loading notification (persistent until dismissed)
  static void showLoading(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _showNotification(
      context,
      message: message,
      title: title,
      type: NotificationType.loading,
      duration: const Duration(days: 1), // Effectively persistent
    );
  }

  /// Dismiss all active notifications
  static void dismissAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Internal method to show notifications
  static void _showNotification(
    BuildContext context, {
    required String message,
    String? title,
    required NotificationType type,
    required Duration duration,
    VoidCallback? onTap,
  }) {
    final config = _getNotificationConfig(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: config.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  config.icon,
                  color: config.iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(
                        title,
                        style: AppTypography.titleMedium().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: AppTypography.bodyMedium().copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Loading indicator for loading type
              if (type == NotificationType.loading) ...[
                const SizedBox(width: AppTheme.space12),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
        backgroundColor: config.backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.space16),
        elevation: 6,
        action: type != NotificationType.loading
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white.withValues(alpha: 0.9),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  /// Get notification configuration based on type
  static _NotificationConfig _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationConfig(
          icon: Icons.check_circle,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundColor: AppColors.success,
        );
      case NotificationType.error:
        return _NotificationConfig(
          icon: Icons.error,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundColor: AppColors.error,
        );
      case NotificationType.warning:
        return _NotificationConfig(
          icon: Icons.warning,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundColor: AppColors.warning,
        );
      case NotificationType.info:
        return _NotificationConfig(
          icon: Icons.info,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundColor: AppColors.info,
        );
      case NotificationType.loading:
        return _NotificationConfig(
          icon: Icons.hourglass_empty,
          iconColor: Colors.white,
          iconBackgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundColor: AppColors.textSecondary,
        );
    }
  }

  /// Show authentication-specific error messages
  static void showAuthError(BuildContext context, String errorMessage) {
    String userFriendlyMessage;
    String? title;

    // Parse common authentication errors
    if (errorMessage.contains('username already exists') ||
        errorMessage.contains('already registered')) {
      title = 'Account Already Exists';
      userFriendlyMessage = 'This username is already registered. Please try logging in or use a different username.';
    } else if (errorMessage.contains('Invalid credentials') ||
        errorMessage.contains('incorrect password') ||
        errorMessage.contains('wrong password')) {
      title = 'Invalid Credentials';
      userFriendlyMessage = 'The username or password you entered is incorrect. Please try again.';
    } else if (errorMessage.contains('User not found') ||
        errorMessage.contains('username not found')) {
      title = 'Account Not Found';
      userFriendlyMessage = 'No account found with this username. Please check your username or sign up.';
    } else if (errorMessage.contains('email already') ||
        errorMessage.contains('Email already registered')) {
      title = 'Email Already Registered';
      userFriendlyMessage = 'This email address is already associated with an account. Please use a different email or try logging in.';
    } else if (errorMessage.contains('invalid email') ||
        errorMessage.contains('email format')) {
      title = 'Invalid Email';
      userFriendlyMessage = 'Please enter a valid email address (e.g., user@example.com).';
    } else if (errorMessage.contains('password') && errorMessage.contains('requirement')) {
      title = 'Password Requirements Not Met';
      userFriendlyMessage = 'Password must be at least 6 characters long and contain letters and numbers.';
    } else if (errorMessage.contains('password') && errorMessage.contains('short')) {
      title = 'Password Too Short';
      userFriendlyMessage = 'Password must be at least 6 characters long.';
    } else if (errorMessage.contains('account locked') ||
        errorMessage.contains('too many attempts')) {
      title = 'Account Locked';
      userFriendlyMessage = 'Your account has been temporarily locked due to multiple failed login attempts. Please try again later.';
    } else if (errorMessage.contains('email verification') ||
        errorMessage.contains('verify your email')) {
      title = 'Email Verification Required';
      userFriendlyMessage = 'Please verify your email address before logging in. Check your inbox for the verification link.';
    } else if (errorMessage.contains('account disabled') ||
        errorMessage.contains('account suspended')) {
      title = 'Account Disabled';
      userFriendlyMessage = 'Your account has been disabled. Please contact support for assistance.';
    } else if (errorMessage.contains('session expired') ||
        errorMessage.contains('token expired')) {
      title = 'Session Expired';
      userFriendlyMessage = 'Your session has expired. Please log in again.';
    } else if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout')) {
      title = 'Connection Error';
      userFriendlyMessage = 'Unable to connect to the server. Please check your internet connection and try again.';
    } else if (errorMessage.contains('server error') ||
        errorMessage.contains('500') ||
        errorMessage.contains('503')) {
      title = 'Server Error';
      userFriendlyMessage = 'The server is experiencing issues. Please try again in a few moments.';
    } else {
      title = 'Authentication Error';
      userFriendlyMessage = errorMessage;
    }

    showError(
      context,
      userFriendlyMessage,
      title: title,
      duration: const Duration(seconds: 6),
    );
  }

  /// Show authentication success messages
  static void showAuthSuccess(BuildContext context, String action) {
    String message;
    String title;

    switch (action.toLowerCase()) {
      case 'login':
        title = 'Login Successful';
        message = 'Welcome back! Redirecting to your dashboard...';
        break;
      case 'signup':
      case 'register':
        title = 'Account Created';
        message = 'Your account has been created successfully. Welcome to MeatTrace Pro!';
        break;
      case 'logout':
        title = 'Logged Out';
        message = 'You have been logged out successfully.';
        break;
      case 'password_reset':
        title = 'Password Reset';
        message = 'Your password has been reset successfully. You can now log in with your new password.';
        break;
      case 'email_verified':
        title = 'Email Verified';
        message = 'Your email has been verified successfully.';
        break;
      default:
        title = 'Success';
        message = action;
    }

    showSuccess(
      context,
      message,
      title: title,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Notification types
enum NotificationType {
  success,
  error,
  warning,
  info,
  loading,
}

/// Internal notification configuration
class _NotificationConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;

  _NotificationConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.backgroundColor,
  });
}