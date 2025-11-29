import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';

/// MeatTrace Pro - Pending Approval Screen
/// Displays join request status and allows withdrawal

class PendingApprovalScreen extends StatefulWidget {
  final String entityName;
  final bool isShop;
  final String requestedRole;
  final DateTime requestedAt;
  final String? rejectionReason;

  const PendingApprovalScreen({
    Key? key,
    required this.entityName,
    required this.isShop,
    required this.requestedRole,
    required this.requestedAt,
    this.rejectionReason,
  }) : super(key: key);

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  String? _confirmationText;

  bool get isRejected => widget.rejectionReason != null;

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isShop ? AppColors.shopPrimary : AppColors.processorPrimary;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: isRejected ? AppColors.error.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_empty_rounded,
                size: 64,
                color: isRejected ? AppColors.error : primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Title
            Text(
              isRejected ? 'Request Rejected' : 'Approval Pending',
              style: AppTypography.headlineMedium().copyWith(
                fontWeight: FontWeight.bold,
                color: isRejected ? AppColors.error : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space12),

            // Subtitle
            Text(
              isRejected
                ? 'Your request to join has been rejected.'
                : 'Your request to join is currently under review.',
              style: AppTypography.bodyLarge().copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space32),

            // Details Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow('Organization', widget.entityName),
                  const Divider(height: AppTheme.space24),
                  _buildInfoRow('Type', widget.isShop ? 'Shop' : 'Processing Unit'),
                  const Divider(height: AppTheme.space24),
                  _buildInfoRow('Requested Role', _formatRole(widget.requestedRole)),
                  const Divider(height: AppTheme.space24),
                  _buildInfoRow(isRejected ? 'Rejected Date' : 'Requested', _formatDate(widget.requestedAt)),

                  if (isRejected && widget.rejectionReason != null) ...[
                    const Divider(height: AppTheme.space24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppColors.error.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejection Reason:',
                            style: AppTypography.bodySmall().copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            widget.rejectionReason!,
                            style: AppTypography.bodyMedium().copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space32),

            // Instructions
            if (!isRejected)
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.grey.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      'What happens next?',
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'The owner or manager will review your request. You will receive a notification once your request is approved or rejected.',
                      style: AppTypography.bodyMedium().copyWith(
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space32),

            // Withdraw Request Button (only if pending)
            if (!isRejected)
              CustomButton(
                label: 'Withdraw Request',
                onPressed: () => _showWithdrawConfirmationDialog(context),
                customColor: AppColors.error,
                icon: Icons.delete_forever,
              ),

              const SizedBox(height: AppTheme.space16),

            // Logout / Back to Login Button
            CustomButton(
              label: isRejected ? 'Back to Login' : 'Logout',
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              customColor: isRejected ? primaryColor : Colors.grey.shade600,
              icon: Icons.logout,
            ),

            const SizedBox(height: AppTheme.space16),

            // Refresh Button (only if pending)
            if (!isRejected)
              TextButton.icon(
                onPressed: () async {
                  // Refresh user profile to check if approved
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.ensureInitialized();

                  // The router will automatically redirect if status changed
                },
                icon: Icon(Icons.refresh),
                label: Text('Check Status'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium().copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatRole(String role) {
    final roleMap = {
      'owner': 'Owner',
      'manager': 'Manager',
      'supervisor': 'Supervisor',
      'worker': 'Worker',
      'quality_control': 'Quality Control',
    };
    return roleMap[role] ?? role;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showWithdrawConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Withdraw Request & Delete Account',
            style: AppTypography.headlineSmall().copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to withdraw your join request?',
                style: AppTypography.bodyLarge(),
              ),
              const SizedBox(height: AppTheme.space12),
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          'This action cannot be undone!',
                          style: AppTypography.bodyMedium().copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      '• Your join request will be permanently withdrawn\n'
                      '• Your account and all associated data will be deleted\n'
                      '• You will be logged out immediately\n'
                      '• You will need to create a new account to reapply',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.space16),
              Text(
                'Type "DELETE" to confirm:',
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              StatefulBuilder(
                builder: (context, setState) {
                  return TextField(
                    onChanged: (value) {
                      setState(() {
                        _confirmationText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Type DELETE here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmationText = '';
              },
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium().copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _confirmationText?.toUpperCase() == 'DELETE'
                  ? () => _withdrawAccount(dialogContext)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  void _withdrawAccount(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop(); // Close dialog

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.withdrawAccount();

      if (success && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account successfully deleted'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to login
        context.go('/login');
      } else if (context.mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to delete account'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}