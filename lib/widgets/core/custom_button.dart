import 'package:flutter/material.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// MeatTrace Pro - Custom Button Components
/// Reusable button widgets with consistent styling

enum ButtonVariant {
  primary,    // Filled button with primary color
  secondary,  // Outlined button
  text,       // Text button
  icon,       // Icon button
  fab,        // Floating action button
}

enum ButtonSize {
  small,      // 36px height
  medium,     // 48px height (default)
  large,      // 56px height
}

class CustomButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool fullWidth;
  final bool loading;
  final Color? customColor;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const CustomButton({
    Key? key,
    this.label,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
    this.loading = false,
    this.customColor,
    this.leadingIcon,
    this.trailingIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || loading;
    
    // Determine button height based on size
    double height;
    double fontSize;
    double iconSize;
    
    switch (size) {
      case ButtonSize.small:
        height = 36;
        fontSize = 12;
        iconSize = 18;
        break;
      case ButtonSize.large:
        height = 56;
        fontSize = 16;
        iconSize = 28;
        break;
      case ButtonSize.medium:
        height = 48;
        fontSize = 14;
        iconSize = 24;
        break;
    }
    
    final buttonColor = customColor ?? theme.colorScheme.primary;
    
    Widget buttonChild;
    
    if (loading) {
      buttonChild = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary ? Colors.white : buttonColor,
          ),
        ),
      );
    } else if (icon != null && label == null) {
      // Icon-only button
      buttonChild = Icon(icon, size: iconSize);
    } else if (icon != null && label != null) {
      // Icon + Label button
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            SizedBox(width: AppTheme.space8),
          ],
          if (icon != null && leadingIcon == null) ...[
            Icon(icon, size: iconSize),
            SizedBox(width: AppTheme.space8),
          ],
          Flexible(
            child: Text(
              label!,
              style: AppTypography.button().copyWith(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: AppTheme.space8),
            trailingIcon!,
          ],
        ],
      );
    } else if (label != null) {
      // Label-only button
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            leadingIcon!,
            SizedBox(width: AppTheme.space8),
          ],
          Flexible(
            child: Text(
              label!,
              style: AppTypography.button().copyWith(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: AppTheme.space8),
            trailingIcon!,
          ],
        ],
      );
    } else {
      buttonChild = const SizedBox.shrink();
    }
    
    Widget button;
    
    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
            elevation: AppTheme.elevationLevel2,
            padding: EdgeInsets.symmetric(
              horizontal: size == ButtonSize.small ? AppTheme.space16 : AppTheme.space24,
              vertical: size == ButtonSize.small ? AppTheme.space8 : AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            minimumSize: Size(
              fullWidth ? double.infinity : 0,
              height,
            ),
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor, width: 1.5),
            disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            padding: EdgeInsets.symmetric(
              horizontal: size == ButtonSize.small ? AppTheme.space16 : AppTheme.space24,
              vertical: size == ButtonSize.small ? AppTheme.space8 : AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            minimumSize: Size(
              fullWidth ? double.infinity : 0,
              height,
            ),
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: buttonColor,
            disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            padding: EdgeInsets.symmetric(
              horizontal: size == ButtonSize.small ? AppTheme.space12 : AppTheme.space16,
              vertical: size == ButtonSize.small ? AppTheme.space4 : AppTheme.space8,
            ),
            minimumSize: Size(
              fullWidth ? double.infinity : 0,
              height,
            ),
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.icon:
        button = IconButton(
          onPressed: isDisabled ? null : onPressed,
          icon: buttonChild,
          color: buttonColor,
          disabledColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
          iconSize: iconSize,
        );
        break;
        
      case ButtonVariant.fab:
        button = FloatingActionButton(
          onPressed: isDisabled ? null : onPressed,
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          child: buttonChild,
        );
        break;
    }
    
    return button;
  }
}

/// Primary Button - Shorthand for filled button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;
  final ButtonSize size;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
    this.size = ButtonSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      fullWidth: fullWidth,
      loading: loading,
      size: size,
    );
  }
}

/// Secondary Button - Shorthand for outlined button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;
  final ButtonSize size;

  const SecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.loading = false,
    this.size = ButtonSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      fullWidth: fullWidth,
      loading: loading,
      size: size,
    );
  }
}

/// Icon Button with consistent styling
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final String? tooltip;

  const CustomIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = CustomButton(
      icon: icon,
      onPressed: onPressed,
      variant: ButtonVariant.icon,
      customColor: color,
    );
    
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}

/// Floating Action Button with consistent styling
class CustomFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool mini;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomFAB({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.mini = false,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget fab;

    if (label != null) {
      // Extended FAB with label
      fab = FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      );
    } else {
      // Regular FAB
      fab = FloatingActionButton(
        onPressed: onPressed,
        mini: mini,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: Icon(icon),
      );
    }

    return fab;
  }
}
