import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import '../widgets/enhanced_back_button.dart';
import '../widgets/loading_indicator.dart';

class ProcessorQrCodesScreen extends StatefulWidget {
  const ProcessorQrCodesScreen({super.key});

  @override
  State<ProcessorQrCodesScreen> createState() => _ProcessorQrCodesScreenState();
}

class _ProcessorQrCodesScreenState extends State<ProcessorQrCodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.user?.id;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final productService = ProductService();
      final allProducts = await productService.getProducts();

      // Filter products created by this processor
      final processorProducts = allProducts.where((product) {
        // Assuming products have a processingUnit field that matches the user ID
        // or we can check if the product was created by this user
        return product.processingUnit == currentUserId.toString() ||
               product.manufacturer?.contains(currentUserId.toString()) == true;
      }).toList();

      if (mounted) {
        setState(() {
          _products = processorProducts;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Generated QR Codes',
        fallbackRoute: '/processor-home',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh products',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? _buildErrorState()
              : _products.isEmpty
                  ? _buildEmptyState()
                  : _buildProductsList(),
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
            onPressed: _loadProducts,
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
            Icons.qr_code,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create products first to view their QR codes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/create-product'),
            icon: const Icon(Icons.add),
            label: const Text('Create Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _filterProducts();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(Responsive.getPadding(context)),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search products',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),

        // Products count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context)),
          child: Text(
            '${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''} with QR codes',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        // Products list
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildNoResultsState()
              : ListView.builder(
                  padding: EdgeInsets.all(Responsive.getPadding(context)),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showProductDetails(product),
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: 'Product details',
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Product info
                            Text(
                              'Batch: ${product.batchNumber}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${product.quantity} units • ${product.weight ?? 'N/A'} ${product.weightUnit}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // QR Code
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    QrImageView(
                                      data: 'product:${product.id}:${product.batchNumber}',
                                      version: QrVersions.auto,
                                      size: 150.0,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Scan for product details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _shareQrCode(product),
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _printQrCode(product),
                                    icon: const Icon(Icons.print),
                                    label: const Text('Print'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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

  List<Product> _filterProducts() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _products;
    }

    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
             product.batchNumber.toLowerCase().contains(query) ||
             product.productType.toLowerCase().contains(query);
    }).toList();
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
              _buildDetailRow('Manufacturer', product.manufacturer ?? 'N/A'),
              _buildDetailRow('Created', product.createdAt.toLocal().toString().split('.')[0]),
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

  void _shareQrCode(Product product) {
    // TODO: Implement QR code sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share functionality for ${product.name} coming soon')),
    );
  }

  void _printQrCode(Product product) {
    // TODO: Implement QR code printing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Print functionality for ${product.name} coming soon')),
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