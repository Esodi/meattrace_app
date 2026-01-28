import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/sale.dart';
import '../../services/sale_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../widgets/core/custom_button.dart';

/// Sales History Screen
/// Shows a list of past sales with filtering options
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SaleService _saleService = SaleService();
  final _searchController = TextEditingController();

  List<Sale> _sales = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  // Filter state
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _productNameFilter;

  // Date formatter
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _fullDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sales = await _saleService.getSales(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        productName: _productNameFilter,
      );
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Sale> _getFilteredSales() {
    if (_searchQuery.isEmpty) return _sales;

    final query = _searchQuery.toLowerCase();
    return _sales.where((sale) {
      final customerName = sale.customerName?.toLowerCase() ?? '';
      final customerPhone = sale.customerPhone?.toLowerCase() ?? '';
      final paymentMethod = sale.paymentMethod.toLowerCase();
      final saleId = sale.id.toString();

      // Search in item names
      final hasMatchingItem = sale.items.any(
        (item) =>
            (item.productName?.toLowerCase() ?? '').contains(query) ||
            (item.batchNumber?.toLowerCase() ?? '').contains(query),
      );

      return customerName.contains(query) ||
          customerPhone.contains(query) ||
          paymentMethod.contains(query) ||
          saleId.contains(query) ||
          hasMatchingItem;
    }).toList();
  }

  void _showFilterDialog() {
    DateTime? tempDateFrom = _dateFrom;
    DateTime? tempDateTo = _dateTo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.shopPrimary),
              const SizedBox(width: AppTheme.space8),
              Text('Filter Sales', style: AppTypography.headlineMedium()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date Range', style: AppTypography.labelMedium()),
              const SizedBox(height: AppTheme.space8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDateFrom ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempDateFrom = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Text(
                              tempDateFrom != null
                                  ? _fullDateFormat.format(tempDateFrom!)
                                  : 'From',
                              style: AppTypography.bodyMedium(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDateTo ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => tempDateTo = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Text(
                              tempDateTo != null
                                  ? _fullDateFormat.format(tempDateTo!)
                                  : 'To',
                              style: AppTypography.bodyMedium(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (tempDateFrom != null || tempDateTo != null) ...[
                const SizedBox(height: AppTheme.space8),
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      tempDateFrom = null;
                      tempDateTo = null;
                    });
                  },
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Clear dates'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            CustomButton(
              label: 'Apply',
              onPressed: () {
                setState(() {
                  _dateFrom = tempDateFrom;
                  _dateTo = tempDateTo;
                });
                Navigator.pop(context);
                _loadSales();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return '💵';
      case 'card':
        return '💳';
      case 'mobile_money':
        return '📱';
      default:
        return '💰';
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSales = _getFilteredSales();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales History', style: AppTypography.headlineMedium()),
            Text(
              '${filteredSales.length} transactions',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Filter indicator
          if (_dateFrom != null || _dateTo != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space8),
              child: Chip(
                label: Text(
                  'Filtered',
                  style: AppTypography.labelSmall().copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.shopPrimary,
                deleteIcon: Icon(Icons.close, size: 16, color: Colors.white),
                onDeleted: () {
                  setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                  });
                  _loadSales();
                },
              ),
            ),
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.shopPrimary),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            color: Colors.white,
            child: CustomTextField(
              hint: 'Search by customer, product, or ID...',
              prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Summary Stats
          _buildSummaryStats(filteredSales),

          // Sales List
          Expanded(child: _buildSalesList(filteredSales)),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(List<Sale> sales) {
    final totalRevenue = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final avgSale = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;

    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Revenue',
              'TZS ${NumberFormat('#,###').format(totalRevenue.round())}',
              Icons.attach_money,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: _buildStatCard(
              'Avg. Sale',
              'TZS ${NumberFormat('#,###').format(avgSale.round())}',
              Icons.trending_up,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList(List<Sale> sales) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.shopPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Failed to load sales',
                style: AppTypography.headlineMedium(),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                _error!,
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space24),
              CustomButton(label: 'Retry', onPressed: _loadSales),
            ],
          ),
        ),
      );
    }

    if (sales.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      color: AppColors.shopPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        itemCount: sales.length,
        itemBuilder: (context, index) {
          final sale = sales[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space12),
            child: _buildSaleCard(sale),
          );
        },
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/shop/sales/${sale.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space8),
                        decoration: BoxDecoration(
                          color: AppColors.shopPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: AppColors.shopPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sale #${sale.id}',
                            style: AppTypography.titleMedium(),
                          ),
                          Text(
                            _dateFormat.format(sale.createdAt),
                            style: AppTypography.bodySmall().copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TZS ${NumberFormat('#,###').format(sale.totalAmount.round())}',
                        style: AppTypography.titleMedium().copyWith(
                          color: AppColors.shopPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _timeFormat.format(sale.createdAt),
                        style: AppTypography.bodySmall().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.space12),
              Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: AppTheme.space12),

              // Details Row
              Row(
                children: [
                  // Customer
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Expanded(
                          child: Text(
                            sale.customerName ?? 'Walk-in Customer',
                            style: AppTypography.bodyMedium(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Method
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getPaymentMethodIcon(sale.paymentMethod),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          _formatPaymentMethod(sale.paymentMethod),
                          style: AppTypography.labelSmall(),
                        ),
                      ],
                    ),
                  ),

                  // Items count
                  const SizedBox(width: AppTheme.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                      vertical: AppTheme.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      '${sale.items.length} items',
                      style: AppTypography.labelSmall().copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),

                  // QR Code indicator
                  if (sale.receiptUuid != null) ...[
                    const SizedBox(width: AppTheme.space8),
                    Icon(Icons.qr_code, size: 20, color: AppColors.shopPrimary),
                  ],
                ],
              ),

              // Items preview
              if (sale.items.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space8),
                Text(
                  sale.items
                          .take(2)
                          .map(
                            (item) =>
                                '${item.productName ?? 'Product'} x${item.quantity.toStringAsFixed(0)}',
                          )
                          .join(', ') +
                      (sale.items.length > 2 ? '...' : ''),
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.receipt_long,
                size: 64,
                color: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'No Sales Found',
              style: AppTypography.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              _searchQuery.isNotEmpty || _dateFrom != null || _dateTo != null
                  ? 'Try adjusting your filters'
                  : 'Sales will appear here after you make transactions',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty ||
                _dateFrom != null ||
                _dateTo != null) ...[
              const SizedBox(height: AppTheme.space24),
              CustomButton(
                label: 'Clear Filters',
                variant: ButtonVariant.secondary,
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _dateFrom = null;
                    _dateTo = null;
                    _searchController.clear();
                  });
                  _loadSales();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
