import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/scan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/status_badge.dart';
import '../../widgets/livestock/traceability_timeline.dart';

/// Product Display Screen - Shows detailed product information after QR scan
class ProductDisplayScreen extends StatefulWidget {
  final String productId;
  final String? source; // 'shop', 'processor', etc.

  const ProductDisplayScreen({
    Key? key,
    required this.productId,
    this.source,
  }) : super(key: key);

  @override
  State<ProductDisplayScreen> createState() => _ProductDisplayScreenState();
}

class _ProductDisplayScreenState extends State<ProductDisplayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProduct();
      // Debug logs for new fields
      print('Product Display Screen: initState called');
    });
  }

  Future<void> _loadProduct() async {
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    await scanProvider.fetchProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Product Details',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProduct(),
            tooltip: 'Share Product',
          ),
        ],
      ),
      body: Consumer<ScanProvider>(
        builder: (context, scanProvider, child) {
          if (scanProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    'Loading product information...',
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (scanProvider.error != null) {
            return _buildErrorState(scanProvider.error!);
          }

          final product = scanProvider.currentProduct;
          if (product == null) {
            return _buildErrorState('Product not found');
          }

          // Debug logs for new fields
          print('Product Display: processingUnitName: ${product.processingUnitName}');
          print('Product Display: animalAnimalId: ${product.animalAnimalId}');
          print('Product Display: animalSpecies: ${product.animalSpecies}');
          print('Product Display: receivedByName: ${product.receivedByName}');

          return _buildProductDetails(product, isDark);
        },
      ),
    );
  }

  Widget _buildProductDetails(Product product, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role;
    final isShop = userRole == 'shop';

    return RefreshIndicator(
      onRefresh: _loadProduct,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header Card
            _buildHeaderCard(product, isDark),
            const SizedBox(height: AppTheme.space16),

            // Product Information
            _buildInfoSection(product, isDark),
            const SizedBox(height: AppTheme.space16),

            // Transfer Status (if applicable)
            if (product.transferredTo != null || product.receivedBy != null)
              _buildTransferSection(product, isDark),

            if (product.transferredTo != null || product.receivedBy != null)
              const SizedBox(height: AppTheme.space16),

            // Traceability Timeline
            if (product.timeline.isNotEmpty) ...[
              _buildTimelineSection(product, isDark),
              const SizedBox(height: AppTheme.space16),
            ],

            // Action Buttons (for shop users)
            if (isShop && product.transferredTo != null && product.receivedBy == null)
              _buildActionButtons(product),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Product product, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.shopPrimary,
            AppColors.shopPrimary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.shopPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.headlineMedium(color: Colors.white),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'ID: ${product.id}',
                      style: AppTypography.bodyMedium(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              _buildHeaderChip(
                Icons.category,
                product.productType,
                Colors.white,
              ),
              const SizedBox(width: AppTheme.space8),
              _buildHeaderChip(
                Icons.numbers,
                'Batch: ${product.batchNumber}',
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.space4),
          Text(
            label,
            style: AppTypography.labelMedium(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Product product, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Information',
            style: AppTypography.headlineSmall(),
          ),
          const SizedBox(height: AppTheme.space16),
          _buildInfoRow(Icons.monitor_weight, 'Weight',
            '${product.weight ?? 'N/A'} ${product.weightUnit}'),
          _buildInfoRow(Icons.inventory, 'Quantity',
            '${product.quantity} units'),
          _buildInfoRow(Icons.attach_money, 'Price',
            '\$${product.price.toStringAsFixed(2)}'),
          _buildInfoRow(Icons.factory, 'Manufacturer',
            product.manufacturer),
          if (product.processingUnitName != null)
            _buildInfoRow(Icons.business, 'Processing Unit',
              product.processingUnitName!),
          if (product.animalAnimalId != null)
            _buildInfoRow(Icons.tag, 'Animal ID',
              product.animalAnimalId!),
          if (product.animalSpecies != null)
            _buildInfoRow(Icons.pets, 'Animal Species',
              product.animalSpecies!),
          _buildInfoRow(Icons.calendar_today, 'Created',
            _formatDate(product.createdAt)),
          if (product.description.isNotEmpty) ...[
            const Divider(height: AppTheme.space24),
            Text(
              'Description',
              style: AppTypography.labelLarge(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              product.description,
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  value,
                  style: AppTypography.bodyMedium(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSection(Product product, bool isDark) {
    final isReceived = product.receivedBy != null;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isReceived 
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReceived ? Icons.check_circle : Icons.pending,
                color: isReceived ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Transfer Status',
                style: AppTypography.headlineSmall(),
              ),
              const Spacer(),
              StatusBadge(
                label: isReceived ? 'Received' : 'Pending',
                color: isReceived ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          if (product.transferredAt != null)
            _buildInfoRow(Icons.send, 'Transferred', 
              _formatDateTime(product.transferredAt!)),
          if (product.transferredToName != null)
            _buildInfoRow(Icons.store, 'Transferred To', 
              product.transferredToName!),
          if (product.receivedAt != null)
            _buildInfoRow(Icons.check, 'Received', 
              _formatDateTime(product.receivedAt!)),
          if (product.receivedByName != null)
            _buildInfoRow(Icons.person, 'Received By',
              product.receivedByName!),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(Product product, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traceability Timeline',
            style: AppTypography.headlineSmall(),
          ),
          const SizedBox(height: AppTheme.space16),
          TraceabilityTimeline(
            events: product.timeline.map((e) => TimelineEvent(
              title: e.action,
              timestamp: e.timestamp,
              location: e.location,
              icon: _getIconForStage(e.stage),
              color: _getColorForStage(e.stage),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Product product) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Receive This Product',
          onPressed: () => _receiveProduct(product),
          icon: Icons.check_circle,
        ),
        const SizedBox(height: AppTheme.space12),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Scanner'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.shopPrimary,
            side: BorderSide(color: AppColors.shopPrimary),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Error Loading Product',
              style: AppTypography.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              error,
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            PrimaryButton(
              label: 'Retry',
              onPressed: _loadProduct,
              icon: Icons.refresh,
            ),
            const SizedBox(height: AppTheme.space12),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receiveProduct(Product product) async {
    // Navigate to receive products screen or handle receipt
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: const Text('Receive Product'),
        content: Text(
          'Confirm receipt of ${product.name}?',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Confirm',
            onPressed: () => Navigator.of(context).pop(true),
            size: ButtonSize.small,
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Navigate to receive products screen with this product pre-selected
      context.go('/receive-products');
    }
  }

  void _shareProduct() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}

  IconData _getIconForStage(int? stage) {
    if (stage == null) return Icons.info;
    switch (stage) {
      case 1:
        return Icons.agriculture;
      case 2:
        return Icons.factory;
      case 3:
        return Icons.local_shipping;
      case 4:
        return Icons.store;
      default:
        return Icons.timeline;
    }
  }

  Color _getColorForStage(int? stage) {
    if (stage == null) return AppColors.info;
    switch (stage) {
      case 1:
        return AppColors.farmerPrimary;
      case 2:
        return AppColors.processorPrimary;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.shopPrimary;
      default:
        return AppColors.info;
    }
  }