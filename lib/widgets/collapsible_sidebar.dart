import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/accessibility.dart';

class CollapsibleSidebar extends StatefulWidget {
  final bool isCollapsed;
  final Function(bool) onToggle;
  final String currentRoute;

  const CollapsibleSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.currentRoute,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  final List<Map<String, dynamic>> _menuSections = [
    {
      'title': 'Operations',
      'icon': Icons.build,
      'color': AppTheme.forestGreen,
      'items': [
        {'title': 'Create Product', 'route': '/create-product', 'icon': Icons.add_business},
        {'title': 'Receive Carcasses', 'route': '/receive-animals', 'icon': Icons.inventory},
        {'title': 'Product Categories', 'route': '/product-categories', 'icon': Icons.category},
        {'title': 'Scan QR', 'route': '/qr-scanner?source=processor', 'icon': Icons.qr_code_scanner},
        {'title': 'Transfer Products', 'route': '/select-products-transfer', 'icon': Icons.send},
      ],
    },
    {
      'title': 'Monitoring',
      'icon': Icons.monitor,
      'color': AppTheme.oceanBlue,
      'items': [
        {'title': 'Production Stats', 'route': '/processor-home', 'icon': Icons.analytics},
        {'title': 'Livestock History', 'route': '/livestock-history', 'icon': Icons.history},
        {'title': 'Scan History', 'route': '/scan-history', 'icon': Icons.qr_code},
        {'title': 'Inventory', 'route': '/inventory-management', 'icon': Icons.warehouse},
      ],
    },
    {
      'title': 'Management',
      'icon': Icons.business,
      'color': AppTheme.earthBrown,
      'items': [
        {'title': 'Place Order', 'route': '/place-order', 'icon': Icons.shopping_cart},
        {'title': 'Product Display', 'route': '/products-dashboard', 'icon': Icons.store},
        {'title': 'Reports', 'route': '/reports', 'icon': Icons.assessment},
      ],
    },
    {
      'title': 'Settings',
      'icon': Icons.settings,
      'color': AppTheme.skyBlue,
      'items': [
        {'title': 'Printer Settings', 'route': '/printer-settings', 'icon': Icons.print},
        {'title': 'Network Debug', 'route': '/network-debug', 'icon': Icons.wifi},
        {'title': 'Profile', 'route': '/profile', 'icon': Icons.person},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.forestGreen.withOpacity(0.9),
            AppTheme.oceanBlue.withOpacity(0.8),
            AppTheme.earthBrown.withOpacity(0.7),
          ],
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
                  const Icon(
                    Icons.factory,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Processor Hub',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.factory,
                    color: Colors.white,
                    size: 32,
                  ),
                ],
                AccessibleIconButton(
                  icon: widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                  semanticLabel: widget.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  tooltip: widget.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () => widget.onToggle(!widget.isCollapsed),
                ),
              ],
            ),
          ),

          // Menu Sections
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _menuSections.map((section) {
                  return _buildSection(context, section);
                }).toList(),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: widget.isCollapsed
                ? AccessibleIconButton(
                    icon: Icons.logout,
                    semanticLabel: 'Logout button',
                    tooltip: 'Logout',
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  )
                : AccessibleButton(
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    semanticLabel: 'Logout from application',
                    tooltip: 'Logout',
                    child: Row(
                      children: [
                        AccessibleIcon(
                          Icons.logout,
                          color: Colors.white70,
                          size: 20,
                          semanticLabel: 'Logout icon',
                        ),
                        const SizedBox(width: 12),
                        AccessibleText(
                          'Logout',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          semanticLabel: 'Logout text',
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, Map<String, dynamic> section) {
    final items = section['items'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isCollapsed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              section['title'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ...items.map((item) => _buildMenuItem(context, item, section['color'] as Color)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, Map<String, dynamic> item, Color sectionColor) {
    final isSelected = widget.currentRoute == item['route'];
    final itemTitle = item['title'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AccessibleButton(
        onPressed: () => context.go(item['route']),
        semanticLabel: '${itemTitle} menu item${isSelected ? ', currently selected' : ''}',
        tooltip: itemTitle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AccessibleIcon(
                  item['icon'] as IconData,
                  color: Colors.white,
                  size: 18,
                  semanticLabel: '${itemTitle} icon',
                ),
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AccessibleText(
                    itemTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    semanticLabel: itemTitle,
                  ),
                ),
                if (isSelected)
                  Semantics(
                    label: 'Current page indicator',
                    child: Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}







