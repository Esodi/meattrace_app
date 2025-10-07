import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'low_stock', 'healthy'
  bool _showStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<InventoryProvider>().fetchInventory(shopId: authProvider.user?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Inventory Management',
        fallbackRoute: '/shop-home',
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.list : Icons.analytics),
            onPressed: () => setState(() => _showStats = !_showStats),
            tooltip: _showStats ? 'Hide stats' : 'Show stats',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              context.read<InventoryProvider>().fetchInventory(shopId: authProvider.user?.id);
            },
            tooltip: 'Refresh inventory',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showStats) _buildStatsCards(),
          _buildFilters(),
          Expanded(
            child: Consumer<InventoryProvider>(
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
                          onPressed: () {
                            final authProvider = context.read<AuthProvider>();
                            provider.fetchInventory(shopId: authProvider.user?.id);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredInventory = _filterInventory(provider.inventory);

                if (filteredInventory.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildInventoryList(filteredInventory);
              },
            ),
          ),
        ],
      ),
      // Inventory items are automatically added when products are received
      // No manual addition allowed as per requirements
    );
  }

  Widget _buildStatsCards() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Items',
                      provider.totalItems.toString(),
                      Icons.inventory,
                      AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      provider.lowStockCount.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Total Value',
                      '\$${provider.totalValue.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.lowStockCount > 0) _buildLowStockAlert(provider),
          ],
        );
      },
    );
  }

  Widget _buildLowStockAlert(InventoryProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.lowStockCount} item(s) are below minimum stock level',
              style: TextStyle(color: Colors.orange.shade700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: provider.lowStockItems.take(3).map((item) {
                return Chip(
                  label: Text(
                    item.productDetails?.name ?? 'Unknown',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: TextStyle(color: Colors.orange.shade900),
                );
              }).toList(),
            ),
            if (provider.lowStockCount > 3)
              Text(
                '...and ${provider.lowStockCount - 3} more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
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
                      ButtonSegment(value: 'low_stock', label: Text('Low Stock')),
                      ButtonSegment(value: 'healthy', label: Text('Healthy')),
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
            'No inventory items found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Receive products from processors to automatically add them to inventory',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/receive-products'),
            icon: const Icon(Icons.inventory_2),
            label: const Text('Receive Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<Inventory> inventory) {
    return ListView.builder(
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context), vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item.isLowStock ? Colors.orange : Colors.green,
              child: Icon(
                item.isLowStock ? Icons.warning : Icons.check,
                color: Colors.white,
              ),
            ),
            title: Text(
              item.productDetails?.name ?? 'Product ${item.product}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch: ${item.productDetails?.batchNumber ?? 'N/A'}'),
                Text(
                  'Quantity: ${item.quantity} | Min: ${item.minStockLevel}',
                  style: TextStyle(
                    color: item.isLowStock ? Colors.orange : AppTheme.textSecondary,
                    fontWeight: item.isLowStock ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                Text(
                  'Price: \$${item.productDetails?.price.toStringAsFixed(2) ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getPriceColor(item),
                  ),
                ),
                Text(
                  'Updated: ${item.lastUpdated.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, item),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'adjust',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Adjust Stock'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Edit Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: () => _showInventoryDetails(item),
          ),
        );
      },
    );
  }

  List<Inventory> _filterInventory(List<Inventory> inventory) {
    return inventory.where((item) {
      // Search filter
      final matchesSearch = _searchController.text.isEmpty ||
          (item.productDetails?.name.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
          (item.productDetails?.batchNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

      // Status filter
      final matchesFilter = switch (_selectedFilter) {
        'low_stock' => item.isLowStock,
        'healthy' => !item.isLowStock,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showAddInventoryDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddInventoryDialog(),
    );
  }

  void _handleMenuAction(String action, Inventory item) {
    switch (action) {
      case 'adjust':
        _showAdjustStockDialog(item);
        break;
      case 'edit':
        _showEditInventoryDialog(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showAdjustStockDialog(Inventory item) {
    showDialog(
      context: context,
      builder: (context) => AdjustStockDialog(inventory: item),
    );
  }

  void _showEditInventoryDialog(Inventory item) {
    showDialog(
      context: context,
      builder: (context) => EditInventoryDialog(inventory: item),
    );
  }

  void _showDeleteConfirmation(Inventory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text('Are you sure you want to delete "${item.productDetails?.name ?? 'this item'}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context.read<InventoryProvider>().deleteInventoryItem(item.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventory item deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInventoryDetails(Inventory item) {
    showDialog(
      context: context,
      builder: (context) => InventoryDetailsDialog(inventory: item),
    );
  }

  Color _getPriceColor(Inventory item) {
    if (item.quantity == 0) {
      return Colors.red; // Out of stock
    } else if (item.isLowStock) {
      return Colors.orange; // Low stock / discounted
    } else {
      return AppTheme.primaryGreen; // Normal stock
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Dialog widgets
class AddInventoryDialog extends StatefulWidget {
  const AddInventoryDialog({super.key});

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedProductId;
  double _quantity = 0.0;
  double _minStockLevel = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  final receivedProducts = provider.products
                      .where((p) => p.receivedBy != null)
                      .toList();

                  return DropdownButtonFormField<int>(
                    value: _selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                    items: receivedProducts.map((product) {
                        return DropdownMenuItem(
                          value: product.id,
                          child: Text('${product.name} (Batch: ${product.batchNumber})'),
                        );
                      }).toList(),
                    validator: (value) => value == null ? 'Please select a product' : null,
                    onChanged: (value) => setState(() => _selectedProductId = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _quantity.toString(),
                decoration: const InputDecoration(
                  labelText: 'Initial Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter quantity';
                  final qty = double.tryParse(value);
                  if (qty == null || qty < 0) return 'Please enter valid quantity';
                  return null;
                },
                onSaved: (value) => _quantity = double.parse(value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _minStockLevel.toString(),
                decoration: const InputDecoration(
                  labelText: 'Minimum Stock Level',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter minimum stock level';
                  final min = double.tryParse(value);
                  if (min == null || min < 0) return 'Please enter valid minimum stock level';
                  return null;
                },
                onSaved: (value) => _minStockLevel = double.parse(value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_selectedProductId == null) return;

      final inventory = Inventory(
        shop: 1, // Current user's shop ID - should be dynamic
        product: _selectedProductId!,
        quantity: _quantity,
        minStockLevel: _minStockLevel,
        lastUpdated: DateTime.now(),
      );

      final success = await context.read<InventoryProvider>().createInventoryItem(inventory);

      if (success != null && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory item added successfully')),
        );
      }
    }
  }
}

class AdjustStockDialog extends StatefulWidget {
  final Inventory inventory;

  const AdjustStockDialog({super.key, required this.inventory});

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  double _adjustment = 0.0;
  String _reason = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Stock'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current quantity: ${widget.inventory.quantity}'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Adjustment (+/-)',
                  hintText: 'Enter positive to add, negative to subtract',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter adjustment';
                  final adj = double.tryParse(value);
                  if (adj == null) return 'Please enter valid number';
                  final newQty = widget.inventory.quantity + adj;
                  if (newQty < 0) return 'Adjustment would result in negative quantity';
                  return null;
                },
                onSaved: (value) => _adjustment = double.parse(value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Why are you adjusting stock?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a reason' : null,
                onSaved: (value) => _reason = value ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Adjust'),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final success = await context.read<InventoryProvider>().adjustStock(
        widget.inventory.id!,
        _adjustment,
        _reason,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock adjusted by $_adjustment')),
        );
      }
    }
  }
}

class EditInventoryDialog extends StatefulWidget {
  final Inventory inventory;

  const EditInventoryDialog({super.key, required this.inventory});

  @override
  State<EditInventoryDialog> createState() => _EditInventoryDialogState();
}

class _EditInventoryDialogState extends State<EditInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late double _price;

  @override
  void initState() {
    super.initState();
    _price = widget.inventory.productDetails?.price ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product Price'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Product: ${widget.inventory.productDetails?.name ?? 'Unknown'}'),
              Text('Batch: ${widget.inventory.productDetails?.batchNumber ?? 'N/A'}'),
              Text('Current quantity: ${widget.inventory.quantity}'),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(
                  labelText: 'Price per Unit',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter price';
                  final price = double.tryParse(value);
                  if (price == null || price < 0) return 'Please enter valid price';
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (widget.inventory.productDetails == null) return;

      try {
        // Create a Product instance from InventoryProduct data
        final productDetails = widget.inventory.productDetails!;
        final product = Product(
          id: productDetails.id,
          processingUnit: '', // Not available in InventoryProduct, but required
          animal: productDetails.animal ?? 0,
          productType: productDetails.productType,
          quantity: 0, // Not available, but required
          createdAt: productDetails.createdAt,
          name: productDetails.name,
          batchNumber: productDetails.batchNumber,
          weight: productDetails.weight,
          weightUnit: productDetails.weightUnit,
          price: _price, // Updated price
          description: productDetails.description ?? '',
          manufacturer: productDetails.manufacturer ?? '',
          category: productDetails.category,
          qrCode: productDetails.qrCode,
          timeline: [], // Not available
        );

        // Update the product price
        await context.read<ProductProvider>().updateProduct(product);

        // Refresh inventory to show updated price
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          await context.read<InventoryProvider>().fetchInventory(shopId: authProvider.user?.id);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product price updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update price: $e')),
          );
        }
      }
    }
  }
}

class InventoryDetailsDialog extends StatelessWidget {
  final Inventory inventory;

  const InventoryDetailsDialog({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(inventory.productDetails?.name ?? 'Inventory Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Product ID', inventory.product.toString()),
            _buildDetailRow('Batch Number', inventory.productDetails?.batchNumber ?? 'N/A'),
            _buildDetailRow('Current Quantity', inventory.quantity.toString()),
            _buildDetailRow('Minimum Stock Level', inventory.minStockLevel.toString()),
            _buildDetailRow('Status', inventory.isLowStock ? 'Low Stock' : 'Healthy'),
            _buildDetailRow('Last Updated', inventory.lastUpdated.toLocal().toString()),
            if (inventory.productDetails != null) ...[
              const SizedBox(height: 16),
              const Text('Product Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('Weight', '${inventory.productDetails!.weight} ${inventory.productDetails!.weightUnit}'),
              _buildDetailRow('Price', '\$${inventory.productDetails!.price}'),
              _buildDetailRow('Type', inventory.productDetails!.productType),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
}







