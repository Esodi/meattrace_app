import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// MeatTrace Pro - Traceability Timeline Component
/// Display chronological history of animal/product journey

class TimelineEvent {
  final String title;
  final String? description;
  final DateTime timestamp;
  final String? location;
  final String? performedBy;
  final String? role;
  final IconData? icon;
  final Color? color;
  final Map<String, String>? metadata;

  const TimelineEvent({
    required this.title,
    this.description,
    required this.timestamp,
    this.location,
    this.performedBy,
    this.role,
    this.icon,
    this.color,
    this.metadata,
  });
}

class TraceabilityTimeline extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool showConnectors;
  final bool reverseOrder; // Show newest first

  const TraceabilityTimeline({
    Key? key,
    required this.events,
    this.showConnectors = true,
    this.reverseOrder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayEvents = reverseOrder ? events.reversed.toList() : events;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayEvents.length,
      itemBuilder: (context, index) {
        final event = displayEvents[index];
        final isLast = index == displayEvents.length - 1;

        return TimelineEventItem(
          event: event,
          showConnector: showConnectors && !isLast,
        );
      },
    );
  }
}

class TimelineEventItem extends StatelessWidget {
  final TimelineEvent event;
  final bool showConnector;

  const TimelineEventItem({
    Key? key,
    required this.event,
    this.showConnector = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventColor = event.color ?? theme.colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Track
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Event Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: eventColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    event.icon ?? Icons.circle,
                    size: 20,
                    color: eventColor,
                  ),
                ),
                
                // Connector Line
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: AppTheme.space16),
          
          // Event Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title & Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: AppTypography.titleSmall(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        _formatTime(event.timestamp),
                        style: AppTypography.caption(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.space4),
                  
                  // Event Date
                  Text(
                    _formatDate(event.timestamp),
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  // Description
                  if (event.description != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      event.description!,
                      style: AppTypography.bodyMedium(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                  
                  // Location
                  if (event.location != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: AppTypography.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Performed By
                  if (event.performedBy != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          event.performedBy!,
                          style: AppTypography.bodySmall(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (event.role != null) ...[
                          const SizedBox(width: AppTheme.space4),
                          Text(
                            '(${event.role})',
                            style: AppTypography.bodySmall(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  // Metadata
                  if (event.metadata != null && event.metadata!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space12),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.backgroundGray,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: event.metadata!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${entry.key}:',
                                    style: AppTypography.bodySmall(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry.value,
                                    style: AppTypography.bodySmall(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Compact Timeline - Simplified version with less detail
class CompactTraceabilityTimeline extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool reverseOrder;

  const CompactTraceabilityTimeline({
    Key? key,
    required this.events,
    this.reverseOrder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayEvents = reverseOrder ? events.reversed.toList() : events;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayEvents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = displayEvents[index];
        final eventColor = event.color ?? theme.colorScheme.primary;

        return ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: eventColor.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.icon ?? Icons.circle,
              size: 16,
              color: eventColor,
            ),
          ),
          title: Text(
            event.title,
            style: AppTypography.bodyMedium(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            _formatDateTime(event.timestamp),
            style: AppTypography.bodySmall(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: event.location != null
              ? Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textTertiary,
                )
              : null,
        );
      },
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Timeline Summary Card - Show key milestones
class TimelineSummaryCard extends StatelessWidget {
  final String title;
  final List<TimelineEvent> events;
  final VoidCallback? onViewAll;

  const TimelineSummaryCard({
    Key? key,
    required this.title,
    required this.events,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      'View All',
                      style: AppTypography.labelMedium(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: AppTheme.space16),
            
            // Timeline
            if (events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 48,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'No events recorded',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              TraceabilityTimeline(
                events: events.take(3).toList(), // Show only first 3
                reverseOrder: true,
              ),
          ],
        ),
      ),
    );
  }
}
