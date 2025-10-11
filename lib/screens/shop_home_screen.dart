import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/yield_trends_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../widgets/interactive_dashboard_card.dart';
import '../widgets/data_visualization_widgets.dart';
import '../widgets/enhanced_yield_trends_chart.dart';
import '../widgets/custom_dashboard_fabs.dart';
import '../widgets/responsive_dashboard_layout.dart';
import '../widgets/theme_toggle.dart';

class ShopHomeScreen extends StatefulWidget {
   const ShopHomeScreen({super.key});

   @override
   State<ShopHomeScreen> createState() => _ShopHomeScreenState();
 }

 class _ShopHomeScreenState extends State<ShopHomeScreen> with WidgetsBindingObserver {
   late OrderProvider _orderProvider;

   @override
   void initState() {
     super.initState();
     _orderProvider = Provider.of<OrderProvider>(context, listen: false);
     WidgetsBinding.instance.addPostFrameCallback((_) {
       _fetchOrders();
     });
     WidgetsBinding.instance.addObserver(this);
   }

   @override
   void dispose() {
     WidgetsBinding.instance.removeObserver(this);
     super.dispose();
   }

   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     if (state == AppLifecycleState.resumed) {
       // Refresh data when app comes back to foreground
       _refreshData();
     }
   }

   Future<void> _refreshData() async {
     await _fetchOrders();
   }

   Future<void> _fetchOrders() async {
     final authProvider = context.read<AuthProvider>();
     if (authProvider.user?.id != null) {
       await _orderProvider.fetchOrders(shopId: authProvider.user!.id);
     }
   }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ShopHomeScreen');
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return ResponsiveDashboardLayout(
      currentRoute: '/shop-home',
      content: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit the app?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
            if (shouldExit == true) {
              if (mounted) Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ShopHub Dashboard'),
            actions: [
              const ThemeToggle(),
              const SizedBox(width: 8),
              const AccessibilityToggle(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh data',
                onPressed: () => _refreshData(),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(Responsive.getPadding(context)).copyWith(bottom: 88.0),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Welcome section
                      InteractiveDashboardCard(
                        title: 'Welcome back, ${user?.username ?? 'Seller'}!',
                        value: 'Shop Overview',
                        icon: Icons.storefront,
                        color: AppTheme.secondaryBurgundy,
                        subtitle: 'Manage your inventory and orders efficiently',
                        animationDelay: Duration.zero,
                      ),
                      const SizedBox(height: 24),

                      // Quick Stats Row
                      DashboardSection(
                        title: 'Key Metrics',
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallScreen = constraints.maxWidth < 400;
                              final spacing = isSmallScreen ? 8.0 : 16.0;
                              
                              return Consumer<OrderProvider>(
                                builder: (context, orderProvider, child) {
                                  final totalOrders = orderProvider.orders.length;
                                  final pendingOrders = orderProvider.orders.where((o) => o.status.toLowerCase() == 'pending').length;
                                  final completedOrders = orderProvider.orders.where((o) => o.status.toLowerCase() == 'delivered').length;
                                  final totalRevenue = orderProvider.orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: MetricCard(
                                              title: 'Total Orders',
                                              value: totalOrders.toString(),
                                              change: '+12%',
                                              isPositive: true,
                                              icon: Icons.shopping_cart,
                                              color: AppTheme.secondaryBurgundy,
                                              animationDelay: const Duration(milliseconds: 100),
                                            ),
                                          ),
                                          SizedBox(width: spacing),
                                          Expanded(
                                            child: MetricCard(
                                              title: 'Pending',
                                              value: pendingOrders.toString(),
                                              change: '-5%',
                                              isPositive: false,
                                              icon: Icons.schedule,
                                              color: AppTheme.warningOrange,
                                              animationDelay: const Duration(milliseconds: 200),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: MetricCard(
                                              title: 'Completed',
                                              value: completedOrders.toString(),
                                              change: '+18%',
                                              isPositive: true,
                                              icon: Icons.check_circle,
                                              color: AppTheme.successGreen,
                                              animationDelay: const Duration(milliseconds: 300),
                                            ),
                                          ),
                                          SizedBox(width: spacing),
                                          Expanded(
                                            child: MetricCard(
                                              title: 'Revenue',
                                              value: '\${totalRevenue.toStringAsFixed(0)}',
                                              change: '+25%',
                                              isPositive: true,
                                              icon: Icons.attach_money,
                                              color: AppTheme.accentOrange,
                                              animationDelay: const Duration(milliseconds: 400),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Enhanced Yield Trends Section
                      DashboardSection(
                        title: 'Sales & Inventory Trends',
                        children: [
                          EnhancedYieldTrendsChart(
                            title: 'Shop Performance Analytics',
                            animationDelay: const Duration(milliseconds: 500),
                            showPeriodSelector: true,
                            showMetricSelector: true,
                            fixedRole: 'Shop',
                            onRefresh: _refreshData,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions Row
                      DashboardSection(
                        title: 'Quick Actions',
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = Responsive.getGridCrossAxisCount(context);
                              final spacing = Responsive.isMobile(context) ? 12.0 : 16.0;
                              final availableWidth = constraints.maxWidth;
                              final cardWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                              
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Receive Products',
                                      value: 'Stock In',
                                      icon: Icons.inventory_2,
                                      color: AppTheme.secondaryBurgundy,
                                      onTap: () => context.go('/receive-products'),
                                      animationDelay: const Duration(milliseconds: 600),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Manage Inventory',
                                      value: 'Stock Control',
                                      icon: Icons.store,
                                      color: AppTheme.successGreen,
                                      onTap: () => context.go('/inventory'),
                                      animationDelay: const Duration(milliseconds: 700),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Place Orders',
                                      value: 'New Order',
                                      icon: Icons.shopping_cart,
                                      color: AppTheme.accentOrange,
                                      onTap: () => context.go('/place-order'),
                                      animationDelay: const Duration(milliseconds: 800),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: InteractiveDashboardCard(
                                      title: 'Scan QR',
                                      value: 'Verify',
                                      icon: Icons.qr_code_scanner,
                                      color: AppTheme.secondaryBlue,
                                      onTap: () => context.go('/qr-scanner?source=shop'),
                                      animationDelay: const Duration(milliseconds: 900),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Recent Orders Section
                      DashboardSection(
                        title: 'Recent Orders',
                        children: [
                          Consumer<OrderProvider>(
                            builder: (context, orderProvider, child) {
                              if (orderProvider.isLoading) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                );
                              }

                              final recentOrders = orderProvider.orders.take(3).toList();

                              if (recentOrders.isEmpty) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const Center(child: Text('No recent orders')),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => context.go('/place-order'),
                                          icon: const Icon(Icons.add_shopping_cart),
                                          label: const Text('Place First Order'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: recentOrders.map((order) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getOrderStatusColor(order.status),
                                        child: Icon(
                                          _getOrderStatusIcon(order.status),
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text('Order #${order.id}'),
                                      subtitle: Text(
                                        '\$${order.totalAmount.toStringAsFixed(2)} • ${order.createdAt.toLocal().toString().split(' ')[0]}',
                                      ),
                                      trailing: Text(
                                        order.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getOrderStatusColor(order.status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Custom Shop Dashboard FAB
          floatingActionButton: const ShopDashboardFAB(),
        ),
      ),
    );
  }


  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'delivered':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}







