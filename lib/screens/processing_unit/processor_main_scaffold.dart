import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

class ProcessorMainScaffold extends StatelessWidget {
  final Widget child;

  const ProcessorMainScaffold({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    // We use the full path to avoid partial matches
    final String location = GoRouterState.of(context).uri.path;

    if (location == '/processor-home') {
      return 0;
    }
    if (location.startsWith('/processor/products') ||
        location.startsWith('/products/')) {
      return 1;
    }
    if (location == '/qr-scanner') return 2;
    if (location == '/processor/settings') return 3;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/processor-home');
        break;
      case 1:
        context.go('/processor/products');
        break;
      case 2:
        context.go('/qr-scanner?source=processor');
        break;
      case 3:
        context.go('/processor/settings');
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
      // We use a Stack-like approach or ensure the bottomNavigationBar is definitely visible
      bottomNavigationBar: Container(
        color: Colors.transparent, // Ensure background matches
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.processorDark,
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
                  Icons.dashboard_rounded,
                  'Home',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.inventory_2_rounded,
                  'Products',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.qr_code_scanner_rounded,
                  'Scan',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  3,
                  Icons.settings_rounded,
                  'Settings',
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
        backgroundColor: AppColors.processorPrimary,
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
              icon: Icons.play_arrow,
              label: 'Process Batch',
              color: AppColors.processorPrimary,
              onTap: () {
                Navigator.pop(context);
                context.push('/create-product');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.inventory_2,
              label: 'Producer Inventory',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                context.push('/producer-inventory');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.inbox,
              label: 'Receive Animals',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                context.push('/receive-animals');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.qr_code,
              label: 'View QR Codes',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                context.push('/processor-qr-codes');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.send,
              label: 'Transfer Products',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                context.push('/transfer-products');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.category,
              label: 'Product Categories',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                context.push('/processor/product-categories');
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
            const SizedBox(height: AppTheme.space8),
          ],
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
