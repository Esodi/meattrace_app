import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_management_provider.dart';
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
  String _defaultPaymentMethod = 'Cash';

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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
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

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications about orders',
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

          // Shop Preferences
          _buildSectionHeader('Shop Preferences'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Auto-Confirm Orders',
              subtitle: 'Automatically confirm new orders',
              value: _autoConfirmOrders,
              onChanged: (value) {
                setState(() => _autoConfirmOrders = value);
              },
              icon: Icons.auto_mode,
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Default Payment Method',
              subtitle: _defaultPaymentMethod,
              icon: Icons.payment,
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showPaymentMethodDialog(),
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
            ),
          ]),

          // Staff Management
          _buildSectionHeader('Staff Management'),
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
                      Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    // Get current shop ID from auth provider
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final shopId = authProvider.user?.shopId;

                    if (shopId != null) {
                      context.goNamed(
                        'shop-users',
                        queryParameters: {'shopId': shopId.toString()},
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Shop not found'),
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
              subtitle: 'Export your shop data',
              icon: Icons.backup,
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup feature coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip,
              trailing: Icon(Icons.chevron_right),
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
              trailing: Icon(Icons.chevron_right),
              onTap: () => context.push('/help'),
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'Report a Problem',
              subtitle: 'Send us feedback',
              icon: Icons.bug_report,
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Feedback form coming soon')),
                );
              },
            ),
            const Divider(height: 1),
            _buildListTile(
              title: 'About',
              subtitle: 'Version 1.0.0',
              icon: Icons.info_outline,
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showAboutDialog(),
            ),
          ]),

          // Danger Zone
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            _buildListTile(
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              trailing: Icon(Icons.chevron_right),
              onTap: () => _showSignOutDialog(),
              titleColor: AppColors.error,
            ),
          ]),

          SizedBox(height: AppTheme.space24),
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
        style: AppTypography.labelLarge(
          color: AppColors.textSecondary,
        ).copyWith(fontWeight: FontWeight.bold),
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
            blurRadius: 10,
            offset: Offset(0, 2),
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: AppTypography.bodyLarge(),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium(
          color: AppColors.textSecondary,
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.shopPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.shopPrimary,
          size: 24,
        ),
      ),
      activeColor: AppColors.shopPrimary,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (titleColor ?? AppColors.shopPrimary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: titleColor ?? AppColors.shopPrimary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge().copyWith(
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodyMedium(
          color: AppColors.textSecondary,
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
              value: 'Cash',
              groupValue: _defaultPaymentMethod,
              onChanged: (value) {
                setState(() => _defaultPaymentMethod = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Card'),
              value: 'Card',
              groupValue: _defaultPaymentMethod,
              onChanged: (value) {
                setState(() => _defaultPaymentMethod = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Mobile Money'),
              value: 'Mobile Money',
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
        child: Icon(
          Icons.store,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'MeatTrace helps you track meat products from farm to table, ensuring quality and transparency throughout the supply chain.',
            style: AppTypography.bodyMedium(),
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: AppTypography.headlineSmall(),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
