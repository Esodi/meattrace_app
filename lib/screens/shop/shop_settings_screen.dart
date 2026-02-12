import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_management_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Shop Settings Screen
class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _autoConfirmOrders = false;
  String _defaultPaymentMethod = 'cash'; // lowercase to match backend

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.headlineMedium().copyWith(
            color: Theme.of(context).colorScheme.onSurface,
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
                  AppColors.shopPrimary,
                  AppColors.shopPrimary.withValues(alpha: 0.8),
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
                        : 'S',
                    style: AppTypography.headlineLarge().copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  user?.username ?? 'Shop Owner',
                  style: AppTypography.headlineMedium().copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  user?.email ?? 'shop@example.com',
                  style: AppTypography.bodyMedium().copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/profile'),
                  icon: Icon(Icons.edit),
                  label: Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.shopPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Business Profile Section
          _buildSectionHeader('Business Profile', themeProvider),
          _buildSettingsCard([
            _buildListTile(
              title: 'Branding & Contact',
              subtitle: 'Edit headers, footers, TIN, and address',
              icon: Icons.store_outlined,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/shop/branding'),
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          // Notifications Section
          _buildSectionHeader('Notifications', themeProvider),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications about orders',
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

          // Shop Preferences
          _buildSectionHeader('Shop Preferences', themeProvider),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Auto-Confirm Orders',
              subtitle: 'Automatically confirm new orders',
              value: _autoConfirmOrders,
              onChanged: (value) {
                setState(() => _autoConfirmOrders = value);
              },
              icon: Icons.auto_mode,
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Default Payment Method',
              subtitle: _defaultPaymentMethod,
              icon: Icons.payment,
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showPaymentMethodDialog(),
              themeProvider: themeProvider,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Business Hours',
              subtitle: 'Set your shop opening hours',
              icon: Icons.access_time,
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Business hours feature coming soon')),
                );
              },
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
              trailing: Icon(Icons.chevron_right),
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
              trailing: Icon(Icons.chevron_right),
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

          // Staff Management
          _buildSectionHeader('Staff Management', themeProvider),
          _buildSettingsCard([
            Consumer<ShopManagementProvider>(
              builder: (context, provider, _) {
                final pendingCount = provider.pendingJoinRequests.length;
                return _buildListTile(
                  title: 'Manage Staff',
                  subtitle: pendingCount > 0
                      ? '$pendingCount pending request${pendingCount > 1 ? 's' : ''}'
                      : 'Invite and manage your team',
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
                    // Get current shop ID from auth provider
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final shopId = authProvider.user?.shopId;

                    if (shopId != null) {
                      context.push('/shop/users?shopId=$shopId');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Shop not found. Please ensure you are logged in as a shop owner.',
                          ),
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
              subtitle: 'Export your shop data',
              icon: Icons.backup,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup feature coming soon')),
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
                  SnackBar(content: Text('Feedback form coming soon')),
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
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSignOutDialog(),
              titleColor: AppColors.error,
              themeProvider: themeProvider,
            ),
          ], themeProvider),

          SizedBox(height: AppTheme.space24),
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
        style: AppTypography.labelLarge(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.7)
              : AppColors.textSecondary,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(
    List<Widget> children,
    ThemeProvider themeProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.1),
              )
            : null,
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: AppTypography.bodyLarge().copyWith(
          color: themeProvider.isDarkMode
              ? Colors.white
              : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.7)
              : AppColors.textSecondary,
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.shopPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.shopPrimary, size: 24),
      ),
      activeThumbColor: AppColors.shopPrimary,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
    Color? titleColor,
    required ThemeProvider themeProvider,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (titleColor ?? AppColors.shopPrimary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.shopPrimary, size: 24),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge().copyWith(
          color:
              titleColor ??
              (themeProvider.isDarkMode ? Colors.white : AppColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.7)
              : AppColors.textSecondary,
        ),
      ),
      trailing: trailing,
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Default Payment Method',
          style: AppTypography.headlineSmall(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Cash'),
              value: 'cash',
              groupValue: _defaultPaymentMethod,
              onChanged: (value) {
                setState(() => _defaultPaymentMethod = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Card'),
              value: 'card',
              groupValue: _defaultPaymentMethod,
              onChanged: (value) {
                setState(() => _defaultPaymentMethod = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Mobile Money'),
              value: 'mobile_money',
              groupValue: _defaultPaymentMethod,
              onChanged: (value) {
                setState(() => _defaultPaymentMethod = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'MeatTrace',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.shopPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.store, color: Colors.white, size: 32),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'MeatTrace helps you track meat products from abbatoir to table, ensuring quality and transparency throughout the supply chain.',
            style: AppTypography.bodyMedium(),
          ),
        ),
      ],
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
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textSecondary,
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
                    activeColor: AppColors.shopPrimary,
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
            child: Text('Done', style: TextStyle(color: AppColors.shopPrimary)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        title: Text(
          'Sign Out',
          style: AppTypography.headlineSmall().copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyMedium().copyWith(
            color: isDark
                ? Colors.white.withOpacity(0.7)
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              if (mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
