import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../core/status_badge.dart';
import '../core/role_avatar.dart';

/// MeatTrace Pro - Transfer Card Component
/// Display transfer/shipment information with source, destination, and status

class TransferCard extends StatelessWidget {
  final String transferId;
  final String status; // 'pending', 'in_transit', 'delivered', 'rejected', 'cancelled'
  final String? fromName;
  final String? fromRole;
  final String? toName;
  final String? toRole;
  final int itemCount;
  final String? itemType;
  final DateTime? transferDate;
  final DateTime? deliveryDate;
  final String? driverName;
  final String? vehicleNumber;
  final VoidCallback? onTap;
  final bool isSelected;
  final Widget? trailing;

  const TransferCard({
    Key? key,
    required this.transferId,
    required this.status,
    this.fromName,
    this.fromRole,
    this.toName,
    this.toRole,
    required this.itemCount,
    this.itemType,
    this.transferDate,
    this.deliveryDate,
    this.driverName,
    this.vehicleNumber,
    this.onTap,
    this.isSelected = false,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Transfer ID & Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transfer #$transferId',
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TransferStatusBadge(
                    status: status,
                    size: BadgeSize.medium,
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppTheme.space8),
                    trailing!,
                  ],
                ],
              ),
              
              const SizedBox(height: AppTheme.space16),
              
              // Route: From -> To
              Row(
                children: [
                  // From
                  Expanded(
                    child: _buildLocation(
                      context,
                      label: 'From',
                      name: fromName ?? 'Unknown',
                      role: fromRole,
                      isDark: isDark,
                    ),
                  ),
                  
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: AppTheme.iconMedium,
                      color: _getStatusColor(),
                    ),
                  ),
                  
                  // To
                  Expanded(
                    child: _buildLocation(
                      context,
                      label: 'To',
                      name: toName ?? 'Unknown',
                      role: toRole,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.space16),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space16),
              
              // Transfer Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetail(
                      Icons.inventory_2,
                      '$itemCount ${itemType ?? 'items'}',
                      isDark,
                    ),
                  ),
                  if (transferDate != null)
                    Expanded(
                      child: _buildDetail(
                        Icons.calendar_today,
                        _formatDate(transferDate!),
                        isDark,
                      ),
                    ),
                ],
              ),
              
              if (driverName != null || vehicleNumber != null) ...[
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    if (driverName != null)
                      Expanded(
                        child: _buildDetail(
                          Icons.person,
                          driverName!,
                          isDark,
                        ),
                      ),
                    if (vehicleNumber != null)
                      Expanded(
                        child: _buildDetail(
                          Icons.local_shipping,
                          vehicleNumber!,
                          isDark,
                        ),
                      ),
                  ],
                ),
              ],
              
              if (deliveryDate != null && status == 'delivered') ...[
                const SizedBox(height: AppTheme.space12),
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        'Delivered on ${_formatDate(deliveryDate!)}',
                        style: AppTypography.bodySmall(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocation(
    BuildContext context, {
    required String label,
    required String name,
    String? role,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Row(
          children: [
            if (role != null) ...[
              RoleAvatar(
                name: name,
                role: role,
                size: AvatarSize.extraSmall,
              ),
              const SizedBox(width: AppTheme.space8),
            ],
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyMedium(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (role != null) ...[
          const SizedBox(height: AppTheme.space4),
          RoleBadge(
            role: role,
            size: BadgeSize.small,
          ),
        ],
      ],
    );
  }

  Widget _buildDetail(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase().replaceAll('_', '')) {
      case 'pending':
        return AppColors.warning;
      case 'intransit':
        return AppColors.info;
      case 'delivered':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Compact Transfer Card - Smaller version for lists
class CompactTransferCard extends StatelessWidget {
  final String transferId;
  final String status;
  final String? fromName;
  final String? toName;
  final int itemCount;
  final VoidCallback? onTap;
  final bool isSelected;

  const CompactTransferCard({
    Key? key,
    required this.transferId,
    required this.status,
    this.fromName,
    this.toName,
    required this.itemCount,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              Icon(
                Icons.local_shipping,
                size: AppTheme.iconMedium,
                color: _getStatusColor(),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer #$transferId',
                      style: AppTypography.bodyMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      '${fromName ?? 'Unknown'} → ${toName ?? 'Unknown'}',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TransferStatusBadge(
                status: status,
                size: BadgeSize.small,
              ),
              const SizedBox(width: AppTheme.space8),
              Icon(
                Icons.chevron_right,
                size: AppTheme.iconSmall,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase().replaceAll('_', '')) {
      case 'pending':
        return AppColors.warning;
      case 'intransit':
        return AppColors.info;
      case 'delivered':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Transfer Stats Card - Display transfer statistics
class TransferStatsCard extends StatelessWidget {
  final int totalTransfers;
  final int pendingCount;
  final int inTransitCount;
  final int deliveredCount;
  final int rejectedCount;
  final VoidCallback? onTap;

  const TransferStatsCard({
    Key? key,
    required this.totalTransfers,
    this.pendingCount = 0,
    this.inTransitCount = 0,
    this.deliveredCount = 0,
    this.rejectedCount = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: AppTheme.iconLarge,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRANSFERS',
                          style: AppTypography.labelLarge(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$totalTransfers Total',
                          style: AppTypography.headlineSmall(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.space16),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space16),
              
              // Status Breakdown
              Wrap(
                spacing: AppTheme.space16,
                runSpacing: AppTheme.space12,
                children: [
                  if (pendingCount > 0)
                    _buildStatusCount(
                      'Pending',
                      pendingCount,
                      AppColors.warning,
                      isDark,
                    ),
                  if (inTransitCount > 0)
                    _buildStatusCount(
                      'In Transit',
                      inTransitCount,
                      AppColors.info,
                      isDark,
                    ),
                  if (deliveredCount > 0)
                    _buildStatusCount(
                      'Delivered',
                      deliveredCount,
                      AppColors.success,
                      isDark,
                    ),
                  if (rejectedCount > 0)
                    _buildStatusCount(
                      'Rejected',
                      rejectedCount,
                      AppColors.error,
                      isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Text(
          count.toString(),
          style: AppTypography.bodySmall(color: color).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
