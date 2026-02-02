import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/custom_icons.dart';

class ShopMainScaffold extends StatelessWidget {
  final Widget child;

  const ShopMainScaffold({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location == '/shop-home') return 0;
    if (location.startsWith('/shop/inventory')) return 1;
    if (location.startsWith('/shop/orders') ||
        location.startsWith('/shop/sell')) {
      return 2;
    }
    if (location.startsWith('/shop/profile')) return 3;

    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/shop-home');
        break;
      case 1:
        context.go('/shop/inventory');
        break;
      case 2:
        context.go('/shop/orders');
        break;
      case 3:
        context.go('/shop/profile');
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
              color: AppColors.shopPrimary, // Or AppColors.shopDark
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shopPrimary.withValues(alpha: 0.3),
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
                  CustomIcons.shop,
                  'Shop',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.inventory_2_rounded,
                  'Inv',
                  selectedIndex,
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.point_of_sale_rounded,
                  'Sales',
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
        backgroundColor: AppColors.shopPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      );
    } else if (selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () => context.push('/shop/sell'),
        backgroundColor: AppColors.shopPrimary,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Quick Actions', style: AppTypography.headlineMedium()),
            const SizedBox(height: 16),
            _buildSpeedDialAction(
              context,
              icon: Icons.point_of_sale,
              label: 'New Sale',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                context.push('/shop/sell');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.inbox,
              label: 'Receive Products',
              color: AppColors.shopPrimary,
              onTap: () {
                Navigator.pop(context);
                context.push('/receive-products');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.add_shopping_cart,
              label: 'Add Opening Stock',
              color: AppColors.processorPrimary,
              onTap: () {
                Navigator.pop(context);
                context.push('/onboarding-inventory');
              },
            ),
            _buildSpeedDialAction(
              context,
              icon: Icons.shopping_bag,
              label: 'Place Order',
              color: AppColors.secondaryBlue,
              onTap: () {
                Navigator.pop(context);
                context.push('/place-order');
              },
            ),
            const SizedBox(height: 8),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
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
