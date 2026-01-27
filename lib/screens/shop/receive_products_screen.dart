import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/status_badge.dart';
import '../../widgets/dialogs/product_rejection_dialog.dart';

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

  // Track products to receive with quantities and weights
  final Map<int, double> _receiveQuantities = {};
  final Map<int, double> _receiveWeights = {};

  // Track products to reject with quantities, weights and reasons
  final Map<int, Map<String, dynamic>> _rejections = {};

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
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Fetch products with pending_receipt=true to get only unreceived products
      // The backend will automatically filter by shop based on user's role
      await productProvider.fetchProducts(pendingReceipt: true);

      // All products returned are already filtered as pending
      final pending = productProvider.products;

      print(
        '🔍 RECEIVE_PRODUCTS_SCREEN - Pending products from API: ${pending.length}',
      );

      setState(() => _pendingProducts = pending);
    } catch (e) {
      print('❌ RECEIVE_PRODUCTS_SCREEN - Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _receiveSelectedProducts() async {
    if (_selectedProducts.isEmpty && _rejections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select products to receive or reject'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Build receives array
      final List<Map<String, dynamic>> receives = [];
      for (final productId in _selectedProducts) {
        // Skip if this product is being rejected
        if (_rejections.containsKey(productId)) continue;

        final product = _pendingProducts.firstWhere((p) => p.id == productId);
        final quantityToReceive =
            _receiveQuantities[productId] ?? product.quantity.toDouble();
        final weightToReceive =
            _receiveWeights[productId] ?? (product.weight ?? 0.0);

        receives.add({
          'product_id': productId,
          'quantity_received': quantityToReceive,
          'weight_received': weightToReceive,
        });
      }

      // Build rejections array
      final List<Map<String, dynamic>> rejections = [];
      for (final entry in _rejections.entries) {
        rejections.add({
          'product_id': entry.key,
          'quantity_rejected': entry.value['quantity'],
          'weight_rejected': entry.value['weight'],
          'rejection_reason': entry.value['reason'],
        });
      }

      // Call API with both receives and rejections
      await productProvider.receiveProducts(
        receives: receives.isNotEmpty ? receives : null,
        rejections: rejections.isNotEmpty ? rejections : null,
      );

      // Refresh the product list to reflect received status
      await productProvider.fetchProducts();

      // Calculate totals for feedback
      final totalReceived = receives.length;
      final totalRejected = rejections.length;

      if (mounted) {
        String message = '';
        if (totalReceived > 0 && totalRejected > 0) {
          message =
              'Received $totalReceived and rejected $totalRejected product(s)';
        } else if (totalReceived > 0) {
          message = 'Successfully received $totalReceived product(s)';
        } else if (totalRejected > 0) {
          message = 'Successfully rejected $totalRejected product(s)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: totalRejected > 0
                ? AppColors.warning
                : AppColors.success,
            duration: const Duration(seconds: 4),
            action: totalReceived > 0
                ? SnackBarAction(
                    label: 'View Inventory',
                    textColor: Colors.white,
                    onPressed: () {
                      context.go('/shop-inventory');
                    },
                  )
                : null,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing products: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectProduct(Product product) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProductRejectionDialog(product: product),
    );

    if (result != null) {
      setState(() {
        // Add to rejections
        _rejections[product.id!] = {
          'quantity': result['quantity'],
          'weight': result['weight'],
          'reason': result['reason'],
          'reject_all': result['reject_all'],
          'is_weight_based': result['is_weight_based'],
        };

        // If partial rejection, also add to receives for remaining quantity
        if (!result['reject_all']) {
          final remainingQuantity =
              product.quantity.toDouble() - (result['quantity'] as double);
          final remainingWeight =
              (product.weight ?? 0.0) - (result['weight'] as double);

          if (remainingQuantity > 0 || remainingWeight > 0) {
            _selectedProducts.add(product.id!);
            _receiveQuantities[product.id!] = remainingQuantity > 0
                ? remainingQuantity
                : 0.0;
            _receiveWeights[product.id!] = remainingWeight > 0
                ? remainingWeight
                : 0.0;
          }
        } else {
          // Full rejection - remove from selected products
          _selectedProducts.remove(product.id);
          _receiveQuantities.remove(product.id);
          _receiveWeights.remove(product.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['reject_all']
                ? 'Product marked for rejection'
                : 'Partial rejection: ${result['quantity']} units',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _rejections.remove(product.id);
                _selectedProducts.remove(product.id);
                _receiveQuantities.remove(product.id);
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelections =
        _selectedProducts.isNotEmpty || _rejections.isNotEmpty;
    final totalToReceive = _selectedProducts
        .where((id) => !_rejections.containsKey(id))
        .length;
    final totalToReject = _rejections.length;

    String selectionText = '';
    if (totalToReceive > 0 && totalToReject > 0) {
      selectionText = '$totalToReceive to receive, $totalToReject to reject';
    } else if (totalToReceive > 0) {
      selectionText = '$totalToReceive to receive';
    } else if (totalToReject > 0) {
      selectionText = '$totalToReject to reject';
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Receive Products', style: AppTypography.headlineMedium()),
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
              child: CircularProgressIndicator(color: AppColors.shopPrimary),
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
                  label: totalToReceive > 0 && totalToReject > 0
                      ? 'Process All ($totalToReceive + $totalToReject)'
                      : totalToReceive > 0
                      ? 'Receive $totalToReceive Product(s)'
                      : 'Reject $totalToReject Product(s)',
                  onPressed: _isLoading ? null : _receiveSelectedProducts,
                  loading: _isLoading,
                  customColor: totalToReject > 0 && totalToReceive == 0
                      ? AppColors.error
                      : null,
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
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
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
                      _pendingProducts.map((p) => p.id!),
                    );
                  }
                });
              },
              icon: Icon(
                hasAnySelections ? Icons.deselect : Icons.select_all,
                size: 20,
              ),
              label: Text(hasAnySelections ? 'Deselect All' : 'Select All'),
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
                side: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProducts.contains(product.id);
    final isRejected = _rejections.containsKey(product.id);
    final isPartialRejection =
        isRejected && !(_rejections[product.id]!['reject_all'] as bool);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: isSelected || isRejected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isRejected
              ? AppColors.error
              : isSelected
              ? AppColors.shopPrimary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection Checkbox (hidden if rejected fully)
                if (!isRejected || isPartialRejection)
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
                  )
                else
                  const SizedBox(width: 48),
                const SizedBox(width: AppTheme.space12),

                // Product Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isRejected
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.shopPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    isRejected ? Icons.cancel : Icons.inventory_2,
                    color: isRejected ? AppColors.error : AppColors.shopPrimary,
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
                                decoration: isRejected && !isPartialRejection
                                    ? TextDecoration.lineThrough
                                    : null,
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
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
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
                        'Batch: ${product.batchNumber}',
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
                            '${product.weight} ${product.weightUnit}',
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

                // Status Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: isRejected
                          ? (isPartialRejection ? 'Partial Reject' : 'Rejected')
                          : 'Pending',
                      color: isRejected ? AppColors.error : AppColors.warning,
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

            // Rejection Info Banner
            if (isRejected) ...[
              const SizedBox(height: AppTheme.space12),
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          'Rejection Details',
                          style: AppTypography.labelMedium().copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Quantity: ${_rejections[product.id]!['quantity']} units${_rejections[product.id]!['weight'] > 0 ? ' / ${_rejections[product.id]!['weight']} ${product.weightUnit}' : ''}',
                      style: AppTypography.bodySmall(),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Reason: ${_rejections[product.id]!['reason']}',
                      style: AppTypography.bodySmall(),
                    ),
                    if (isPartialRejection) ...[
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        'Accepting: ${(product.quantity.toDouble() - (_rejections[product.id]!['quantity'] as double)).toStringAsFixed(1)} units'
                        ' / ${((product.weight ?? 0.0) - (_rejections[product.id]!['weight'] as double)).toStringAsFixed(1)} ${product.weightUnit}',
                        style: AppTypography.bodySmall().copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action Buttons
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                if (!isRejected)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectProduct(product),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space12,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _rejections.remove(product.id);
                          _selectedProducts.remove(product.id);
                          _receiveQuantities.remove(product.id);
                        });
                      },
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Undo Rejection'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space12,
                        ),
                      ),
                    ),
                  ),
                if (!isRejected) ...[
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedProducts.remove(product.id);
                          } else {
                            _selectedProducts.add(product.id!);
                          }
                        });
                      },
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        size: 18,
                      ),
                      label: Text(isSelected ? 'Selected' : 'Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppColors.shopPrimary
                            : AppColors.shopPrimary.withValues(alpha: 0.1),
                        foregroundColor: isSelected
                            ? Colors.white
                            : AppColors.shopPrimary,
                        elevation: isSelected ? 2 : 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.space12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
            Text('No Pending Transfers', style: AppTypography.headlineMedium()),
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
