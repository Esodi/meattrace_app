import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class ReceiveProductsScreen extends StatefulWidget {
  const ReceiveProductsScreen({super.key});

  @override
  State<ReceiveProductsScreen> createState() => _ReceiveProductsScreenState();
}

class _ReceiveProductsScreenState extends State<ReceiveProductsScreen> {
  late ProductProvider _productProvider;
  List<Product> _transferredProducts = [];
  List<Product> _selectedProducts = [];
  bool _isReceiving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _productProvider = Provider.of<ProductProvider>(context, listen: false);
    _loadTransferredProducts();
  }

  Future<void> _loadTransferredProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productProvider.fetchTransferredProducts();
      if (mounted) {
        setState(() {
          _transferredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transferred products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Receive Products',
        fallbackRoute: '/shop-home',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransferredProducts,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransferredProducts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transferredProducts.isEmpty
                ? _buildEmptyState()
                : _buildProductsList(),
      ),
      floatingActionButton: _selectedProducts.isNotEmpty
          ? FloatingActionButton(
              onPressed: _isReceiving ? null : _receiveSelectedProducts,
              backgroundColor: AppTheme.accentOrange,
              child: _isReceiving
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.check),
            )
          : null,
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
            'No transferred products',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Products transferred by processors will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    debugPrint('Building products list, selected products: ${_selectedProducts.length}');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select products to receive from processors',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transferredProducts.length,
            itemBuilder: (context, index) {
              final product = _transferredProducts[index];
              final isSelected = _selectedProducts.contains(product);
              debugPrint('Building product ${product.name}, selected: $isSelected');

              return Card(
                key: ValueKey(product.id ?? index),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          try {
                            final weightText = product.weight != null ? '${product.weight}${product.weightUnit}' : 'N/A';
                            return Text(
                              '${product.productType} • $weightText • Batch: ${product.batchNumber}',
                              style: const TextStyle(fontSize: 12),
                            );
                          } catch (e) {
                            debugPrint('Error building product subtitle: $e, product: ${product.name}');
                            return Text(
                              '${product.productType} • Error • Batch: ${product.batchNumber}',
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            );
                          }
                        },
                      ),
                      Text(
                        'Transferred: ${product.transferredAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        'From: ${product.processingUnit}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    debugPrint('Product selection changed: ${product.name}, value: $value, current selected: ${_selectedProducts.length}');
                    setState(() {
                      if (value == true) {
                        _selectedProducts.add(product);
                      } else {
                        _selectedProducts.remove(product);
                      }
                    });
                    debugPrint('After selection, selected products: ${_selectedProducts.length}');
                  },
                  activeColor: AppTheme.accentOrange,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundGray,
          child: _selectedProducts.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedProducts.length} product(s) selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isReceiving ? null : _receiveSelectedProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isReceiving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Receive'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _receiveSelectedProducts() async {
    if (_selectedProducts.isEmpty) return;

    setState(() => _isReceiving = true);

    try {
      final productIds = _selectedProducts.map((product) => product.id!).toList();

      final response = await _productProvider.receiveProducts(productIds);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Successfully received ${_selectedProducts.length} product(s)'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Clear selection and reload
      setState(() {
        _selectedProducts.clear();
      });
      _loadTransferredProducts();

      // Refresh inventory to show updated stock levels
      if (context.mounted) {
        final authProvider = context.read<AuthProvider>();
        context.read<InventoryProvider>().fetchInventory(shopId: authProvider.user?.id);
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to receive products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isReceiving = false);
    }
  }
}