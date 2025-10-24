import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../animations/skeleton_loader.dart';

/// MeatTrace Pro - Custom Card Components
/// Reusable card widgets with consistent styling

enum CardVariant {
  elevated,   // Standard elevated card
  outlined,   // Card with border outline
  filled,     // Filled background card
}

class CustomCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final double? elevation;
  final double? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final CardVariant variant;
  final bool selected;

  const CustomCard({
    Key? key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.variant = CardVariant.elevated,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final cardElevation = elevation ?? (variant == CardVariant.elevated ? AppTheme.elevationLevel2 : 0);
    final radius = borderRadius ?? AppTheme.radiusMedium;
    
    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: variant == CardVariant.outlined || selected
            ? Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : borderColor ?? AppColors.textSecondary.withValues(alpha: 0.2),
                width: selected ? 2 : (borderWidth ?? 1),
              )
            : null,
        boxShadow: cardElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.space16),
              child: child,
            ),
          ),
        ),
      ),
    );

    return card;
  }
}

/// Info Card - Card with icon, title, and value
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InfoCard({
    Key? key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: cardColor,
                size: AppTheme.iconLarge,
              ),
            ),
            const SizedBox(width: AppTheme.space16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  value,
                  style: AppTypography.headlineSmall(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Stats Card - Card with numeric value and label
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final Widget? trend;
  final VoidCallback? onTap;
  final bool isLoading;

  const StatsCard({
    Key? key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.subtitle,
    this.trend,
    this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statColor = color ?? theme.colorScheme.primary;
    if (isLoading) {
      return const StatsCardSkeleton();
    }

    return CustomCard(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: statColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: statColor,
                  size: AppTheme.iconMedium,
                ),
              ),
            const SizedBox(height: AppTheme.space12),
            Text(
              value,
              style: AppTypography.numericLarge(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (trend != null) trend!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.space4),
              Text(
                subtitle!,
                style: AppTypography.bodySmall(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List Card - Card for list items with optional leading/trailing widgets
class ListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const ListCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTheme.space16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.space16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Header Card - Card with gradient header section
class HeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? child;
  final LinearGradient? gradient;
  final Color? headerColor;
  final Widget? headerAction;
  final EdgeInsetsGeometry? padding;

  const HeaderCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.child,
    this.gradient,
    this.headerColor,
    this.headerAction,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgGradient = gradient ?? 
        LinearGradient(
          colors: [
            headerColor ?? theme.colorScheme.primary,
            (headerColor ?? theme.colorScheme.primary).withValues(alpha: 0.8),
          ],
        );

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              gradient: bgGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge(color: Colors.white),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          subtitle!,
                          style: AppTypography.bodyMedium(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),
          // Content section
          if (child != null)
            Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.space16),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Empty State Card - Card shown when there's no data
class EmptyStateCard extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const EmptyStateCard({
    Key? key,
    required this.message,
    this.subtitle,
    this.icon,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              const SizedBox(height: AppTheme.space16),
              Text(
                message,
                style: AppTypography.bodyLarge(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.space8),
                Text(
                  subtitle!,
                  style: AppTypography.bodyMedium(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppTheme.space24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
