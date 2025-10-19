import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// MeatTrace Pro - Status Badge Components
/// Visual indicators for health, quality, transfer status, and more

enum BadgeVariant {
  filled,      // Solid background with white text
  outlined,    // Border with colored text
  soft,        // Light background with colored text
}

enum BadgeSize {
  small,   // 20px height, 11px font
  medium,  // 24px height, 12px font
  large,   // 28px height, 14px font
}

/// Base Status Badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final BadgeVariant variant;
  final BadgeSize size;
  final IconData? icon;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.color,
    this.variant = BadgeVariant.filled,
    this.size = BadgeSize.medium,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Size configurations
    double height;
    double fontSize;
    double iconSize;
    double horizontalPadding;

    switch (size) {
      case BadgeSize.small:
        height = 20;
        fontSize = 11;
        iconSize = 12;
        horizontalPadding = AppTheme.space8;
        break;
      case BadgeSize.medium:
        height = 24;
        fontSize = 12;
        iconSize = 14;
        horizontalPadding = AppTheme.space12;
        break;
      case BadgeSize.large:
        height = 28;
        fontSize = 14;
        iconSize = 16;
        horizontalPadding = AppTheme.space16;
        break;
    }

    // Variant configurations
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (variant) {
      case BadgeVariant.filled:
        backgroundColor = color;
        textColor = Colors.white;
        borderColor = null;
        break;
      case BadgeVariant.outlined:
        backgroundColor = Colors.transparent;
        textColor = color;
        borderColor = color;
        break;
      case BadgeVariant.soft:
        backgroundColor = color.withOpacity(isDark ? 0.2 : 0.1);
        textColor = color;
        borderColor = null;
        break;
    }

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: textColor,
            ),
            SizedBox(width: AppTheme.space4),
          ],
          Text(
            label,
            style: AppTypography.labelMedium(color: textColor).copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Health Status Badge - For animal health indicators
class HealthStatusBadge extends StatelessWidget {
  final String status; // 'healthy', 'sick', 'quarantine', 'deceased', 'treatment'
  final BadgeVariant variant;
  final BadgeSize size;

  const HealthStatusBadge({
    Key? key,
    required this.status,
    this.variant = BadgeVariant.soft,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();
    
    String label;
    Color color;
    IconData? icon;

    switch (statusLower) {
      case 'healthy':
        label = 'Healthy';
        color = AppColors.getHealthStatusColor('healthy');
        icon = Icons.check_circle;
        break;
      case 'sick':
        label = 'Sick';
        color = AppColors.getHealthStatusColor('sick');
        icon = Icons.warning;
        break;
      case 'quarantine':
        label = 'Quarantine';
        color = AppColors.getHealthStatusColor('quarantine');
        icon = Icons.block;
        break;
      case 'deceased':
        label = 'Deceased';
        color = AppColors.getHealthStatusColor('deceased');
        icon = Icons.close;
        break;
      case 'treatment':
        label = 'Treatment';
        color = AppColors.getHealthStatusColor('treatment');
        icon = Icons.medical_services;
        break;
      default:
        label = status;
        color = AppColors.textSecondary;
        icon = Icons.info;
    }

    return StatusBadge(
      label: label,
      color: color,
      variant: variant,
      size: size,
      icon: icon,
    );
  }
}

/// Quality Grade Badge - For product quality indicators
class QualityBadge extends StatelessWidget {
  final String grade; // 'premium', 'standard', 'economy', 'organic', 'certified'
  final BadgeVariant variant;
  final BadgeSize size;

  const QualityBadge({
    Key? key,
    required this.grade,
    this.variant = BadgeVariant.soft,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradeLower = grade.toLowerCase();
    
    String label;
    Color color;
    IconData? icon;

    switch (gradeLower) {
      case 'premium':
        label = 'Premium';
        color = AppColors.getQualityColor('premium');
        icon = Icons.star;
        break;
      case 'standard':
        label = 'Standard';
        color = AppColors.getQualityColor('standard');
        icon = Icons.circle;
        break;
      case 'economy':
        label = 'Economy';
        color = AppColors.getQualityColor('economy');
        icon = Icons.circle_outlined;
        break;
      case 'organic':
        label = 'Organic';
        color = AppColors.getQualityColor('organic');
        icon = Icons.eco;
        break;
      case 'certified':
        label = 'Certified';
        color = AppColors.getQualityColor('certified');
        icon = Icons.verified;
        break;
      default:
        label = grade;
        color = AppColors.textSecondary;
        icon = Icons.label;
    }

    return StatusBadge(
      label: label,
      color: color,
      variant: variant,
      size: size,
      icon: icon,
    );
  }
}

/// Transfer Status Badge - For transfer/shipment tracking
class TransferStatusBadge extends StatelessWidget {
  final String status; // 'pending', 'in_transit', 'delivered', 'rejected', 'cancelled'
  final BadgeVariant variant;
  final BadgeSize size;

  const TransferStatusBadge({
    Key? key,
    required this.status,
    this.variant = BadgeVariant.soft,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase().replaceAll('_', '');
    
    String label;
    Color color;
    IconData? icon;

    switch (statusLower) {
      case 'pending':
        label = 'Pending';
        color = AppColors.warning;
        icon = Icons.schedule;
        break;
      case 'intransit':
        label = 'In Transit';
        color = AppColors.info;
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        label = 'Delivered';
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        label = 'Rejected';
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      case 'cancelled':
        label = 'Cancelled';
        color = AppColors.textSecondary;
        icon = Icons.close;
        break;
      default:
        label = status;
        color = AppColors.textSecondary;
        icon = Icons.info;
    }

    return StatusBadge(
      label: label,
      color: color,
      variant: variant,
      size: size,
      icon: icon,
    );
  }
}

/// Role Badge - For user role indicators
class RoleBadge extends StatelessWidget {
  final String role; // 'farmer', 'processing_unit', 'shop', 'admin'
  final BadgeVariant variant;
  final BadgeSize size;

  const RoleBadge({
    Key? key,
    required this.role,
    this.variant = BadgeVariant.soft,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleLower = role.toLowerCase().replaceAll('_', '');
    
    String label;
    Color color;
    IconData? icon;

    switch (roleLower) {
      case 'farmer':
        label = 'Farmer';
        color = AppColors.getPrimaryColorForRole('farmer');
        icon = Icons.agriculture;
        break;
      case 'processingunit':
        label = 'Processor';
        color = AppColors.getPrimaryColorForRole('processing_unit');
        icon = Icons.factory;
        break;
      case 'shop':
        label = 'Shop';
        color = AppColors.getPrimaryColorForRole('shop');
        icon = Icons.store;
        break;
      case 'admin':
        label = 'Admin';
        color = AppColors.textPrimary;
        icon = Icons.admin_panel_settings;
        break;
      default:
        label = role;
        color = AppColors.textSecondary;
        icon = Icons.person;
    }

    return StatusBadge(
      label: label,
      color: color,
      variant: variant,
      size: size,
      icon: icon,
    );
  }
}

/// Verification Badge - For verification/certification status
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String? label;
  final BadgeVariant variant;
  final BadgeSize size;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.label,
    this.variant = BadgeVariant.filled,
    this.size = BadgeSize.small,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: label ?? (isVerified ? 'Verified' : 'Unverified'),
      color: isVerified ? AppColors.success : AppColors.textSecondary,
      variant: variant,
      size: size,
      icon: isVerified ? Icons.verified : Icons.info,
    );
  }
}

/// Count Badge - For notification counts or item counts
class CountBadge extends StatelessWidget {
  final int count;
  final Color? color;
  final BadgeSize size;
  final int? maxCount; // Show "99+" if count exceeds this

  const CountBadge({
    Key? key,
    required this.count,
    this.color,
    this.size = BadgeSize.small,
    this.maxCount = 99,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayCount = maxCount != null && count > maxCount!
        ? '$maxCount+'
        : count.toString();

    return StatusBadge(
      label: displayCount,
      color: color ?? AppColors.error,
      variant: BadgeVariant.filled,
      size: size,
    );
  }
}

/// New Badge - For highlighting new items
class NewBadge extends StatelessWidget {
  final BadgeSize size;

  const NewBadge({
    Key? key,
    this.size = BadgeSize.small,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: 'NEW',
      color: AppColors.error,
      variant: BadgeVariant.filled,
      size: size,
    );
  }
}

/// Custom Badge - For custom text and colors
class CustomBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final BadgeSize size;

  const CustomBadge({
    Key? key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.size = BadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    
    return StatusBadge(
      label: label,
      color: bgColor,
      variant: BadgeVariant.filled,
      size: size,
      icon: icon,
    );
  }
}
