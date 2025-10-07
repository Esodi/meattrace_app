import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

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

  // Touch target size constants (WCAG 2.1 AA compliant)
  static const double minTouchTargetSize = 44.0; // Updated to 44px minimum
  static const double recommendedTouchTargetSize = 48.0;

  // Color contrast utilities - WCAG 2.1 AA compliant
  static bool hasGoodTextContrast(Color foreground, Color background) {
    final double contrast = _calculateContrast(foreground, background);
    return contrast >= 4.5; // WCAG AA standard for text
  }

  static bool hasGoodGraphicsContrast(Color foreground, Color background) {
    final double contrast = _calculateContrast(foreground, background);
    return contrast >= 3.0; // WCAG AA standard for graphics
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

  // High contrast color utilities
  static Color getHighContrastColor(Color original, bool isHighContrast) {
    if (!isHighContrast) return original;

    // Convert to high contrast equivalents
    if (_isLightColor(original)) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  static bool _isLightColor(Color color) {
    return _getLuminance(color) > 0.5;
  }

  // Focus indicator styles
  static BoxDecoration getFocusIndicatorDecoration({
    required bool hasFocus,
    required bool isHighContrast,
    Color? focusColor,
  }) {
    if (!hasFocus) return const BoxDecoration();

    final Color indicatorColor = focusColor ?? (isHighContrast ? Colors.yellow : Colors.blue);
    return BoxDecoration(
      border: Border.all(
        color: indicatorColor,
        width: 2.0,
      ),
      borderRadius: BorderRadius.circular(4.0),
    );
  }

  // Keyboard shortcut handling
  static Map<LogicalKeySet, VoidCallback> getKeyboardShortcuts({
    VoidCallback? onSearch,
    VoidCallback? onToggleSidebar,
    VoidCallback? onToggleDarkMode,
    VoidCallback? onGridUp,
    VoidCallback? onGridDown,
    VoidCallback? onGridLeft,
    VoidCallback? onGridRight,
  }) {
    return {
      // Ctrl/Cmd + K for search
      LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK): onSearch ?? () {},
      LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyK): onSearch ?? () {},

      // Ctrl/Cmd + B for sidebar
      LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyB): onToggleSidebar ?? () {},
      LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyB): onToggleSidebar ?? () {},

      // Ctrl/Cmd + D for dark mode
      LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyD): onToggleDarkMode ?? () {},
      LogicalKeySet(LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyD): onToggleDarkMode ?? () {},

      // Arrow keys for grid navigation
      LogicalKeySet(LogicalKeyboardKey.arrowUp): onGridUp ?? () {},
      LogicalKeySet(LogicalKeyboardKey.arrowDown): onGridDown ?? () {},
      LogicalKeySet(LogicalKeyboardKey.arrowLeft): onGridLeft ?? () {},
      LogicalKeySet(LogicalKeyboardKey.arrowRight): onGridRight ?? () {},
    };
  }

  // Motion-aware animation duration
  static Duration getAnimationDuration(BuildContext context, {Duration defaultDuration = const Duration(milliseconds: 300)}) {
    return prefersReducedMotion(context) ? Duration.zero : defaultDuration;
  }

  // Accessible focus management
  static void requestFocus(FocusNode? focusNode) {
    if (focusNode != null && focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }

  static void moveFocus(BuildContext context, FocusNode from, FocusNode to) {
    from.unfocus();
    requestFocus(to);
  }

  static void moveFocusForward(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  static void moveFocusBackward(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }
}

class AccessibleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final bool enabled;
  final FocusNode? focusNode;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

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
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityUtils.isHighContrastEnabled(context);

    return Semantics(
      label: widget.semanticLabel,
      enabled: widget.enabled,
      button: true,
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          decoration: AccessibilityUtils.getFocusIndicatorDecoration(
            hasFocus: _hasFocus,
            isHighContrast: isHighContrast,
          ),
          child: Tooltip(
            message: widget.tooltip ?? '',
            child: InkWell(
              onTap: widget.enabled ? widget.onPressed : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: AccessibilityUtils.minTouchTargetSize,
                  minHeight: AccessibilityUtils.minTouchTargetSize,
                ),
                child: widget.child,
              ),
            ),
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

class AccessibleIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? semanticLabel;
  final String? tooltip;
  final bool enabled;
  final FocusNode? focusNode;

  const AccessibleIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.semanticLabel,
    this.tooltip,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<AccessibleIconButton> createState() => _AccessibleIconButtonState();
}

class _AccessibleIconButtonState extends State<AccessibleIconButton> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

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
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = AccessibilityUtils.isHighContrastEnabled(context);

    return Semantics(
      label: widget.semanticLabel,
      enabled: widget.enabled,
      button: true,
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          decoration: AccessibilityUtils.getFocusIndicatorDecoration(
            hasFocus: _hasFocus,
            isHighContrast: isHighContrast,
          ),
          child: IconButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            icon: Icon(widget.icon),
            tooltip: widget.tooltip,
            constraints: const BoxConstraints(
              minWidth: AccessibilityUtils.minTouchTargetSize,
              minHeight: AccessibilityUtils.minTouchTargetSize,
            ),
          ),
        ),
      ),
    );
  }
}

class AccessibleGrid extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double spacing;
  final VoidCallback? onUpPressed;
  final VoidCallback? onDownPressed;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;

  const AccessibleGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.spacing = 16.0,
    this.onUpPressed,
    this.onDownPressed,
    this.onLeftPressed,
    this.onRightPressed,
  });

  @override
  State<AccessibleGrid> createState() => _AccessibleGridState();
}

class _AccessibleGridState extends State<AccessibleGrid> {
  int _focusedIndex = -1;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.children.length, (index) => FocusNode());
    for (final node in _focusNodes) {
      node.addListener(() => _updateFocusedIndex());
    }
  }

  @override
  void didUpdateWidget(AccessibleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      // Dispose old nodes
      for (final node in _focusNodes) {
        node.dispose();
      }
      // Create new nodes
      _focusNodes = List.generate(widget.children.length, (index) => FocusNode());
      for (final node in _focusNodes) {
        node.addListener(() => _updateFocusedIndex());
      }
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _updateFocusedIndex() {
    setState(() {
      _focusedIndex = _focusNodes.indexWhere((node) => node.hasFocus);
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        widget.onUpPressed?.call();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        widget.onDownPressed?.call();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        widget.onLeftPressed?.call();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        widget.onRightPressed?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: widget.spacing,
          mainAxisSpacing: widget.spacing,
        ),
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          return Focus(
            focusNode: _focusNodes[index],
            child: widget.children[index],
          );
        },
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

// High contrast mode provider
class HighContrastProvider with ChangeNotifier {
  bool _isHighContrastEnabled = false;

  bool get isHighContrastEnabled => _isHighContrastEnabled;

  void toggleHighContrast() {
    _isHighContrastEnabled = !_isHighContrastEnabled;
    notifyListeners();
  }

  void setHighContrast(bool enabled) {
    if (_isHighContrastEnabled != enabled) {
      _isHighContrastEnabled = enabled;
      notifyListeners();
    }
  }
}

// Motion-aware animation wrapper
class AccessibleMotionWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AccessibleMotionWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = AccessibilityUtils.getAnimationDuration(context, defaultDuration: duration);
    return AnimatedSwitcher(
      duration: effectiveDuration,
      child: child,
    );
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







