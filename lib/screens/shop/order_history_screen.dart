import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../widgets/core/status_badge.dart';

/// Modern Order History Screen
/// Features: Order list with status tabs, search, filtering
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Order> _orders = [];
  String _searchQuery = '';

  final List<String> _statusFilters = ['all', 'pending', 'confirmed', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/orders/');
      
      final orders = (response.data['results'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
      
      // Sort by most recent first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() => _orders = orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Order> _getFilteredOrders(String status) {
    var filtered = _orders;
    
    // Apply status filter
    if (status != 'all') {
      filtered = filtered.where((order) => order.status.toLowerCase() == status).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((order) {
        return order.id.toString().contains(query) ||
            order.deliveryAddress?.toLowerCase().contains(query) == true ||
            order.status.toLowerCase().contains(query);
      }).toList();
    }
    
    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.processorPrimary;
      case 'ready':
        return AppColors.success;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order History', style: AppTypography.headlineMedium()),
            Text(
              'Track your orders',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.shopPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.shopPrimary,
          labelStyle: AppTypography.labelMedium(),
          unselectedLabelStyle: AppTypography.labelSmall(),
          isScrollable: true,
          tabs: _statusFilters.map((status) {
            final count = _getFilteredOrders(status).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getStatusLabel(status)),
                  if (count > 0) ...[
                    const SizedBox(width: AppTheme.space4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space6,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.shopPrimary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        '$count',
                        style: AppTypography.labelSmall().copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            color: Colors.white,
            child: CustomTextField(
              hint: 'Search orders...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Order List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusFilters.map((status) {
                if (_isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.shopPrimary),
                  );
                }

                final filteredOrders = _getFilteredOrders(status);

                if (filteredOrders.isEmpty) {
                  return _buildEmptyState(status);
                }

                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppColors.shopPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space12),
                        child: _buildOrderCard(order),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/shop/orders/${order.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppColors.shopPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: AppColors.shopPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: AppTypography.titleMedium(),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(order.createdAt),
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: order.status.toUpperCase(),
                    color: _getStatusColor(order.status),
                  ),
                ],
              ),
              const Divider(height: AppTheme.space24),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Text(
                    '${order.items.length} items',
                    style: AppTypography.bodyMedium(),
                  ),
                  const Spacer(),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium().copyWith(
                      color: AppColors.shopPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!,
                        style: AppTypography.bodySmall().copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    String subtitle;

    switch (status) {
      case 'pending':
        message = 'No Pending Orders';
        subtitle = 'All your orders have been processed';
        break;
      case 'confirmed':
        message = 'No Confirmed Orders';
        subtitle = 'No orders awaiting confirmation';
        break;
      case 'delivered':
        message = 'No Delivered Orders';
        subtitle = 'You haven\'t received any orders yet';
        break;
      case 'cancelled':
        message = 'No Cancelled Orders';
        subtitle = 'Great! No orders have been cancelled';
        break;
      default:
        message = 'No Orders Found';
        subtitle = _searchQuery.isNotEmpty
            ? 'Try adjusting your search'
            : 'Place your first order to get started';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              message,
              style: AppTypography.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
