import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';

/// Notification badge widget that displays unread count
class NotificationBadge extends StatelessWidget {
  final int count;
  final bool showZero;
  final Widget child;
  final double? size;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.showZero = false,
    this.size,
    this.badgeColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0 || (showZero && count == 0))
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              constraints: BoxConstraints(
                minWidth: size ?? 20,
                minHeight: size ?? 20,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.error,
                borderRadius: BorderRadius.circular((size ?? 20) / 2),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getDisplayText(),
                  style: AppTypography.labelSmall().copyWith(
                    color: textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getDisplayText() {
    if (count == 0) return '0';
    if (count < 10) return count.toString();
    if (count < 100) return count.toString();
    return '99+';
  }
}

/// Notification badge positioned widget for specific use cases
class PositionedNotificationBadge extends StatelessWidget {
  final int count;
  final bool showZero;
  final double? size;
  final Color? badgeColor;
  final Color? textColor;
  final double? right;
  final double? top;

  const PositionedNotificationBadge({
    super.key,
    required this.count,
    this.showZero = false,
    this.size,
    this.badgeColor,
    this.textColor,
    this.right = -8,
    this.top = -8,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: right,
      top: top,
      child: Container(
        constraints: BoxConstraints(
          minWidth: size ?? 20,
          minHeight: size ?? 20,
        ),
        decoration: BoxDecoration(
          color: badgeColor ?? AppColors.error,
          borderRadius: BorderRadius.circular((size ?? 20) / 2),
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _getDisplayText(),
              style: AppTypography.labelSmall().copyWith(
                color: textColor ?? Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (count == 0) return '0';
    if (count < 10) return count.toString();
    if (count < 100) return count.toString();
    return '99+';
  }
}
