import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/product_category_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';

/// Products Dashboard - View all products with categories and filters
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _loadProducts();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
        Provider.of<ProductCategoryProvider>(
          context,
          listen: false,
        ).fetchCategories(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    return products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            product.name.toLowerCase().contains(_searchQuery) ||
            (product.batchNumber.toLowerCase().contains(_searchQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Category filter (product type)
      if (_selectedCategory != 'All' &&
          product.productType != _selectedCategory) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Products', style: AppTypography.headlineMedium()),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/qr-scanner?source=processor'),
            tooltip: 'Scan QR',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-product'),
            tooltip: 'Create Product',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),

            // Category Tabs
            _buildCategoryTabs(),

            // Products List
            Expanded(child: _buildProductsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-product'),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
        backgroundColor: AppColors.processorPrimary,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Consumer<ProductCategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = [
          'All',
          ...categoryProvider.categories.map((c) => c.name),
        ];

        return SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.processorPrimary.withOpacity(0.2),
                  checkmarkColor: AppColors.processorPrimary,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (_isLoading && productProvider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.error != null) {
          return _buildErrorState(productProvider.error!);
        }

        final filteredProducts = _getFilteredProducts(productProvider.products);

        if (filteredProducts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadProducts,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProductCard(product),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return CustomCard(
      onTap: () => context.push('/products/${product.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 16),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.headlineSmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.batchNumber ?? 'No batch',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.weight ?? 0} kg',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2) ?? '0.00'}',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(
                        label: _getStockLabel(product),
                        color: _getStockColor(product),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // QR Button
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQRCode(product),
              color: AppColors.processorPrimary,
              tooltip: 'Show QR Code',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: AppTypography.bodyMedium()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No products found',
              style: AppTypography.headlineMedium(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'Try adjusting your filters or search'
                  : 'Start by creating your first product',
              style: AppTypography.bodyLarge(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTypography.headlineMedium(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: AppTypography.bodyLarge(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.qr_code, size: 150)),
            ),
            const SizedBox(height: 16),
            Text(
              product.batchNumber ?? 'No batch',
              style: AppTypography.bodyLarge(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Print QR code
              Navigator.pop(context);
            },
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  String _getStockLabel(Product product) {
    // Check if product has been transferred to a shop
    if (product.transferredTo != null) {
      return '📦 Transferred';
    }

    // If not transferred, it's in stock at processing unit
    if (product.quantity > 0) {
      return '✓ In Stock';
    }

    return '❌ Out of Stock';
  }

  Color _getStockColor(Product product) {
    // Check if product has been transferred to a shop
    if (product.transferredTo != null) {
      return Colors.blue; // Transferred to shop
    }

    // If not transferred, check quantity
    if (product.quantity > 0) {
      return Colors.green; // In stock
    }

    return Colors.red; // Out of stock
  }
}
