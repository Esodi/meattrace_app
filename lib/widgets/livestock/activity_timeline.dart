import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../models/activity.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Activity Timeline Widget
/// Displays a timeline of recent abbatoir activities
class ActivityTimeline extends StatelessWidget {
  final List<Activity> activities;
  final int maxItems;
  final VoidCallback? onViewAll;

  const ActivityTimeline({
    super.key,
    required this.activities,
    this.maxItems = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final displayActivities = activities.take(maxItems).toList();

    if (displayActivities.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: AppTypography.headlineMedium()),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View All',
                    style: AppTypography.button().copyWith(
                      color: AppColors.abbatoirPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),

        // Activity Items
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            itemCount: displayActivities.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: Divider(
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.5),
              ),
            ),
            itemBuilder: (context, index) {
              return ActivityTimelineItem(
                activity: displayActivities[index],
                isFirst: index == 0,
                isLast: index == displayActivities.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'No Recent Activity',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Individual Activity Timeline Item
class ActivityTimelineItem extends StatelessWidget {
  final Activity activity;
  final bool isFirst;
  final bool isLast;

  const ActivityTimelineItem({
    super.key,
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: activity.targetRoute != null
          ? () {}
          : null, // Route navigation logic should be here
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.space12,
          horizontal: AppTheme.space16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with colored background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getActivityColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getActivityIcon(),
                color: _getActivityColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space16),

            // Activity Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTypography.titleSmall().copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(activity.timestamp),
                        style: AppTypography.labelSmall().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (activity.metadata != null &&
                          activity.metadata!.containsKey('count')) ...[
                        const SizedBox(width: AppTheme.space8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.divider,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          '${activity.metadata!['count']} items',
                          style: AppTypography.labelSmall().copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron for navigation
            if (activity.targetRoute != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.registration:
        return Icons.add_circle;
      case ActivityType.transfer:
        return Icons.send;
      case ActivityType.slaughter:
        return Icons.set_meal;
      case ActivityType.healthUpdate:
        return Icons.health_and_safety;
      case ActivityType.weightUpdate:
        return Icons.monitor_weight;
      case ActivityType.vaccination:
        return Icons.medical_services;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.registration:
        return AppColors.abbatoirPrimary;
      case ActivityType.transfer:
        return AppColors.processorPrimary;
      case ActivityType.slaughter:
        return AppColors.error;
      case ActivityType.healthUpdate:
      case ActivityType.vaccination:
        return AppColors.success;
      case ActivityType.weightUpdate:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return timeago.format(timestamp, locale: 'en_short');
  }
}

/// Compact Activity Card for smaller displays
class CompactActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const CompactActivityCard({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getActivityColor(
                    activity.type,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: _getActivityColor(activity.type),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      timeago.format(activity.timestamp, locale: 'en_short'),
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppTheme.iconSmall,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return Icons.add_circle;
      case ActivityType.transfer:
        return Icons.send;
      case ActivityType.slaughter:
        return Icons.set_meal;
      case ActivityType.healthUpdate:
        return Icons.health_and_safety;
      case ActivityType.weightUpdate:
        return Icons.monitor_weight;
      case ActivityType.vaccination:
        return Icons.medical_services;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.registration:
        return AppColors.abbatoirPrimary;
      case ActivityType.transfer:
        return AppColors.processorPrimary;
      case ActivityType.slaughter:
        return AppColors.error;
      case ActivityType.healthUpdate:
      case ActivityType.vaccination:
        return AppColors.success;
      case ActivityType.weightUpdate:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
