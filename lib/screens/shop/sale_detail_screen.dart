import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/sale.dart';
import '../../services/sale_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_button.dart';

/// Sale Detail Screen
/// Displays receipt-like view of a single sale transaction
class SaleDetailScreen extends StatefulWidget {
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final SaleService _saleService = SaleService();

  Sale? _sale;
  bool _isLoading = true;
  String? _error;

  final DateFormat _dateFormat = DateFormat('EEEE, MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadSale();
  }

  Future<void> _loadSale() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sale = await _saleService.getSale(widget.saleId);
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash Payment';
      case 'card':
        return 'Card Payment';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return method;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments;
      case 'card':
        return Icons.credit_card;
      case 'mobile_money':
        return Icons.phone_android;
      default:
        return Icons.payment;
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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Sale Details', style: AppTypography.headlineMedium()),
        actions: [
          if (_sale != null)
            IconButton(
              icon: Icon(Icons.share, color: AppColors.shopPrimary),
              tooltip: 'Share Receipt',
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
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
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Failed to load sale',
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
              CustomButton(label: 'Retry', onPressed: _loadSale),
            ],
          ),
        ),
      );
    }

    if (_sale == null) {
      return const Center(child: Text('Sale not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadSale,
      color: AppColors.shopPrimary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Receipt Card
            _buildReceiptCard(),

            const SizedBox(height: AppTheme.space16),

            // QR Code Card
            if (_sale!.receiptUuid != null) _buildQRCodeCard(),

            const SizedBox(height: AppTheme.space16),

            // Actions
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    final sale = _sale!;

    return CustomCard(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppColors.shopPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppColors.shopPrimary,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'SALE RECEIPT',
                  style: AppTypography.headlineMedium().copyWith(
                    letterSpacing: 2,
                    color: AppColors.shopPrimary,
                  ),
                ),
                Text(
                  '#${sale.id}',
                  style: AppTypography.titleLarge().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date',
                  _dateFormat.format(sale.createdAt),
                ),
                _buildInfoRow(
                  Icons.access_time,
                  'Time',
                  _timeFormat.format(sale.createdAt),
                ),

                const SizedBox(height: AppTheme.space12),
                Divider(color: AppColors.borderLight),
                const SizedBox(height: AppTheme.space12),

                // Customer
                if (sale.customerName != null ||
                    sale.customerPhone != null) ...[
                  Text(
                    'CUSTOMER',
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  if (sale.customerName != null)
                    _buildInfoRow(Icons.person, 'Name', sale.customerName!),
                  if (sale.customerPhone != null)
                    _buildInfoRow(Icons.phone, 'Phone', sale.customerPhone!),
                  const SizedBox(height: AppTheme.space12),
                  Divider(color: AppColors.borderLight),
                  const SizedBox(height: AppTheme.space12),
                ],

                // Items
                Text(
                  'ITEMS',
                  style: AppTypography.labelMedium().copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                ...sale.items.map((item) => _buildItemRow(item)),

                const SizedBox(height: AppTheme.space12),
                Divider(color: AppColors.borderLight),
                const SizedBox(height: AppTheme.space12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'TZS ${_currencyFormat.format(sale.totalAmount.round())}',
                      style: AppTypography.headlineMedium().copyWith(
                        color: AppColors.shopPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.space16),

                // Payment Method
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getPaymentIcon(sale.paymentMethod),
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        _formatPaymentMethod(sale.paymentMethod),
                        style: AppTypography.titleMedium().copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppTheme.space8),
          Text(
            '$label: ',
            style: AppTypography.bodyMedium().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium().copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(SaleItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Product #${item.product}',
                      style: AppTypography.titleMedium(),
                    ),
                    if (item.batchNumber != null)
                      Text(
                        'Batch: ${item.batchNumber}',
                        style: AppTypography.bodySmall().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'TZS ${_currencyFormat.format(item.subtotal.round())}',
                style: AppTypography.titleMedium().copyWith(
                  color: AppColors.shopPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              _buildItemDetail('Qty', item.quantity.toStringAsFixed(0)),
              const SizedBox(width: AppTheme.space16),
              _buildItemDetail(
                'Weight',
                '${item.weight.toStringAsFixed(2)} ${item.weightUnit}',
              ),
              const SizedBox(width: AppTheme.space16),
              _buildItemDetail(
                'Price',
                'TZS ${_currencyFormat.format(item.unitPrice.round())}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.bodySmall().copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall().copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeCard() {
    final sale = _sale!;

    return CustomCard(
      child: Column(
        children: [
          Text('Digital Receipt', style: AppTypography.titleMedium()),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Scan to view receipt details',
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: QrImageView(
              data: sale.receiptUuid ?? 'sale-${sale.id}',
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF333333),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Receipt ID: ${sale.receiptUuid?.substring(0, 8) ?? sale.id}...',
            style: AppTypography.labelSmall().copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return CustomCard(
      child: Column(
        children: [
          CustomButton(
            label: 'Print Receipt',
            icon: Icons.print,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print feature coming soon')),
              );
            },
            fullWidth: true,
          ),
          const SizedBox(height: AppTheme.space12),
          CustomButton(
            label: 'View Product Tracking',
            icon: Icons.timeline,
            variant: ButtonVariant.secondary,
            onPressed: () {
              if (_sale != null && _sale!.items.isNotEmpty) {
                final firstItem = _sale!.items.first;
                final productName = firstItem.productName ?? 'Unknown';
                context.push('/shop/product-sales/$productName');
              }
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
