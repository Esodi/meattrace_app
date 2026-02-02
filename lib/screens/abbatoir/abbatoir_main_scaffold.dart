import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';

class AbbatoirMainScaffold extends StatelessWidget {
  final Widget child;

  const AbbatoirMainScaffold({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location == '/abbatoir-home') return 0;
    if (location.startsWith('/abbatoir/livestock-history') ||
        location.startsWith('/animals/')) {
      return 1;
    }
    if (location.startsWith('/abbatoir/sick-animals')) return 2;
    if (location.startsWith('/abbatoir/profile')) return 3;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/abbatoir-home');
        break;
      case 1:
        context.go('/abbatoir/livestock-history');
        break;
      case 2:
        context.go('/abbatoir/sick-animals');
        break;
      case 3:
        context.go('/abbatoir/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(
          bottom: 90,
        ), // Buffer for floating nav bar
        child: child,
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.abbatoirDark,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.pets_rounded,
                  'Animals',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.history_rounded,
                  'History',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.health_and_safety_rounded,
                  'Sick',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  3,
                  Icons.person_rounded,
                  'Profile',
                  selectedIndex,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context, selectedIndex),
    );
  }

  Widget? _buildFAB(BuildContext context, int selectedIndex) {
    if (selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () => _showSpeedDialActions(context),
        backgroundColor: AppColors.abbatoirPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return null;
  }

  void _showSpeedDialActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Quick Actions', style: AppTypography.headlineMedium()),
              const SizedBox(height: AppTheme.space16),
              _buildSpeedDialAction(
                context,
                icon: CustomIcons.cattle,
                label: 'Register Animal',
                color: AppColors.abbatoirPrimary,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/register-animal');
                },
              ),
              _buildSpeedDialAction(
                context,
                icon: CustomIcons.slaughter,
                label: 'Slaughter Animal',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/slaughter-animal');
                },
              ),
              _buildSpeedDialAction(
                context,
                icon: Icons.add_home_work,
                label: 'Add Opening Stock',
                color: AppColors.processorPrimary,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/onboarding-inventory');
                },
              ),
              _buildSpeedDialAction(
                context,
                icon: CustomIcons.transfer,
                label: 'Transfer Animals',
                color: AppColors.processorPrimary,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/select-animals-transfer');
                },
              ),
              _buildSpeedDialAction(
                context,
                icon: Icons.business_center,
                label: 'Manage Vendors',
                color: AppColors.secondaryBlue,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/external-vendors');
                },
              ),
              const SizedBox(height: AppTheme.space8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDialAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space8),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.space16),
            Text(
              label,
              style: AppTypography.bodyLarge().copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    int selectedIndex,
  ) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
