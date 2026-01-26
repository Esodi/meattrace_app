import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';

/// Shop Profile Screen
/// Features: User info, settings links, logout
class ShopProfileScreen extends StatelessWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: AppTypography.headlineMedium()),
            Text(
              'Account & Settings',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.space16),
        children: [
          CustomCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.shopPrimary,
                  child: Text(
                    user?.username.substring(0, 1).toUpperCase() ?? 'S',
                    style: AppTypography.headlineLarge().copyWith(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  user?.username ?? 'Shop User',
                  style: AppTypography.headlineMedium(),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  user?.email ?? 'email@example.com',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.shopPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    'Shop Owner',
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.shopPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Shop Management',
            style: AppTypography.titleMedium().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.store,
                  title: 'Shop Settings',
                  subtitle: 'Manage shop information',
                  onTap: () => context.push('/shop/settings'),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.people,
                  title: 'User Management',
                  subtitle: 'Manage shop users and roles',
                  onTap: () {
                    // Get current shop ID from auth provider
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final shopId = authProvider.user?.shopId;

                    if (shopId != null) {
                      // Use context.push to maintain navigation stack
                      context.push('/shop/users?shopId=$shopId');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shop ID not found. Please try again.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'App Settings',
            style: AppTypography.titleMedium().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          CustomCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          CustomButton(
            label: 'Logout',
            customColor: AppColors.error,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout', style: AppTypography.headlineMedium()),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: AppTypography.bodyMedium(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    CustomButton(
                      label: 'Logout',
                      customColor: AppColors.error,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const SizedBox(height: AppTheme.space16),
          Center(
            child: Text(
              'MeatTrace Pro v2.0.0',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.space8),
        decoration: BoxDecoration(
          color: AppColors.shopPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Icon(icon, color: AppColors.shopPrimary, size: 24),
      ),
      title: Text(title, style: AppTypography.titleMedium()),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall().copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
