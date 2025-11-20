import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/core/custom_button.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String entityName;
  final String requestedRole;
  final DateTime requestedAt;
  final bool isShop;

  const PendingApprovalScreen({
    super.key,
    required this.entityName,
    required this.requestedRole,
    required this.requestedAt,
    this.isShop = false,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  String? _confirmationText = '';

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isShop ? AppColors.shopPrimary : AppColors.processorPrimary;
    final icon = widget.isShop ? Icons.store : Icons.factory;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pending Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 60,
                    color: AppColors.warning,
                  ),
                ),

                SizedBox(height: AppTheme.space32),

                // Title
                Text(
                  'Request Pending Approval',
                  style: AppTypography.headlineMedium().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppTheme.space16),

                // Message
                Text(
                  'Your request to join',
                  style: AppTypography.bodyLarge(),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppTheme.space8),

                // Entity Name
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: AppTheme.space8),
                      Flexible(
                        child: Text(
                          widget.entityName,
                          style: AppTypography.headlineSmall().copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppTheme.space16),

                Text(
                  'is pending approval.',
                  style: AppTypography.bodyLarge(),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppTheme.space32),

                // Info Card
                Container(
                  padding: EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          SizedBox(width: AppTheme.space8),
                          Text(
                            'Request Details',
                            style: AppTypography.bodyLarge().copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.space12),
                      _buildInfoRow('Requested Role', _formatRole(widget.requestedRole)),
                      SizedBox(height: AppTheme.space8),
                      _buildInfoRow('Submitted', _formatDate(widget.requestedAt)),
                      SizedBox(height: AppTheme.space8),
                      _buildInfoRow('Status', 'Pending Review'),
                    ],
                  ),
                ),

                SizedBox(height: AppTheme.space32),

                // Instructions
                Container(
                  padding: EdgeInsets.all(AppTheme.space16),
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
                      SizedBox(height: AppTheme.space12),
                      Text(
                        'What happens next?',
                        style: AppTypography.bodyLarge().copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.space8),
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

                SizedBox(height: AppTheme.space32),

                // Withdraw Request Button
                CustomButton(
                  label: 'Withdraw Request',
                  onPressed: () => _showWithdrawConfirmationDialog(context),
                  customColor: AppColors.error,
                  icon: Icons.delete_forever,
                ),

                SizedBox(height: AppTheme.space16),

                // Logout Button
                CustomButton(
                  label: 'Logout',
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  customColor: Colors.grey.shade600,
                  icon: Icons.logout,
                ),

                SizedBox(height: AppTheme.space16),

                // Refresh Button
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
              SizedBox(height: AppTheme.space12),
              Container(
                padding: EdgeInsets.all(AppTheme.space12),
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
                        SizedBox(width: AppTheme.space8),
                        Text(
                          'This action cannot be undone!',
                          style: AppTypography.bodyMedium().copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.space8),
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
              SizedBox(height: AppTheme.space8),
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
                      contentPadding: EdgeInsets.symmetric(
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
            content: Text('An error occurred: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}