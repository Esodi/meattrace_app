import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../services/navigation_service.dart';

/// Enhanced back button widget with comprehensive navigation handling,
/// error recovery, state preservation, and cross-platform compatibility
class EnhancedBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final String? fallbackRoute;
  final Map<String, dynamic>? preservedState;
  final bool enableHapticFeedback;
  final bool showTooltip;
  final String? customTooltip;

  const EnhancedBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.fallbackRoute,
    this.preservedState,
    this.enableHapticFeedback = true,
    this.showTooltip = true,
    this.customTooltip,
  });

  @override
  State<EnhancedBackButton> createState() => _EnhancedBackButtonState();
}

class _EnhancedBackButtonState extends State<EnhancedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleBackNavigation() async {
    if (_isPressed) return; // Prevent double-tap
    
    setState(() {
      _isPressed = true;
    });

    try {
      // Haptic feedback for better UX
      if (widget.enableHapticFeedback) {
        await HapticFeedback.lightImpact();
      }

      // Animation feedback
      await _animationController.forward();
      await _animationController.reverse();

      // Custom onPressed handler takes priority
      if (widget.onPressed != null) {
        widget.onPressed!();
        return;
      }

      // Use NavigationService for robust navigation
      final navigationService = NavigationService.instance;
      final success = await navigationService.navigateBack(
        context: context,
        fallbackRoute: widget.fallbackRoute,
        preservedState: widget.preservedState,
      );

      if (!success) {
        // Show user-friendly error if navigation fails
        if (mounted) {
          _showNavigationError();
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        _showNavigationError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    }
  }

  void _showNavigationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Unable to navigate back. Please try again.'),
        backgroundColor: AppTheme.errorRed,
        action: SnackBarAction(
          label: 'Home',
          textColor: Colors.white,
          onPressed: () => context.go('/farmer-home'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: widget.color ?? Colors.white,
              size: 24,
            ),
            onPressed: _isPressed ? null : _handleBackNavigation,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        );
      },
    );

    if (!widget.showTooltip) {
      return button;
    }

    return Tooltip(
      message: widget.customTooltip ?? 'Go back',
      child: button,
    );
  }
}

/// Enhanced AppBar creation function with improved back button
AppBar createEnhancedAppBarWithBackButton({
  required String title,
  List<Widget>? actions,
  VoidCallback? onBackPressed,
  Color? backgroundColor,
  Color? foregroundColor,
  String? fallbackRoute,
  Map<String, dynamic>? preservedState,
  bool enableHapticFeedback = true,
}) {
  return AppBar(
    title: Text(title),
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    leading: EnhancedBackButton(
      onPressed: onBackPressed,
      fallbackRoute: fallbackRoute,
      preservedState: preservedState,
      enableHapticFeedback: enableHapticFeedback,
    ),
    leadingWidth: 56,
    actions: actions,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
  );
}

/// Backward compatibility - enhanced version of the original function
AppBar createAppBarWithBackButton({
  required String title,
  List<Widget>? actions,
  VoidCallback? onBackPressed,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  return createEnhancedAppBarWithBackButton(
    title: title,
    actions: actions,
    onBackPressed: onBackPressed,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    fallbackRoute: '/farmer-home', // Default fallback for livestock history
  );
}