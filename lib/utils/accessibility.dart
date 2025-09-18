import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibilityUtils {
  // Screen reader announcements
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // High contrast mode detection
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  // Large text scale detection
  static bool hasLargeText(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor > 1.2;
  }

  // Reduced motion detection
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  // Touch target size constants
  static const double minTouchTargetSize = 48.0;
  static const double recommendedTouchTargetSize = 56.0;

  // Color contrast utilities
  static bool hasGoodContrast(Color foreground, Color background) {
    // Simple contrast calculation (in real app, use proper WCAG formula)
    final double contrast = _calculateContrast(foreground, background);
    return contrast >= 4.5; // WCAG AA standard
  }

  static double _calculateContrast(Color fg, Color bg) {
    final double fgLuminance = _getLuminance(fg);
    final double bgLuminance = _getLuminance(bg);
    final double lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final double darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _getLuminance(Color color) {
    final double r = color.red / 255.0;
    final double g = color.green / 255.0;
    final double b = color.blue / 255.0;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}

class AccessibleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final bool enabled;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      enabled: enabled,
      button: true,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AccessibilityUtils.minTouchTargetSize,
              minHeight: AccessibilityUtils.minTouchTargetSize,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: onTap != null,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AccessibilityUtils.minTouchTargetSize,
            ),
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticLabel;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AccessibleIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? 'Icon',
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}

class FocusableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final FocusNode? focusNode;

  const FocusableWidget({
    super.key,
    required this.child,
    this.onFocus,
    this.onBlur,
    this.focusNode,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocus?.call();
    } else {
      widget.onBlur?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}

// Keyboard navigation utilities
class KeyboardNavigation {
  static void moveFocus(BuildContext context, FocusNode current, FocusNode next) {
    current.unfocus();
    FocusScope.of(context).requestFocus(next);
  }

  static void moveFocusUp(BuildContext context, FocusNode current) {
    FocusScope.of(context).previousFocus();
  }

  static void moveFocusDown(BuildContext context, FocusNode current) {
    FocusScope.of(context).nextFocus();
  }
}

// Screen reader friendly loading indicator
class AccessibleLoadingIndicator extends StatelessWidget {
  final String message;

  const AccessibleLoadingIndicator({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: const CircularProgressIndicator(),
    );
  }
}

// Error announcement utility
class ErrorAnnouncer extends StatelessWidget {
  final String errorMessage;
  final Widget child;

  const ErrorAnnouncer({
    super.key,
    required this.errorMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Announce error when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityUtils.announce('Error: $errorMessage');
    });

    return child;
  }
}