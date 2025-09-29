import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_category_provider.dart';
import '../models/product_category.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';

class ProductCategoryScreen extends StatefulWidget {
  const ProductCategoryScreen({super.key});

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  ProductCategory? _editingCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductCategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Product Categories',
        fallbackRoute: '/processor-home',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ProductCategoryProvider>().fetchCategories(),
          ),
        ],
      ),
      body: Consumer<ProductCategoryProvider>(
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
                    onPressed: () => provider.fetchCategories(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchCategories(),
            child: ListView.builder(
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                 final category = provider.categories[index];
                 return Card(
                   margin: const EdgeInsets.symmetric(
                     horizontal: 16,
                     vertical: 8,
                   ),
                   child: ListTile(
                     title: Text(category.name),
                     subtitle: category.description != null
                         ? Text(category.description!)
                         : null,
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: const Icon(Icons.edit, color: Colors.blue),
                           onPressed: () => _showEditCategoryDialog(category),
                           tooltip: 'Edit category',
                         ),
                         IconButton(
                           icon: const Icon(Icons.delete, color: Colors.red),
                           onPressed: () => _showDeleteConfirmationDialog(category),
                           tooltip: 'Delete category',
                         ),
                       ],
                     ),
                   ),
                 );
               },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog() {
    _editingCategory = null;
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addCategory, child: const Text('Add')),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(ProductCategory category) {
    _editingCategory = category;
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _updateCategory, child: const Text('Update')),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCategory(category),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    final category = ProductCategory(
      name: name,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    context.read<ProductCategoryProvider>().addCategory(category);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category added successfully')),
    );
  }

  void _updateCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    if (_editingCategory == null) return;

    final updatedCategory = ProductCategory(
      id: _editingCategory!.id,
      name: name,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      createdAt: _editingCategory!.createdAt,
    );

    context.read<ProductCategoryProvider>().updateCategory(updatedCategory);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category updated successfully')),
    );
  }

  void _deleteCategory(ProductCategory category) {
    context.read<ProductCategoryProvider>().deleteCategory(category.id!);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category deleted successfully')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
