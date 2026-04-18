import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/sale.dart';
import '../../models/shop.dart';
import '../../services/sale_service.dart';
import '../../services/shop_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/printer/receipt_printer.dart';

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
  final ShopService _shopService = ShopService();

  Sale? _sale;
  Shop? _shop;
  bool _isLoading = true;
  String? _error;

  final DateFormat _dateFormat = DateFormat('EEEE, MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  final NumberFormat _currencyFormat = NumberFormat('#,###');

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
      final sale = await _saleService.getSale(widget.saleId);

      // Try to load shop info
      Shop? shop;
      try {
        shop = await _shopService.getShop(sale.shop);
      } catch (e) {
        // Ignored, we'll just fall back to "NYAMA TAMU"
      }

      if (mounted) {
        setState(() {
          _sale = sale;
          _shop = shop;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareReceipt() async {
    if (_sale == null) return;

    final sale = _sale!;
    final shopName = _shop?.name ?? 'Nyama Tamu Shop';

    String shareText = 'Receipt from $shopName\n';
    if (sale.receiptUuid != null) {
      shareText += 'Receipt No: ${sale.receiptUuid}\n';
    } else {
      shareText += 'Sale ID: ${sale.id}\n';
    }

    shareText += 'Total: TZS ${_currencyFormat.format(sale.totalAmount)}\n';
    shareText += 'Date: ${_dateFormat.format(sale.createdAt)}\n\n';

    if (sale.publicReceiptUrl != null) {
      final baseUrl = Constants.baseUrl.replaceAll('/api/v2', '');
      final url = '$baseUrl${sale.publicReceiptUrl}';
      shareText += 'View your digital receipt here:\n$url';
    }

    await Share.share(shareText, subject: 'Receipt #$sale.id');
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Sale Details', style: AppTypography.headlineMedium()),
        actions: [
          if (_sale != null)
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.shopPrimary),
              tooltip: 'Share Receipt',
              onPressed: _shareReceipt,
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
              CustomButton(label: 'Retry', onPressed: _loadData),
            ],
          ),
        ),
      );
    }

    if (_sale == null) {
      return const Center(child: Text('Sale not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
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
            if (_sale!.publicReceiptUrl != null) _buildQRCodeCard(),

            const SizedBox(height: AppTheme.space16),

            // Actions
            _buildActionsCard(),

            // Add padding to bottom
            const SizedBox(height: AppTheme.space32),
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
                const Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppColors.shopPrimary,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  _shop?.name.toUpperCase() ?? 'NYAMA TAMU',
                  style: AppTypography.headlineMedium().copyWith(
                    letterSpacing: 2,
                    color: AppColors.shopPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (sale.receiptUuid != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Receipt #${sale.receiptUuid!.substring(0, 8)}',
                      style: AppTypography.titleMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Text(
                    'Order #${sale.id}',
                    style: AppTypography.titleMedium().copyWith(
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
                _buildInfoRow(
                  Icons.person_pin,
                  'Cashier ID',
                  sale.soldBy.toString(),
                ),

                const SizedBox(height: AppTheme.space12),
                const Divider(color: AppColors.borderLight),
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
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: AppTheme.space12),
                ],

                // Items (Table Layout)
                Text(
                  'ITEMS',
                  style: AppTypography.labelMedium().copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),

                // Table Header
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Item',
                        style: AppTypography.bodySmall().copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Qty/Wt',
                        textAlign: TextAlign.right,
                        style: AppTypography.bodySmall().copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: AppTypography.bodySmall().copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: AppTheme.space8),

                ...sale.items.map((item) => _buildItemTableRow(item)),

                const SizedBox(height: AppTheme.space12),
                const Divider(color: AppColors.borderLight),
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
                      'TZS ${_currencyFormat.format(sale.totalAmount)}',
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
                      const Icon(
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

  Widget _buildItemTableRow(SaleItem item) {
    final qtyStr = item.weight > 0
        ? '${item.weight.toStringAsFixed(1)}${item.weightUnit}'
        : item.quantity.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item.productName ?? 'Product #${item.product}',
                  style: AppTypography.bodyMedium().copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  qtyStr,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyMedium(),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _currencyFormat.format(item.subtotal),
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.batchNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Batch: ${item.batchNumber}',
                style: AppTypography.caption().copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemQr(SaleItem item) {
    final url = '${Constants.baseUrl}/product-info/view/${item.product}/';
    final label = item.productName ?? 'Product #${item.product}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.batchNumber != null)
            Text(
              'Batch: ${item.batchNumber}',
              style: AppTypography.caption().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: AppTheme.space8),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 160,
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
        ],
      ),
    );
  }

  Widget _buildQRCodeCard() {
    final sale = _sale!;

    return CustomCard(
      child: Column(
        children: [
          Text('Trace Each Item', style: AppTypography.titleMedium()),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Scan an item\'s QR to view its traceability — same code the processor printed.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          ...sale.items.map(_buildItemQr),
          const SizedBox(height: AppTheme.space16),
          if (sale.receiptUuid != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt ID:',
                          style: AppTypography.caption().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          sale.receiptUuid!,
                          style: AppTypography.labelSmall().copyWith(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 20,
                      color: AppColors.shopPrimary,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: sale.receiptUuid!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Receipt ID copied to clipboard'),
                        ),
                      );
                      }
                    },
                    tooltip: 'Copy ID',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return CustomCard(
      child: Column(
        children: [
          CustomButton(
            label: 'Print Thermal Receipt',
            icon: Icons.print,
            onPressed: () => ReceiptPrinter.printSaleReceipt(
              context,
              _sale!,
              shopName: _shop?.name,
            ),
            fullWidth: true,
          ),
          const SizedBox(height: AppTheme.space12),
          CustomButton(
            label: 'Share Digital Receipt',
            icon: Icons.share,
            variant: ButtonVariant.secondary,
            onPressed: _shareReceipt,
            fullWidth: true,
          ),
          const SizedBox(height: AppTheme.space12),
          CustomButton(
            label: 'View Product Tracking',
            icon: Icons.timeline,
            variant: ButtonVariant.outlined,
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
