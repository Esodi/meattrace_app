import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Sync progress indicator showing detailed sync status
/// Displays progress, items synced, and errors
class SyncProgressIndicator extends StatefulWidget {
  final bool isSyncing;
  final double progress; // 0.0 to 1.0
  final int totalItems;
  final int syncedItems;
  final int failedItems;
  final String? statusMessage;
  final VoidCallback? onCancel;

  const SyncProgressIndicator({
    super.key,
    required this.isSyncing,
    this.progress = 0.0,
    this.totalItems = 0,
    this.syncedItems = 0,
    this.failedItems = 0,
    this.statusMessage,
    this.onCancel,
  });

  @override
  State<SyncProgressIndicator> createState() => _SyncProgressIndicatorState();
}

class _SyncProgressIndicatorState extends State<SyncProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isSyncing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SyncProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing != oldWidget.isSyncing) {
      if (widget.isSyncing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing) {
      return const SizedBox.shrink();
    }

    final percentage = (widget.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_sync,
                        color: AppColors.info,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syncing Data',
                      style: AppTypography.headlineSmall(),
                    ),
                    if (widget.statusMessage != null)
                      Text(
                        widget.statusMessage!,
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onCancel,
                  color: AppColors.textSecondary,
                  tooltip: 'Cancel sync',
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          
          // Progress details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$percentage%',
                    style: AppTypography.labelLarge().copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    '${widget.syncedItems}/${widget.totalItems} items',
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (widget.failedItems > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Text(
                        '${widget.failedItems} failed',
                        style: AppTypography.labelSmall().copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
