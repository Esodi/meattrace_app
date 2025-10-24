import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/processing_unit_management_provider.dart';
import '../../providers/theme_provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF1A1A1A) : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.isDarkMode ? Colors.white : AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.headlineMedium().copyWith(
            color: themeProvider.isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
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
          _buildSectionHeader('Notifications', themeProvider),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications about transfers',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              icon: Icons.notifications,
              themeProvider: themeProvider,
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
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          // Processing Preferences
          _buildSectionHeader('Processing Preferences', themeProvider),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Auto-Receive Animals',
              subtitle: 'Automatically receive transferred animals',
              value: _autoReceiveAnimals,
              onChanged: (value) {
                setState(() => _autoReceiveAnimals = value);
              },
              icon: Icons.auto_mode,
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Default Quality Grade',
              subtitle: _defaultQualityGrade,
              icon: Icons.grade,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showQualityGradeDialog(),
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          // Appearance Section
          _buildSectionHeader('Appearance', themeProvider),
          _buildSettingsCard([
            _buildListTile(
              title: 'Theme',
              subtitle: _getThemeLabel(themeProvider.themePreference.name),
              icon: Icons.palette,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(themeProvider),
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'High Contrast',
              subtitle: 'Improve text readability',
              value: themeProvider.isHighContrastEnabled,
              onChanged: (value) => themeProvider.toggleHighContrast(),
              icon: Icons.contrast,
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Text Size',
              subtitle: '${(themeProvider.textScale * 100).toInt()}%',
              icon: Icons.text_fields,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTextSizeDialog(themeProvider),
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Reduce Motion',
              subtitle: 'Minimize animations and transitions',
              value: themeProvider.reduceMotion,
              onChanged: (value) => themeProvider.setReduceMotion(value),
              icon: Icons.reduce_capacity,
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          // User Management
          _buildSectionHeader('User Management', themeProvider),
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
                  themeProvider: themeProvider,
                );
              },
            ),
          ], themeProvider),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy', themeProvider),
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
              themeProvider: themeProvider,
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
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          // Support
          _buildSectionHeader('Support', themeProvider),
          _buildSettingsCard([
            _buildListTile(
              title: 'Help Center',
              subtitle: 'Get help and support',
              icon: Icons.help_outline,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/help'),
              themeProvider: themeProvider,
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
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'About',
              subtitle: 'Version 1.0.0',
              icon: Icons.info_outline,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAboutDialog(),
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          // Danger Zone
          _buildSectionHeader('Account', themeProvider),
          _buildSettingsCard([
            _buildListTile(
              title: 'Logout',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              iconColor: AppColors.error,
              textColor: AppColors.error,
              onTap: () => _showLogoutDialog(),
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          const SizedBox(height: AppTheme.space32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider themeProvider) {
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
          color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: themeProvider.isDarkMode ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
        boxShadow: themeProvider.isDarkMode ? null : [
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
    required ThemeProvider themeProvider,
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
          color: themeProvider.isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium().copyWith(
          color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
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
    required ThemeProvider themeProvider,
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
          color: textColor ?? (themeProvider.isDarkMode ? Colors.white : AppColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium().copyWith(
          color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
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

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return theme;
    }
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Select Theme',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemePreference>(
              title: Text(
                'Light',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              value: ThemePreference.light,
              groupValue: themeProvider.themePreference,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLightMode();
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemePreference>(
              title: Text(
                'Dark',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              value: ThemePreference.dark,
              groupValue: themeProvider.themePreference,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setDarkMode();
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemePreference>(
              title: Text(
                'System Default',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              value: ThemePreference.system,
              groupValue: themeProvider.themePreference,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setSystemMode();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSizeDialog(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Text Size',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adjust the text size for better readability',
              style: AppTypography.bodyMedium().copyWith(
                color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: themeProvider.textScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: '${(themeProvider.textScale * 100).toInt()}%',
                    activeColor: AppColors.processorPrimary,
                    onChanged: (value) => themeProvider.setTextScale(value),
                  ),
                ),
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Current: ${(themeProvider.textScale * 100).toInt()}%',
              style: AppTypography.titleMedium().copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(color: AppColors.processorPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Logout',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
              context.go('/login');
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
