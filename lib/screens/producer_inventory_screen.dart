import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../widgets/enhanced_back_button.dart';
import '../widgets/loading_indicator.dart';

class ProducerInventoryScreen extends StatefulWidget {
  const ProducerInventoryScreen({super.key});

  @override
  State<ProducerInventoryScreen> createState() => _ProducerInventoryScreenState();
}

class _ProducerInventoryScreenState extends State<ProducerInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'ready', 'not_ready'
  List<Product> _inventoryProducts = [];
  List<int> _selectedProductIds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productService = ProductService();
      final products = await productService.getProducts();

      // Filter to show only products not yet transferred
      setState(() {
        _inventoryProducts = products.where((product) => product.transferredTo == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Producer Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh inventory',
          ),
        ],
        fallbackRoute: '/processor-home',
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? _buildErrorState()
              : _inventoryProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildInventoryContent(),
      floatingActionButton: _selectedProductIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _initiateBulkTransfer,
              backgroundColor: AppTheme.accentOrange,
              icon: const Icon(Icons.send),
              label: Text('Transfer ${_selectedProductIds.length} items'),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInventory,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No products in inventory',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create products first to see them in your inventory',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/create-product'),
            icon: const Icon(Icons.add),
            label: const Text('Create Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryContent() {
    final filteredProducts = _filterProducts();

    return Column(
      children: [
        _buildSearchAndFilter(),
        _buildStatsBar(),
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildNoResultsState()
              : _buildProductsList(filteredProducts),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Card(
      margin: EdgeInsets.all(Responsive.getPadding(context)),
      child: Padding(
        padding: EdgeInsets.all(Responsive.getPadding(context)),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('All')),
                      ButtonSegment(value: 'ready', label: Text('Ready')),
                      ButtonSegment(value: 'not_ready', label: Text('Not Ready')),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() => _selectedFilter = selection.first);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalProducts = _inventoryProducts.length;
    final readyProducts = _inventoryProducts.where((p) => _isProductReady(p)).length;
    final totalValue = _inventoryProducts.fold<double>(0.0, (sum, p) => sum + (p.price * p.quantity));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context), vertical: 8),
      color: AppTheme.backgroundGray,
      child: Row(
        children: [
          _buildStatItem('Total Products', totalProducts.toString(), Icons.inventory),
          const SizedBox(width: 16),
          _buildStatItem('Ready for Transfer', readyProducts.toString(), Icons.check_circle),
          const SizedBox(width: 16),
          _buildStatItem('Total Value', '\$${totalValue.toStringAsFixed(2)}', Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No products match your search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isSelected = product.id != null && _selectedProductIds.contains(product.id);
        final isReady = _isProductReady(product);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context), vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true && product.id != null) {
                    _selectedProductIds.add(product.id!);
                  } else if (product.id != null) {
                    _selectedProductIds.remove(product.id);
                  }
                });
              },
              activeColor: AppTheme.accentOrange,
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.productType} • ${product.weight ?? 'N/A'} ${product.weightUnit} • Batch: ${product.batchNumber}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Quantity: ${product.quantity} • Price: \$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Created: ${product.createdAt.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isReady)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else
                  const Icon(Icons.pending, color: Colors.orange, size: 20),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, product),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: ListTile(
                        leading: Icon(Icons.info),
                        title: Text('View Details'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit_quantity',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Quantity'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: isReady ? 'mark_not_ready' : 'mark_ready',
                      child: ListTile(
                        leading: Icon(isReady ? Icons.cancel : Icons.check),
                        title: Text(isReady ? 'Mark Not Ready' : 'Mark Ready'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _showProductDetails(product),
          ),
        );
      },
    );
  }

  List<Product> _filterProducts() {
    return _inventoryProducts.where((product) {
      // Search filter
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.batchNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.productType.toLowerCase().contains(_searchController.text.toLowerCase());

      // Status filter
      final matchesFilter = switch (_selectedFilter) {
        'ready' => _isProductReady(product),
        'not_ready' => !_isProductReady(product),
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool _isProductReady(Product product) {
    // For now, consider all products as ready. In a real implementation,
    // this could be a field in the Product model or stored separately
    return true;
  }

  void _handleMenuAction(String action, Product product) {
    switch (action) {
      case 'details':
        _showProductDetails(product);
        break;
      case 'edit_quantity':
        _showEditQuantityDialog(product);
        break;
      case 'mark_ready':
        // Mark as ready - in real implementation, update a flag
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} marked as ready for transfer')),
        );
        break;
      case 'mark_not_ready':
        // Mark as not ready
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} marked as not ready for transfer')),
        );
        break;
    }
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Product Type', product.productType),
              _buildDetailRow('Batch Number', product.batchNumber),
              _buildDetailRow('Quantity', product.quantity.toString()),
              _buildDetailRow('Weight', '${product.weight ?? 'N/A'} ${product.weightUnit}'),
              _buildDetailRow('Price', '\$${product.price.toStringAsFixed(2)}'),
              _buildDetailRow('Description', product.description),
              _buildDetailRow('Manufacturer', product.manufacturer),
              _buildDetailRow('Created', product.createdAt.toLocal().toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: product.quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(
            labelText: 'New Quantity',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = double.tryParse(quantityController.text);
              if (newQuantity != null && newQuantity > 0) {
                try {
                  // Create updated product with new quantity
                  final updatedProduct = Product(
                    id: product.id,
                    processingUnit: product.processingUnit,
                    animal: product.animal,
                    productType: product.productType,
                    quantity: newQuantity,
                    createdAt: product.createdAt,
                    name: product.name,
                    batchNumber: product.batchNumber,
                    weight: product.weight,
                    weightUnit: product.weightUnit,
                    price: product.price,
                    description: product.description,
                    manufacturer: product.manufacturer,
                    category: product.category,
                    qrCode: product.qrCode,
                    timeline: product.timeline,
                    transferredTo: product.transferredTo,
                    transferredAt: product.transferredAt,
                    transferredToUsername: product.transferredToUsername,
                    receivedBy: product.receivedBy,
                    receivedAt: product.receivedAt,
                    receivedByUsername: product.receivedByUsername,
                  );

                  await context.read<ProductProvider>().updateProduct(updatedProduct);

                  Navigator.of(context).pop();
                  _loadInventory(); // Refresh the list

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quantity updated successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update quantity: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _initiateBulkTransfer() {
    if (_selectedProductIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Transfer'),
        content: Text(
          'Are you sure you want to transfer ${_selectedProductIds.length} selected product(s) to a shop? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to shop selection with selected products
              final selectedProducts = _inventoryProducts
                  .where((p) => p.id != null && _selectedProductIds.contains(p.id))
                  .toList();
              context.push('/select-shop-transfer', extra: selectedProducts);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed to Transfer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}