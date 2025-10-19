import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/processing_unit_management_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Processor Settings Screen
class ProcessorSettingsScreen extends StatefulWidget {
  const ProcessorSettingsScreen({super.key});

  @override
  State<ProcessorSettingsScreen> createState() => _ProcessorSettingsScreenState();
}

class _ProcessorSettingsScreenState extends State<ProcessorSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _autoReceiveAnimals = false;
  String _defaultQualityGrade = 'Premium';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.headlineMedium(),
        ),
      ),
      body: ListView(
        children: [
          // User Profile Section
          Container(
            margin: const EdgeInsets.all(AppTheme.space16),
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.processorPrimary,
                  AppColors.processorPrimary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: Text(
                    user?.username != null && user!.username.isNotEmpty
                        ? user.username.substring(0, 1).toUpperCase()
                        : 'P',
                    style: AppTypography.headlineLarge().copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  user?.username ?? 'Processor',
                  style: AppTypography.headlineMedium().copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? 'processor@example.com',
                  style: AppTypography.bodyMedium().copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/profile'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.processorPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications about transfers',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              icon: Icons.notifications,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Get updates via email',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
              },
              icon: Icons.email,
            ),
          ]),

          // Processing Preferences
          _buildSectionHeader('Processing Preferences'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Auto-Receive Animals',
              subtitle: 'Automatically receive transferred animals',
              value: _autoReceiveAnimals,
              onChanged: (value) {
                setState(() => _autoReceiveAnimals = value);
              },
              icon: Icons.auto_mode,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Default Quality Grade',
              subtitle: _defaultQualityGrade,
              icon: Icons.grade,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQualityGradeDialog(),
            ),
          ]),

          // User Management
          _buildSectionHeader('User Management'),
          _buildSettingsCard([
            Consumer<ProcessingUnitManagementProvider>(
              builder: (context, provider, _) {
                final pendingCount = provider.pendingJoinRequests.length;
                return _buildListTile(
                  title: 'Manage Users',
                  subtitle: pendingCount > 0 
                      ? '$pendingCount pending request${pendingCount > 1 ? 's' : ''}'
                      : 'Invite and manage team members',
                  icon: Icons.people,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: AppTypography.caption(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    // Get current processing unit ID from auth provider
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final processingUnitId = authProvider.user?.processingUnitId;
                    
                    if (processingUnitId != null) {
                      context.goNamed(
                        'processing-unit-users',
                        queryParameters: {'unitId': processingUnitId.toString()},
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Processing unit not found'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ]),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard([
            _buildListTile(
              title: 'Backup Data',
              subtitle: 'Export your processing data',
              icon: Icons.backup,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup feature coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to privacy policy
              },
            ),
          ]),

          // Support
          _buildSectionHeader('Support'),
          _buildSettingsCard([
            _buildListTile(
              title: 'Help Center',
              subtitle: 'Get help and support',
              icon: Icons.help_outline,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/help'),
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Report a Problem',
              subtitle: 'Send us feedback',
              icon: Icons.bug_report,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback form coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'About',
              subtitle: 'Version 1.0.0',
              icon: Icons.info_outline,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAboutDialog(),
            ),
          ]),

          // Danger Zone
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            _buildListTile(
              title: 'Logout',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              iconColor: AppColors.error,
              textColor: AppColors.error,
              onTap: () => _showLogoutDialog(),
            ),
          ]),

          const SizedBox(height: AppTheme.space32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space8,
      ),
      child: Text(
        title,
        style: AppTypography.labelLarge().copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: AppColors.processorPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(icon, color: AppColors.processorPrimary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge().copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium().copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.processorPrimary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.processorPrimary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.processorPrimary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge().copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium().copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
    );
  }

  void _showQualityGradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Quality Grade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Premium', 'Choice', 'Select', 'Standard'].map((grade) {
            return RadioListTile<String>(
              title: Text(grade),
              value: grade,
              groupValue: _defaultQualityGrade,
              onChanged: (value) {
                setState(() => _defaultQualityGrade = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.processorPrimary,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About MeatTrace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: AppTypography.bodyLarge(),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'MeatTrace is a comprehensive meat traceability system for farmers, processors, and retailers.',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              '© 2025 MeatTrace. All rights reserved.',
              style: AppTypography.caption().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
