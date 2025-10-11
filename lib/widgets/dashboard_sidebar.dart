import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/theme.dart';

class DashboardSidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool) onToggle;
  final String currentRoute;

  const DashboardSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.currentRoute,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  List<Map<String, dynamic>> get _menuItems {
    if (widget.currentRoute.startsWith('/processor')) {
      return [
        {
          'title': 'Dashboard Overview',
          'icon': Icons.dashboard,
          'route': '/processor-home',
          'color': AppTheme.primaryGreen,
        },
        {
          'title': 'Processing Units',
          'icon': Icons.factory,
          'route': '/processing-units',
          'color': AppTheme.secondaryBlue,
        },
        {
          'title': 'Inventory Management',
          'icon': Icons.inventory,
          'route': '/inventory-management',
          'color': AppTheme.accentOrange,
        },
        {
          'title': 'Compliance Reports',
          'icon': Icons.verified,
          'route': '/compliance-reports',
          'color': AppTheme.secondaryBurgundy,
        },
        {
          'title': 'Supplier Interactions',
          'icon': Icons.business,
          'route': '/supplier-interactions',
          'color': AppTheme.successGreen,
        },
      ];
    } else if (widget.currentRoute.startsWith('/shop')) {
      return [
        {
          'title': 'Dashboard Overview',
          'icon': Icons.dashboard,
          'route': '/shop-home',
          'color': AppTheme.secondaryBurgundy,
        },
        {
          'title': 'Place Order',
          'icon': Icons.shopping_cart,
          'route': '/place-order',
          'color': AppTheme.accentOrange,
        },
        {
          'title': 'Product Display',
          'icon': Icons.store,
          'route': '/products-dashboard',
          'color': AppTheme.secondaryBlue,
        },
        {
          'title': 'Receive Products',
          'icon': Icons.inventory_2,
          'route': '/receive-products',
          'color': AppTheme.primaryGreen,
        },
        {
          'title': 'Inventory Management',
          'icon': Icons.warehouse,
          'route': '/inventory-management',
          'color': AppTheme.successGreen,
        },
        {
          'title': 'Scan QR Code',
          'icon': Icons.qr_code_scanner,
          'route': '/qr-scanner?source=shop',
          'color': AppTheme.accentMaroon,
        },
        {
          'title': 'Reports',
          'icon': Icons.analytics,
          'route': '/reports',
          'color': AppTheme.primaryRed,
        },
      ];
    } else {
      // Farmer menu items
      return [
        {
          'title': 'Dashboard Overview',
          'icon': Icons.dashboard,
          'route': '/farmer-home',
          'color': AppTheme.primaryRed,
        },
        {
          'title': 'Livestock Management',
          'icon': Icons.pets,
          'route': '/livestock-history',
          'color': AppTheme.secondaryBlue,
        },
        {
          'title': 'Weather Insights',
          'icon': Icons.wb_sunny,
          'route': '/weather-insights',
          'color': AppTheme.accentOrange,
        },
        {
          'title': 'Inventory Tracking',
          'icon': Icons.inventory,
          'route': '/inventory-management',
          'color': AppTheme.secondaryBurgundy,
        },
        {
          'title': 'Reports',
          'icon': Icons.analytics,
          'route': '/reports',
          'color': AppTheme.successGreen,
        },
      ];
    }
  }

  String get _headerTitle {
    if (widget.currentRoute.startsWith('/processor')) {
      return 'MeatTrace';
    } else if (widget.currentRoute.startsWith('/shop')) {
      return 'ShopHub';
    } else {
      return 'FarmHub';
    }
  }

  IconData get _headerIcon {
    if (widget.currentRoute.startsWith('/processor')) {
      return Icons.factory;
    } else if (widget.currentRoute.startsWith('/shop')) {
      return Icons.store;
    } else {
      return Icons.agriculture;
    }
  }

  List<Color> get _gradientColors {
    if (widget.currentRoute.startsWith('/processor')) {
      return [
        AppTheme.primaryGreen.withOpacity(0.9),
        AppTheme.primaryGreen.withOpacity(0.7),
        AppTheme.secondaryBlue.withOpacity(0.8),
      ];
    } else if (widget.currentRoute.startsWith('/shop')) {
      return [
        AppTheme.secondaryBurgundy.withOpacity(0.9),
        AppTheme.secondaryBurgundy.withOpacity(0.7),
        AppTheme.accentOrange.withOpacity(0.8),
      ];
    } else {
      return [
        AppTheme.primaryRed.withOpacity(0.9),
        AppTheme.primaryRed.withOpacity(0.7),
        AppTheme.secondaryBurgundy.withOpacity(0.8),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!widget.isCollapsed) ...[
                  Icon(
                    _headerIcon,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _headerTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    _headerIcon,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
                GestureDetector(
                  onTap: () => widget.onToggle(!widget.isCollapsed),
                  child: Icon(
                    widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white,
                    size: widget.isCollapsed ? 12 : 24,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = widget.currentRoute == item['route'];

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildMenuItem(
                          context,
                          item,
                          isSelected,
                          widget.isCollapsed,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: widget.isCollapsed
                ? const Icon(Icons.settings, color: Colors.white70, size: 24)
                : Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    Map<String, dynamic> item,
    bool isSelected,
    bool isCollapsed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (item['route'].startsWith('/processor') || item['route'] == '/farmer-home' || item['route'] == '/livestock-history') {
              context.go(item['route']);
            } else {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Feature Not Implemented'),
                    content: Text('Feature not implemented yet.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}







