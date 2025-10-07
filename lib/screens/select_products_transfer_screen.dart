import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class SelectProductsTransferScreen extends StatefulWidget {
  const SelectProductsTransferScreen({super.key});

  @override
  State<SelectProductsTransferScreen> createState() => _SelectProductsTransferScreenState();
}

class _SelectProductsTransferScreenState extends State<SelectProductsTransferScreen> {
  late ProductProvider _productProvider;
  List<Product> _availableProducts = [];
  List<int> _selectedProductIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _productProvider = Provider.of<ProductProvider>(context, listen: false);
    _loadAvailableProducts();
  }

  Future<void> _loadAvailableProducts() async {
    setState(() => _isLoading = true);
    try {
      await _productProvider.fetchProducts();
      setState(() {
        _availableProducts = _productProvider.products.where((product) => product.transferredTo == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
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
        title: 'Select Products to Transfer',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableProducts,
          ),
        ],
        fallbackRoute: '/processor-home',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableProducts.isEmpty
              ? _buildEmptyState()
              : _buildProductsList(),
      floatingActionButton: _selectedProductIds.isNotEmpty
          ? Builder(
              builder: (context) {
                debugPrint('Building FAB, selected ids: $_selectedProductIds');
                return FloatingActionButton(
                  heroTag: null,
                  onPressed: _proceedToSelectShop,
                  backgroundColor: AppTheme.accentOrange,
                  child: const Icon(Icons.arrow_forward),
                );
              },
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
            'No products available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some products first before transferring them',
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
    debugPrint('Building products list, selected ids: $_selectedProductIds, offstage: ${_selectedProductIds.isEmpty}');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Select products to transfer to shop',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _availableProducts.length,
            itemBuilder: (context, index) {
              final product = _availableProducts[index];
              debugPrint('Building product ${product.name}, id: ${product.id}, weight: ${product.weight}, weightUnit: ${product.weightUnit}');
              final isSelected = product.id != null && _selectedProductIds.contains(product.id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          } catch (e) {
                            debugPrint('Error building product subtitle: $e, product: ${product.name}');
                            return Text(
                              '${product.productType} • Error • Batch: ${product.batchNumber}',
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                        },
                      ),
                      Text(
                        'Created: ${product.createdAt.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    debugPrint('Product selection changed: ${product.name}, id: ${product.id}, value: $value');
                    debugPrint('Current selected ids before: $_selectedProductIds');
                    setState(() {
                      if (value == true) {
                        if (product.id != null && !_selectedProductIds.contains(product.id)) {
                          _selectedProductIds.add(product.id!);
                        }
                      } else {
                        if (product.id != null) {
                          _selectedProductIds.remove(product.id);
                        }
                      }
                    });
                    debugPrint('Current selected ids after: $_selectedProductIds');
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
          child: _selectedProductIds.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedProductIds.length} product(s) selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _proceedToSelectShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Next: Select Shop'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _proceedToSelectShop() {
    if (_selectedProductIds.isEmpty) return;

    // Get selected products based on ids
    final selectedProducts = _availableProducts.where((p) => p.id != null && _selectedProductIds.contains(p.id)).toList();

    // Pass selected products to the next screen
    context.push('/select-shop-transfer', extra: selectedProducts);
  }
}







