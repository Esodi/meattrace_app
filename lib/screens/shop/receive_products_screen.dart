import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/status_badge.dart';

/// Receive Products Screen - Shop receives incoming product transfers
class ReceiveProductsScreen extends StatefulWidget {
  const ReceiveProductsScreen({super.key});

  @override
  State<ReceiveProductsScreen> createState() => _ReceiveProductsScreenState();
}

class _ReceiveProductsScreenState extends State<ReceiveProductsScreen> {
  bool _isLoading = false;
  List<Product> _pendingProducts = [];

  // State management for selected products
  final Set<int> _selectedProducts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingProducts();
    });
  }

  Future<void> _loadPendingProducts() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Fetch products with pending_receipt=true to get only unreceived products
      // The backend will automatically filter by shop based on user's role
      await productProvider.fetchProducts(pendingReceipt: true);

      // All products returned are already filtered as pending
      final pending = productProvider.products;

      print('🔍 RECEIVE_PRODUCTS_SCREEN - Pending products from API: ${pending.length}');

      setState(() => _pendingProducts = pending);
    } catch (e) {
      print('❌ RECEIVE_PRODUCTS_SCREEN - Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _receiveSelectedProducts() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select products to receive')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      // Receive products
      await productProvider.receiveProducts(_selectedProducts.toList());

      // Refresh the product list to reflect received status
      await productProvider.fetchProducts();

      // Calculate total items received
      final totalProducts = _selectedProducts.length;
      
      // Get details of received products for better feedback
      final receivedProductNames = _pendingProducts
          .where((p) => _selectedProducts.contains(p.id))
          .map((p) => p.name)
          .take(3)
          .toList();
      
      String message = 'Successfully received $totalProducts product(s)';
      if (receivedProductNames.isNotEmpty) {
        message += ': ${receivedProductNames.join(", ")}';
        if (totalProducts > 3) {
          message += ' and ${totalProducts - 3} more';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View Inventory',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to inventory screen
                context.go('/shop-inventory');
              },
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving products: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelections = _selectedProducts.isNotEmpty;
    final totalProducts = _selectedProducts.length;

    String selectionText = totalProducts > 0 ? '$totalProducts Selected' : '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Receive Products',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          IconButton(
            icon: const Icon(CustomIcons.MEATTRACE_ICON),
            onPressed: () => _openQRScanner(),
            tooltip: 'Scan QR Code',
          ),
          if (hasSelections)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.shopPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    selectionText,
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.shopPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.shopPrimary,
              ),
            )
          : _pendingProducts.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildInfoBanner(),
                    _buildActionButtons(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPendingProducts,
                        color: AppColors.shopPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          itemCount: _pendingProducts.length,
                          itemBuilder: (context, index) {
                            final product = _pendingProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: hasSelections
          ? Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  label: 'Receive $totalProducts Product(s)',
                  onPressed: _isLoading ? null : _receiveSelectedProducts,
                  loading: _isLoading,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 24,
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Transfers',
                  style: AppTypography.labelLarge().copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  '${_pendingProducts.length} product(s) waiting to be received',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasAnySelections = _selectedProducts.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  if (hasAnySelections) {
                    // Deselect all
                    _selectedProducts.clear();
                  } else {
                    // Select all pending products
                    _selectedProducts.addAll(
                      _pendingProducts.map((p) => p.id!)
                    );
                  }
                });
              },
              icon: Icon(
                hasAnySelections
                    ? Icons.deselect
                    : Icons.select_all,
                size: 20,
              ),
              label: Text(
                hasAnySelections
                    ? 'Deselect All'
                    : 'Select All',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.shopPrimary,
                side: BorderSide(color: AppColors.shopPrimary),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: !hasAnySelections
                  ? null
                  : () {
                      setState(() {
                        _selectedProducts.clear();
                      });
                    },
              icon: const Icon(Icons.clear, size: 20),
              label: const Text('Clear'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProducts.contains(product.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isSelected
              ? AppColors.shopPrimary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedProducts.remove(product.id);
            } else {
              _selectedProducts.add(product.id!);
            }
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Selection Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedProducts.add(product.id!);
                    } else {
                      _selectedProducts.remove(product.id);
                    }
                  });
                },
                activeColor: AppColors.shopPrimary,
              ),
              const SizedBox(width: AppTheme.space12),

              // Product Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: AppColors.shopPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.space12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTypography.bodyLarge().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                            product.productType,
                            style: AppTypography.caption().copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Batch: ${product.batchNumber ?? 'N/A'}',
                      style: AppTypography.bodyMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Wrap(
                      spacing: AppTheme.space8,
                      runSpacing: AppTheme.space4,
                      children: [
                        _buildInfoChip(
                          Icons.monitor_weight,
                          '${product.weight ?? 0} ${product.weightUnit ?? 'kg'}',
                        ),
                        _buildInfoChip(
                          Icons.inventory,
                          '${product.quantity} units',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transfer Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    label: 'Pending',
                    color: AppColors.warning,
                  ),
                  if (product.transferredAt != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      _formatDate(product.transferredAt!),
                      style: AppTypography.caption().copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: AppTheme.space4),
          Text(
            label,
            style: AppTypography.caption().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2,
                size: 60,
                color: AppColors.shopPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'No Pending Transfers',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'There are no products waiting to be received.\nCheck back later for new transfers.',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            OutlinedButton.icon(
              onPressed: _loadPendingProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.shopPrimary,
                side: BorderSide(color: AppColors.shopPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _openQRScanner() async {
    // Navigate to QR scanner
    final result = await Navigator.pushNamed(
      context,
      '/qr-scanner',
      arguments: {'source': 'shop'},
    );

    // Refresh the list after scanning
    if (result != null && mounted) {
      await _loadPendingProducts();
    }
  }
}