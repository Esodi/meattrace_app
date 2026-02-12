import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sale.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../widgets/core/status_badge.dart';

/// Modern Sales History Screen
/// Features: Sales list with status tabs, search, filtering
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Sale> _sales = [];
  String _searchQuery = '';

  final List<String> _statusFilters = ['all', 'cash', 'card', 'mobile_money'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadSales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/sales/');

      // Handle both paginated and non-paginated responses
      List<dynamic> salesList;
      if (response.data is Map && response.data.containsKey('results')) {
        // Paginated response
        salesList = response.data['results'] as List;
      } else if (response.data is List) {
        // Direct list response
        salesList = response.data as List;
      } else {
        // Empty or unexpected format
        salesList = [];
      }

      final sales = salesList.map((json) => Sale.fromJson(json)).toList();

      // Sort by most recent first
      sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() => _sales = sales);
      }
    } catch (e) {
      debugPrint('Error loading sales: $e');
      if (mounted) {
        setState(() => _sales = []); // Set empty list on error
        // Only show error if it's not a "no sales" situation
        if (!e.toString().contains('404')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error loading sales: ${e.toString().contains('404') ? 'No sales found' : e.toString()}',
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Sale> _getFilteredSales(String filter) {
    var filtered = _sales;

    // Apply payment method filter
    if (filter != 'all') {
      filtered = filtered
          .where((sale) => sale.paymentMethod.toLowerCase() == filter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((sale) {
        return sale.id.toString().contains(query) ||
            sale.customerName?.toLowerCase().contains(query) == true ||
            sale.customerPhone?.toLowerCase().contains(query) == true ||
            sale.paymentMethod.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'card':
        return AppColors.info;
      case 'mobile_money':
        return AppColors.processorPrimary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return filter[0].toUpperCase() + filter.substring(1);
    }
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
            Text('Sales History', style: AppTypography.headlineMedium()),
            Text(
              'Track your sales',
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
          tabs: _statusFilters.map((filter) {
            final count = _getFilteredSales(filter).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getFilterLabel(filter)),
                  if (count > 0) ...[
                    const SizedBox(width: AppTheme.space4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space6,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.shopPrimary,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
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
              hint: 'Search sales...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Sales List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusFilters.map((filter) {
                if (_isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.shopPrimary,
                    ),
                  );
                }

                final filteredSales = _getFilteredSales(filter);

                if (filteredSales.isEmpty) {
                  return _buildEmptyState(filter);
                }

                return RefreshIndicator(
                  onRefresh: _loadSales,
                  color: AppColors.shopPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.space12,
                        ),
                        child: _buildSaleCard(sale),
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

  Widget _buildSaleCard(Sale sale) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          // Navigate to sale detail if needed
          // context.push('/shop/sales/${sale.id}');
        },
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
                          'Sale #${sale.id}',
                          style: AppTypography.titleMedium(),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(sale.createdAt),
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: sale.paymentMethod.toUpperCase(),
                    color: _getPaymentMethodColor(sale.paymentMethod),
                  ),
                ],
              ),
              const Divider(height: AppTheme.space24),
              // Products sold
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Text(
                    '${sale.items.length} product${sale.items.length != 1 ? 's' : ''}',
                    style: AppTypography.bodyMedium(),
                  ),
                  const Spacer(),
                  Text(
                    'TZS ${sale.totalAmount.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium().copyWith(
                      color: AppColors.shopPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Customer info (if provided)
              if (sale.customerName != null || sale.customerPhone != null) ...[
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        sale.customerName ?? sale.customerPhone ?? 'Customer',
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
              // Show product details
              if (sale.items.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space8),
                const Divider(height: AppTheme.space16),
                ...sale.items
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productName ?? 'Product'} (${item.weight.toStringAsFixed(2)} ${item.weightUnit})',
                                style: AppTypography.bodySmall(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'TZS ${item.subtotal.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall().copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (sale.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.space4),
                    child: Text(
                      '+ ${sale.items.length - 3} more item${sale.items.length - 3 != 1 ? 's' : ''}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
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

  Widget _buildEmptyState(String filter) {
    String message;
    String subtitle;

    switch (filter) {
      case 'cash':
        message = 'No Cash Sales';
        subtitle = 'No cash payments recorded yet';
        break;
      case 'card':
        message = 'No Card Sales';
        subtitle = 'No card payments recorded yet';
        break;
      case 'mobile_money':
        message = 'No Mobile Money Sales';
        subtitle = 'No mobile money payments recorded yet';
        break;
      default:
        message = 'No Sales Found';
        subtitle = _searchQuery.isNotEmpty
            ? 'Try adjusting your search'
            : 'Make your first sale to get started';
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
                Icons.point_of_sale,
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
