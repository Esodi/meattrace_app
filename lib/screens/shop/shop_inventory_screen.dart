import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../widgets/core/status_badge.dart';

/// Modern Shop Inventory Screen
/// Features: Product search, category filters, stock status, product management
class ShopInventoryScreen extends StatefulWidget {
  const ShopInventoryScreen({super.key});

  @override
  State<ShopInventoryScreen> createState() => _ShopInventoryScreenState();
}

class _ShopInventoryScreenState extends State<ShopInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final List<String> _categories = ['all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInventory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await productProvider.fetchProducts();
  }

  List<Product> _filterProducts(List<Product> products, int tabIndex, String category, String query) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentShopId = authProvider.user?.shopId;

    // Filter by shop ownership - receivedBy contains the shop ID, not user ID
    var filtered = products.where((p) => p.receivedBy == currentShopId).toList();

    // Filter by stock status (tab)
    filtered = filtered.where((p) {
      switch (tabIndex) {
        case 0: // All
          return true;
        case 1: // In Stock
          return p.quantity > 10;
        case 2: // Low Stock
          return p.quantity > 0 && p.quantity <= 10;
        case 3: // Out of Stock
          return p.quantity == 0;
        default:
          return true;
      }
    }).toList();

    // Filter by category
    if (category != 'all') {
      filtered = filtered.where((p) => 
        p.productType.toLowerCase().contains(category)
      ).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.batchNumber?.toLowerCase().contains(query.toLowerCase()) ?? false ||
        p.productType.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  Color _getStockStatusColor(int tabIndex) {
    switch (tabIndex) {
      case 1: return AppColors.success;
      case 2: return AppColors.warning;
      case 3: return AppColors.error;
      default: return AppColors.shopPrimary;
    }
  }

  String _getStockStatusLabel(Product product) {
    if (product.quantity == 0) return 'Out of Stock';
    if (product.quantity <= 10) return 'Low Stock';
    return 'In Stock';
  }

  Color _getProductStatusColor(Product product) {
    if (product.quantity == 0) return AppColors.error;
    if (product.quantity <= 10) return AppColors.warning;
    return AppColors.success;
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
            Text('Inventory', style: AppTypography.headlineMedium()),
            Text(
              'Manage your product stock',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.shopPrimary),
            tooltip: 'Filters',
            onPressed: () {
              // TODO: Show filter dialog
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.shopPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.shopPrimary,
          labelStyle: AppTypography.labelMedium(),
          unselectedLabelStyle: AppTypography.labelSmall(),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Stock'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Out of Stock'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Category Filters
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                CustomTextField(
                  hint: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: AppTheme.space12),
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.space8),
                        child: FilterChip(
                          label: Text(
                            category.toUpperCase(),
                            style: AppTypography.labelMedium().copyWith(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : 'all';
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.shopPrimary,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isSelected 
                                ? AppColors.shopPrimary 
                                : AppColors.borderLight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Product List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIndex) {
                return Consumer<ProductProvider>(
                  builder: (context, productProvider, child) {
                    if (productProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.shopPrimary,
                        ),
                      );
                    }

                    final filteredProducts = _filterProducts(
                      productProvider.products,
                      tabIndex,
                      _selectedCategory,
                      _searchQuery,
                    );

                    if (filteredProducts.isEmpty) {
                      return _buildEmptyState(tabIndex);
                    }

                    return RefreshIndicator(
                      onRefresh: _loadInventory,
                      color: AppColors.shopPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.space12),
                            child: _buildProductCard(product),
                          );
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Product Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  CustomIcons.meatCut,
                  color: AppColors.shopPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.productType,
                            style: AppTypography.titleMedium(),
                          ),
                        ),
                        StatusBadge(
                          label: _getStockStatusLabel(product),
                          color: _getProductStatusColor(product),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Batch: ${product.batchNumber ?? 'N/A'}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          'Qty: ${product.quantity}',
                          style: AppTypography.bodyMedium(),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Icon(
                          Icons.scale,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          '${product.weight?.toStringAsFixed(1) ?? '0'} kg',
                          style: AppTypography.bodyMedium(),
                        ),
                        const Spacer(),
                        // Show "Add Price" button if price is 0, otherwise show price with edit button
                        if (product.price == 0)
                          ElevatedButton.icon(
                            onPressed: () => _showAddPriceDialog(product),
                            icon: const Icon(Icons.attach_money, size: 22),
                            label: Text(
                              'Add Price',
                              style: AppTypography.bodyMedium().copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.shopPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space20,
                                vertical: AppTheme.space16,
                              ),
                              minimumSize: const Size(140, 48),
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TZS ${product.price.toStringAsFixed(2)}',
                                style: AppTypography.titleMedium().copyWith(
                                  color: AppColors.shopPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space4),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: AppColors.shopPrimary,
                                ),
                                onPressed: () => _showEditPriceDialog(product),
                                tooltip: 'Edit Price',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editProduct(product);
                  } else if (value == 'qr') {
                    _showQRCode(product);
                  } else if (value == 'delete') {
                    _deleteProduct(product);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.textPrimary),
                        const SizedBox(width: AppTheme.space8),
                        Text('Edit', style: AppTypography.bodyMedium()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        Icon(CustomIcons.MEATTRACE_ICON, color: AppColors.textPrimary),
                        const SizedBox(width: AppTheme.space8),
                        Text('Show QR', style: AppTypography.bodyMedium()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          'Delete',
                          style: AppTypography.bodyMedium().copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String message;
    String subtitle;
    
    switch (tabIndex) {
      case 1:
        message = 'No Products In Stock';
        subtitle = 'All your products are either low stock or out of stock.';
        break;
      case 2:
        message = 'No Low Stock Items';
        subtitle = 'Great! All products have sufficient stock.';
        break;
      case 3:
        message = 'No Out of Stock Items';
        subtitle = 'Excellent! All products are available.';
        break;
      default:
        message = 'No Products Found';
        subtitle = _searchQuery.isNotEmpty || _selectedCategory != 'all'
            ? 'Try adjusting your filters'
            : 'Start by receiving products from processing units';
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
                Icons.inventory_2,
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
            if (_searchQuery.isNotEmpty || _selectedCategory != 'all') ...[
              const SizedBox(height: AppTheme.space24),
              CustomButton(
                label: 'Clear Filters',
                variant: ButtonVariant.secondary,
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'all';
                    _searchController.clear();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editProduct(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit product: ${product.productType}'),
        backgroundColor: AppColors.info,
      ),
    );
    // TODO: Navigate to edit product screen
  }

  void _showQRCode(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Row(
        children: [
          Icon(CustomIcons.MEATTRACE_ICON, color: AppColors.shopPrimary),
          const SizedBox(width: AppTheme.space8),
            Text('Product QR Code', style: AppTypography.headlineMedium()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                children: [
                  Icon(
                    CustomIcons.MEATTRACE_ICON,
                    size: 120,
                    color: AppColors.shopPrimary,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    product.productType,
                    style: AppTypography.titleMedium(),
                  ),
                  Text(
                    'Batch: ${product.batchNumber ?? 'N/A'}',
                    style: AppTypography.bodySmall().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'QR generation coming soon',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            variant: ButtonVariant.secondary,
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text('Delete Product?', style: AppTypography.headlineMedium()),
        content: Text(
          'Are you sure you want to delete ${product.productType}? This action cannot be undone.',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTypography.button()),
          ),
          CustomButton(
            label: 'Delete',
            customColor: AppColors.error,
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete functionality coming soon'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddPriceDialog(Product product) {
    final priceController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(Icons.attach_money, color: AppColors.shopPrimary),
              const SizedBox(width: AppTheme.space8),
              Text('Add Price', style: AppTypography.headlineMedium()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product: ${product.productType}',
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Batch: ${product.batchNumber ?? 'N/A'}',
                style: AppTypography.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              CustomTextField(
                controller: priceController,
                hint: 'Enter price',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(Icons.attach_money, color: AppColors.textSecondary),
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel', style: AppTypography.button()),
            ),
            CustomButton(
              label: 'Save Price',
              loading: isLoading,
              onPressed: isLoading
                  ? null
                  : () async {
                      final priceText = priceController.text.trim();
                      if (priceText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a price'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }

                      final price = double.tryParse(priceText);
                      if (price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid price greater than 0'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final productProvider = Provider.of<ProductProvider>(context, listen: false);
                        
                        // Update product with new price
                        final updatedProduct = product.copyWith(
                          price: price,
                          quantity: 0, // Set to 0 to trigger partial update in service
                        );
                        
                        await productProvider.updateProduct(updatedProduct);
                        
                        // Refresh the inventory list
                        await _loadInventory();

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Price updated to TZS ${price.toStringAsFixed(2)}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update price: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPriceDialog(Product product) {
    final priceController = TextEditingController(
      text: product.price.toStringAsFixed(2),
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: AppColors.shopPrimary),
              const SizedBox(width: AppTheme.space8),
              Text('Edit Price', style: AppTypography.headlineMedium()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product: ${product.productType}',
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Batch: ${product.batchNumber ?? 'N/A'}',
                style: AppTypography.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Current Price: TZS ${product.price.toStringAsFixed(2)}',
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.shopPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              CustomTextField(
                controller: priceController,
                hint: 'Enter new price',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(Icons.attach_money, color: AppColors.textSecondary),
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel', style: AppTypography.button()),
            ),
            CustomButton(
              label: 'Update Price',
              loading: isLoading,
              onPressed: isLoading
                  ? null
                  : () async {
                      final priceText = priceController.text.trim();
                      if (priceText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a price'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }

                      final price = double.tryParse(priceText);
                      if (price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid price greater than 0'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }

                      // Check if price hasn't changed
                      if (price == product.price) {
                        Navigator.of(context).pop();
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final productProvider = Provider.of<ProductProvider>(context, listen: false);
                        
                        // Update product with new price
                        final updatedProduct = product.copyWith(
                          price: price,
                          quantity: 0, // Set to 0 to trigger partial update in service
                        );
                        
                        await productProvider.updateProduct(updatedProduct);
                        
                        // Refresh the inventory list
                        await _loadInventory();

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Price updated to TZS ${price.toStringAsFixed(2)}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update price: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
