import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Settings Screen for Abbatoir
/// Features: Account settings, notifications, app preferences, about
class AbbatoirSettingsScreen extends StatefulWidget {
  const AbbatoirSettingsScreen({super.key});

  @override
  State<AbbatoirSettingsScreen> createState() => _AbbatoirSettingsScreenState();
}

class _AbbatoirSettingsScreenState extends State<AbbatoirSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _transferAlerts = true;
  bool _healthAlerts = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings',
          style: AppTypography.titleLarge().copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Container(
              margin: const EdgeInsets.all(AppTheme.space16),
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.abbatoirPrimary,
                          AppColors.abbatoirPrimary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (user?.username ?? 'F').substring(0, 1).toUpperCase(),
                        style: AppTypography.headlineLarge().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Abbatoir',
                          style: AppTypography.titleMedium().copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          user?.email ?? 'abbatoir@meattrace.com',
                          style: AppTypography.bodySmall().copyWith(
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: AppColors.abbatoirPrimary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit profile coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Account Settings
            _buildSectionHeader('Account', isDark),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Profile Information',
              subtitle: 'Update your personal details',
              onTap: () {
                context.push('/profile');
              },
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Change password coming soon!')),
                );
              },
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              subtitle: 'Manage your privacy settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Privacy settings coming soon!'),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              isDark: isDark,
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
              },
              isDark: isDark,
            ),
            _buildSwitchTile(
              icon: Icons.send_outlined,
              title: 'Transfer Alerts',
              subtitle: 'Get notified about animal transfers',
              value: _transferAlerts,
              onChanged: (value) {
                setState(() => _transferAlerts = value);
              },
              isDark: isDark,
            ),
            _buildSwitchTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Health Alerts',
              subtitle: 'Get notified about health issues',
              value: _healthAlerts,
              onChanged: (value) {
                setState(() => _healthAlerts = value);
              },
              isDark: isDark,
            ),

            // App Preferences
            _buildSectionHeader('Preferences', isDark),
            _buildSettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: _getThemeLabel(themeProvider.themePreference.name),
              onTap: () => _showThemeDialog(themeProvider),
              isDark: isDark,
            ),
            _buildSwitchTile(
              icon: Icons.contrast_outlined,
              title: 'High Contrast',
              subtitle: 'Improve text readability',
              value: themeProvider.isHighContrastEnabled,
              onChanged: (value) {
                themeProvider.toggleHighContrast();
              },
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.text_fields_outlined,
              title: 'Text Size',
              subtitle: '${(themeProvider.textScale * 100).toInt()}%',
              onTap: () {
                _showTextSizeDialog(themeProvider);
              },
              isDark: isDark,
            ),
            _buildSwitchTile(
              icon: Icons.reduce_capacity_outlined,
              title: 'Reduce Motion',
              subtitle: 'Minimize animations and transitions',
              value: themeProvider.reduceMotion,
              onChanged: (value) {
                themeProvider.setReduceMotion(value);
              },
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: 'English (US)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language settings coming soon!'),
                  ),
                );
              },
              isDark: isDark,
            ),

            // About
            _buildSectionHeader('About', isDark),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0',
              onTap: () {},
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terms & Conditions coming soon!'),
                  ),
                );
              },
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy coming soon!')),
                );
              },
              isDark: isDark,
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help with MeatTrace',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon!')),
                );
              },
              isDark: isDark,
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await _showLogoutDialog();
                    if (confirmed == true) {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        'Logout',
                        style: AppTypography.button().copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space24,
        AppTheme.space16,
        AppTheme.space8,
      ),
      child: Text(
        title,
        style: AppTypography.titleMedium().copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: AppColors.abbatoirPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppColors.abbatoirPrimary, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge().copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall().copyWith(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark
              ? Colors.white.withOpacity(0.7)
              : AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(AppTheme.space8),
          decoration: BoxDecoration(
            color: AppColors.abbatoirPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppColors.abbatoirPrimary, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.bodyLarge().copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall().copyWith(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.abbatoirPrimary,
      ),
    );
  }

  void _showTextSizeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = themeProvider.isDarkMode;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
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
                          activeColor: AppColors.abbatoirPrimary,
                          onChanged: (value) {
                            themeProvider.setTextScale(value);
                            setState(() {});
                          },
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
                  const SizedBox(height: AppTheme.space16),
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
                    style: TextStyle(color: AppColors.abbatoirPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
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

  Future<bool?> _showLogoutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return showDialog<bool>(
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
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
