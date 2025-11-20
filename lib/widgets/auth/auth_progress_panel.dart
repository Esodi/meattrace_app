import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_progress_provider.dart';
import '../../services/auth_websocket_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Widget to display real-time authentication progress
class AuthProgressPanel extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;

  const AuthProgressPanel({
    super.key,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProgressProvider>(
      builder: (context, progressProvider, child) {
        if (!progressProvider.hasMessages) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: AppTheme.space16),
          constraints: BoxConstraints(
            maxHeight: isExpanded ? 300 : 80,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppColors.borderLight.withValues(alpha: 0.3),
              width: 1,
            ),
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
              // Header
              _buildHeader(context, progressProvider),
              
              // Messages list
              if (isExpanded) ...[
                const Divider(height: 1),
                Expanded(
                  child: _buildMessagesList(progressProvider),
                ),
              ] else ...[
                // Show only latest message when collapsed
                _buildLatestMessage(progressProvider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthProgressProvider provider) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.isConnected 
                    ? AppColors.success 
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            
            // Title
            Expanded(
              child: Text(
                'Authentication Progress',
                style: AppTypography.labelLarge().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Message count badge
            if (provider.messages.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.messages.length}',
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            
            const SizedBox(width: AppTheme.space8),
            
            // Expand/collapse icon
            Icon(
              isExpanded 
                  ? Icons.keyboard_arrow_up 
                  : Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestMessage(AuthProgressProvider provider) {
    final latestMessage = provider.latestMessage;
    if (latestMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: Row(
        children: [
          _getStatusIcon(latestMessage),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              latestMessage.message,
              style: AppTypography.bodyMedium(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AuthProgressProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.space12),
      itemCount: provider.messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space8),
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(AuthProgressMessage message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: _getMessageBackgroundColor(message),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: _getMessageBorderColor(message),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getStatusIcon(message),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: AppTypography.bodyMedium().copyWith(
                    color: message.isError 
                        ? AppColors.error 
                        : AppColors.textPrimary,
                    fontWeight: message.isComplete || message.isError
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (message.step != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message.step!,
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Timestamp
          Text(
            _formatTime(message.timestamp),
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(AuthProgressMessage message) {
    IconData icon;
    Color color;

    if (message.isError) {
      icon = Icons.error_outline;
      color = AppColors.error;
    } else if (message.isSuccess) {
      icon = Icons.check_circle_outline;
      color = AppColors.success;
    } else if (message.isProgress) {
      icon = Icons.hourglass_empty;
      color = AppColors.info;
    } else {
      icon = Icons.info_outline;
      color = AppColors.textSecondary;
    }

    return Icon(icon, color: color, size: 20);
  }

  Color _getMessageBackgroundColor(AuthProgressMessage message) {
    if (message.isError) {
      return AppColors.error.withValues(alpha: 0.05);
    } else if (message.isSuccess) {
      return AppColors.success.withValues(alpha: 0.05);
    } else if (message.status == 'warning') {
      return AppColors.warning.withValues(alpha: 0.05);
    } else {
      return AppColors.info.withValues(alpha: 0.03);
    }
  }

  Color _getMessageBorderColor(AuthProgressMessage message) {
    if (message.isError) {
      return AppColors.error.withValues(alpha: 0.2);
    } else if (message.isSuccess) {
      return AppColors.success.withValues(alpha: 0.2);
    } else if (message.status == 'warning') {
      return AppColors.warning.withValues(alpha: 0.2);
    } else {
      return AppColors.borderLight.withValues(alpha: 0.2);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
