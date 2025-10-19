import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Pending changes list showing unsynced data
/// Displays list of changes waiting to be synced to server
class PendingChangesList extends StatelessWidget {
  final List<PendingChange> changes;
  final VoidCallback? onSyncAll;
  final Function(PendingChange)? onSyncItem;
  final Function(PendingChange)? onDeleteItem;

  const PendingChangesList({
    super.key,
    required this.changes,
    this.onSyncAll,
    this.onSyncItem,
    this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    if (changes.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.sync_problem,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Changes',
                        style: AppTypography.headlineSmall(),
                      ),
                      Text(
                        '${changes.length} ${changes.length == 1 ? 'change' : 'changes'} waiting to sync',
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSyncAll != null)
                  TextButton.icon(
                    onPressed: onSyncAll,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sync All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.info,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Changes list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: changes.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: AppTheme.space16,
            ),
            itemBuilder: (context, index) {
              final change = changes[index];
              return _buildChangeItem(change);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(PendingChange change) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: _getChangeTypeColor(change.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          _getChangeTypeIcon(change.type),
          color: _getChangeTypeColor(change.type),
          size: 20,
        ),
      ),
      title: Text(
        change.title,
        style: AppTypography.bodyLarge(),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.space4),
          Text(
            change.description,
            style: AppTypography.bodyMedium().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            _formatTimestamp(change.timestamp),
            style: AppTypography.labelSmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space8,
              vertical: AppTheme.space4,
            ),
            decoration: BoxDecoration(
              color: _getChangeTypeColor(change.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              _getChangeTypeLabel(change.type),
              style: AppTypography.labelSmall().copyWith(
                color: _getChangeTypeColor(change.type),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onSyncItem != null || onDeleteItem != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'sync' && onSyncItem != null) {
                  onSyncItem!(change);
                } else if (value == 'delete' && onDeleteItem != null) {
                  onDeleteItem!(change);
                }
              },
              itemBuilder: (context) => [
                if (onSyncItem != null)
                  const PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 18, color: AppColors.info),
                        SizedBox(width: AppTheme.space8),
                        Text('Sync Now'),
                      ],
                    ),
                  ),
                if (onDeleteItem != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: AppTheme.space8),
                        Text('Discard'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'All Changes Synced',
              style: AppTypography.headlineSmall(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'Your data is up to date with the server',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChangeTypeIcon(ChangeType type) {
    switch (type) {
      case ChangeType.create:
        return Icons.add_circle;
      case ChangeType.update:
        return Icons.edit;
      case ChangeType.delete:
        return Icons.delete;
      case ChangeType.transfer:
        return Icons.send;
    }
  }

  Color _getChangeTypeColor(ChangeType type) {
    switch (type) {
      case ChangeType.create:
        return AppColors.success;
      case ChangeType.update:
        return AppColors.info;
      case ChangeType.delete:
        return AppColors.error;
      case ChangeType.transfer:
        return AppColors.warning;
    }
  }

  String _getChangeTypeLabel(ChangeType type) {
    switch (type) {
      case ChangeType.create:
        return 'CREATE';
      case ChangeType.update:
        return 'UPDATE';
      case ChangeType.delete:
        return 'DELETE';
      case ChangeType.transfer:
        return 'TRANSFER';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Data model for pending changes
class PendingChange {
  final String id;
  final String title;
  final String description;
  final ChangeType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const PendingChange({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.data,
  });
}

/// Types of changes that can be pending
enum ChangeType {
  create,
  update,
  delete,
  transfer,
}
