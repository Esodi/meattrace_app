import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/category_sales_summary.dart';
import '../../services/sale_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_button.dart';

/// Product Sales Tracking Screen
/// Shows aggregated sales data for a specific product name/category
class ProductSalesTrackingScreen extends StatefulWidget {
  final String productName;

  const ProductSalesTrackingScreen({super.key, required this.productName});

  @override
  State<ProductSalesTrackingScreen> createState() =>
      _ProductSalesTrackingScreenState();
}

class _ProductSalesTrackingScreenState
    extends State<ProductSalesTrackingScreen> {
  final SaleService _saleService = SaleService();
  CategorySalesSummary? _summary;
  bool _isLoading = true;
  String? _error;

  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _saleService.getCategorySalesSummary(
        widget.productName,
      );
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading product tracking: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.productName, style: AppTypography.headlineMedium()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.shopPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load tracking data',
                style: AppTypography.headlineMedium(),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(label: 'Retry', onPressed: _loadData),
            ],
          ),
        ),
      );
    }

    if (_summary == null) {
      return const Center(child: Text('No data found for this product'));
    }

    final summary = _summary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Card
          _buildOverviewCard(summary),

          const SizedBox(height: AppTheme.space24),

          // Inventory History Section
          Text('Stock History', style: AppTypography.titleLarge()),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Initial stock and additions from the processing unit',
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          _buildStockAdditions(summary),

          const SizedBox(height: AppTheme.space24),

          // Sales History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: AppTypography.titleLarge()),
              Text(
                '${summary.transactionCount} total',
                style: AppTypography.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          _buildTransactions(summary),

          const SizedBox(height: AppTheme.space32),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(CategorySalesSummary summary) {
    return CustomCard(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Stock',
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        summary.remainingWeight.toStringAsFixed(1),
                        style: AppTypography.displaySmall().copyWith(
                          color: AppColors.shopPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kg',
                        style: AppTypography.titleMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${summary.remainingWeight.toStringAsFixed(1)} kg remaining',
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Sold',
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalSoldWeight.toStringAsFixed(1)} kg',
                    style: AppTypography.titleLarge().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'TZS ${_currencyFormat.format(summary.totalRevenue.round())}',
                    style: AppTypography.bodyMedium().copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inventory Health',
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${summary.remainingPercentage.toStringAsFixed(0)}% remaining',
                    style: AppTypography.labelSmall().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: summary.remainingPercentage / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    summary.remainingPercentage > 20
                        ? AppColors.shopPrimary
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockAdditions(CategorySalesSummary summary) {
    if (summary.stockAdditions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space20),
          child: Text('No stock data recorded'),
        ),
      );
    }

    return Column(
      children: summary.stockAdditions
          .map(
            (addition) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space8),
              child: CustomCard(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.processorPrimary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.input,
                        color: AppColors.processorPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch: ${addition.batchNumber}',
                            style: AppTypography.titleSmall(),
                          ),
                          Text(
                            addition.receivedAt != null
                                ? _dateFormat.format(addition.receivedAt!)
                                : 'Unknown date',
                            style: AppTypography.bodySmall().copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${addition.weight.toStringAsFixed(1)} ${addition.weightUnit}',
                          style: AppTypography.titleSmall().copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${addition.weight.toStringAsFixed(1)} ${addition.weightUnit}',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTransactions(CategorySalesSummary summary) {
    if (summary.transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space20),
          child: Text('No sales transactions recorded'),
        ),
      );
    }

    return Column(
      children: summary.transactions
          .map(
            (tx) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space8),
              child: CustomCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.push('/shop/sales/${tx.saleId}'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.customerName ?? 'Walk-in Customer',
                                style: AppTypography.titleSmall(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _dateFormat.format(tx.createdAt),
                                style: AppTypography.bodySmall().copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TZS ${_currencyFormat.format(tx.subtotal.round())}',
                              style: AppTypography.titleSmall().copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '-${tx.weightSold.toStringAsFixed(1)} kg',
                              style: AppTypography.labelSmall().copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
