import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';
import 'create_product_screen.dart';

class ProductsDashboardScreen extends StatefulWidget {
  const ProductsDashboardScreen({super.key});

  @override
  State<ProductsDashboardScreen> createState() => _ProductsDashboardScreenState();
}

class _ProductsDashboardScreenState extends State<ProductsDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedAnimal;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Products Dashboard',
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductProvider>().fetchProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateProductScreen()),
        ),
        tooltip: 'Create new product',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const LoadingIndicator();
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${provider.error}'),
                        ElevatedButton(
                          onPressed: () => provider.fetchProducts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredProducts = _filterProducts(provider.products);

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return _isGridView
                    ? _buildGridView(filteredProducts)
                    : _buildListView(filteredProducts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      final categories = provider.products
                          .map((p) => p.category)
                          .where((c) => c != null)
                          .toSet()
                          .toList();

                      return DropdownButtonFormField<String?>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map((categoryId) {
                            // For now, just show ID, could be enhanced to show name
                            return DropdownMenuItem(
                              value: categoryId.toString(),
                              child: Text('Category $categoryId'),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => _selectedCategory = value),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      final animals = provider.products
                          .map((p) => p.animal)
                          .toSet()
                          .toList();

                      return DropdownButtonFormField<String?>(
                        value: _selectedAnimal,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Animal',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Animals'),
                          ),
                          ...animals.map((animalId) {
                            return DropdownMenuItem(
                              value: animalId.toString(),
                              child: Text('Animal $animalId'),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => _selectedAnimal = value),
                      );
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

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.batchNumber.toLowerCase().contains(_searchController.text.toLowerCase());

      final matchesCategory = _selectedCategory == null ||
          product.category?.toString() == _selectedCategory;

      final matchesAnimal = _selectedAnimal == null ||
          product.animal.toString() == _selectedAnimal;

      return matchesSearch && matchesCategory && matchesAnimal;
    }).toList();
  }

  Widget _buildListView(List<Product> products) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProductProvider>().fetchProducts(),
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batch: ${product.batchNumber}'),
                  Text('Weight: ${product.weight} ${product.weightUnit}'),
                  Text('Created: ${product.createdAt.toString().split(' ')[0]}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(product),
                    tooltip: 'Edit product',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(product),
                    tooltip: 'Delete product',
                  ),
                ],
              ),
              onTap: () => _showProductDetails(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView(List<Product> products) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProductProvider>().fetchProducts(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text('Batch: ${product.batchNumber}'),
                  Text('Weight: ${product.weight} ${product.weightUnit}'),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        onPressed: () => _showEditDialog(product),
                        tooltip: 'Edit product',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _showDeleteDialog(product),
                        tooltip: 'Delete product',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
              Text('Batch Number: ${product.batchNumber}'),
              Text('Weight: ${product.weight} ${product.weightUnit}'),
              Text('Animal ID: ${product.animal}'),
              if (product.category != null) Text('Category ID: ${product.category}'),
              Text('Created: ${product.createdAt}'),
              Text('Description: ${product.description}'),
              Text('Manufacturer: ${product.manufacturer}'),
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

  void _showEditDialog(Product product) {
    // For now, just show details. Could be enhanced to allow editing
    _showProductDetails(product);
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteProduct(product),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(Product product) async {
    final provider = context.read<ProductProvider>();
    final success = await provider.deleteProduct(product.id!);

    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete product')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}