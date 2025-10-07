import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/order_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../models/inventory.dart';
import '../models/order.dart';
import '../services/bluetooth_printing_service.dart';
import '../widgets/enhanced_back_button.dart';
import '../utils/theme.dart';
import '../widgets/loading_indicator.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'all';
  bool _showCart = false;

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
        title: 'Place Order',
        onBackPressed: () => context.go('/shop-home'),
        actions: [
          IconButton(
            icon: Icon(_showCart ? Icons.list : Icons.shopping_cart),
            onPressed: () => setState(() => _showCart = !_showCart),
            tooltip: _showCart ? 'Show Products' : 'Show Cart',
          ),
        ],
      ),
      body: _showCart ? _buildCartView() : _buildProductSelectionView(),
      floatingActionButton: _showCart ? _buildCheckoutButton() : null,
    );
  }

  Widget _buildProductSelectionView() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: Consumer<InventoryProvider>(
            builder: (context, inventoryProvider, child) {
              if (inventoryProvider.isLoading) {
                return const LoadingIndicator();
              }

              if (inventoryProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${inventoryProvider.error}'),
                      ElevatedButton(
                        onPressed: () {
                          final authProvider = context.read<AuthProvider>();
                          inventoryProvider.fetchInventory(shopId: authProvider.user?.id);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredInventory = _filterInventory(inventoryProvider.inventory);

              if (filteredInventory.isEmpty) {
                return _buildEmptyProductsState();
              }

              return _buildProductGrid(filteredInventory);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
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
                const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Categories')),
                      DropdownMenuItem(value: 'meat', child: Text('Meat')),
                      DropdownMenuItem(value: 'milk', child: Text('Milk')),
                      DropdownMenuItem(value: 'eggs', child: Text('Eggs')),
                    ],
                    onChanged: (value) => setState(() => _selectedCategory = value ?? 'all'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Inventory> inventory) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: inventory.length,
      itemBuilder: (context, index) {
        final item = inventory[index];
        return _buildProductCard(item);
      },
    );
  }

  Widget _buildProductCard(Inventory inventory) {
    final product = inventory.productDetails;
    if (product == null) return const SizedBox.shrink();

    final cartItem = context.watch<OrderProvider>().cartItems.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, inventory: inventory, quantity: 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Batch: ${product.batchNumber}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text(
              'Stock: ${inventory.quantity}',
              style: TextStyle(
                fontSize: 12,
                color: inventory.isLowStock ? Colors.orange : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (cartItem.quantity > 0)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _updateCartQuantity(product.id!, cartItem.quantity - 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text('${cartItem.quantity}'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _updateCartQuantity(product.id!, cartItem.quantity + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: inventory.quantity > 0
                    ? () => _addToCart(product, inventory, 1)
                    : null,
                child: const Text('Add to Cart'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartView() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.cartItems.isEmpty) {
          return _buildEmptyCartState();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = orderProvider.cartItems[index];
                  return _buildCartItem(cartItem);
                },
              ),
            ),
            _buildCartSummary(orderProvider),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(CartItem cartItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Batch: ${cartItem.product.batchNumber}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '\$${cartItem.product.price.toStringAsFixed(2)} each',
                    style: TextStyle(color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _updateCartQuantity(cartItem.product.id!, cartItem.quantity - 1),
                ),
                Text('${cartItem.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _updateCartQuantity(cartItem.product.id!, cartItem.quantity + 1),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFromCart(cartItem.product.id!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(OrderProvider orderProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '\$${orderProvider.cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return FloatingActionButton.extended(
          onPressed: orderProvider.cartItems.isNotEmpty ? _checkout : null,
          icon: const Icon(Icons.payment),
          label: const Text('Checkout'),
        );
      },
    );
  }

  Widget _buildEmptyProductsState() {
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
            'Receive products from processors to start selling',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showCart = false),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  List<Inventory> _filterInventory(List<Inventory> inventory) {
    return inventory.where((item) {
      final product = item.productDetails;
      if (product == null) return false;

      // Search filter
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.batchNumber.toLowerCase().contains(_searchController.text.toLowerCase());

      // Category filter
      final matchesCategory = _selectedCategory == 'all' || product.productType == _selectedCategory;

      return matchesSearch && matchesCategory && item.quantity > 0;
    }).toList();
  }

  void _addToCart(InventoryProduct product, Inventory inventory, double quantity) {
    context.read<OrderProvider>().addToCart(product, inventory, quantity);
  }

  void _updateCartQuantity(int productId, double quantity) {
    context.read<OrderProvider>().updateCartItemQuantity(productId, quantity);
  }

  void _removeFromCart(int productId) {
    context.read<OrderProvider>().removeFromCart(productId);
  }

  Future<void> _checkout() async {
    final orderProvider = context.read<OrderProvider>();
    final authProvider = context.read<AuthProvider>();

    if (orderProvider.cartItems.isEmpty) return;

    // Convert cart items to order items
    final orderItems = orderProvider.convertCartToOrderItems(0); // orderId will be set by backend

    // Create order with items
    final order = Order(
      customer: authProvider.user?.id ?? 1, // Default to current user or guest
      shop: authProvider.user?.id ?? 1, // Shop is the current user
      status: 'confirmed',
      totalAmount: orderProvider.cartTotal,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      items: orderItems,
    );

    final createdOrder = await orderProvider.createOrder(order);
    print('🔍 [PlaceOrderScreen] After createOrder, local order.id: ${order.id}, createdOrder.id: ${createdOrder?.id}');

    if (createdOrder != null && mounted) {
      // Print receipt
      await _printReceipt(createdOrder);

      // Update inventory
      await _updateInventory();

      // Refresh inventory to update UI
      final authProvider = context.read<AuthProvider>();
      await context.read<InventoryProvider>().fetchInventory(shopId: authProvider.user?.id);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order completed successfully!')),
      );

      // Reset form
      _customerNameController.clear();
      _notesController.clear();

      // Go back to product view
      setState(() => _showCart = false);
    } else {
      if (orderProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: ${orderProvider.error}')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout failed: Unknown error')),
        );
      }
    }
  }

  Future<void> _printReceipt(Order order) async {
    try {
      final printingService = BluetoothPrintingService();
      final orderProvider = context.read<OrderProvider>();

      // Debug logs for printer state
      print('🔍 [PlaceOrderScreen] Checking printer state before printing...');
      print('📊 [PlaceOrderScreen] selectedPrinter: ${printingService.selectedPrinter}');
      print('📊 [PlaceOrderScreen] isConnected: ${printingService.isConnected}');
      print('📊 [PlaceOrderScreen] Order ID for printing: ${order.id}');

      // Check if printer is selected
      if (printingService.selectedPrinter == null) {
        print('🔄 [PlaceOrderScreen] No printer selected - showing selection dialog');
        final printerSelected = await _showPrinterSelectionDialog();
        if (!printerSelected || printingService.selectedPrinter == null) {
          print('❌ [PlaceOrderScreen] No printer selected after dialog - cannot print receipt');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No printer selected. Receipt not printed.')),
            );
          }
          return;
        }
      }

      // Print order header
      await printingService.printQRCode(
        'ORDER_${order.id ?? 'unknown'}',
        'Order #${order.id ?? 'unknown'}',
        'Total: \$${order.totalAmount.toStringAsFixed(2)}',
      );

      // Print each product QR code
      for (final cartItem in orderProvider.cartItems) {
        if (cartItem.product.qrCode != null && cartItem.product.qrCode!.isNotEmpty) {
          await printingService.printQRCode(
            cartItem.product.qrCode!,
            cartItem.product.name,
            'Batch: ${cartItem.product.batchNumber} | Qty: ${cartItem.quantity}',
          );
        }
      }

    } catch (e) {
      // Don't fail the order if printing fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order completed, but printing failed: $e')),
        );
      }
    }
  }

  Future<bool> _showPrinterSelectionDialog() async {
    if (!mounted) return false;

    final printingService = BluetoothPrintingService();
    List<BluetoothDevice> availablePrinters = [];
    bool isScanning = false;
    BluetoothDevice? selectedPrinter;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> scanPrinters() async {
              setState(() => isScanning = true);
              try {
                final hasPermissions = await printingService.requestPermissions();
                if (!hasPermissions) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bluetooth permissions are required')),
                    );
                  }
                  return;
                }

                final printers = await printingService.scanPrinters();
                setState(() {
                  availablePrinters = printers;
                  isScanning = false;
                });
              } catch (e) {
                setState(() => isScanning = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to scan printers: $e')),
                  );
                }
              }
            }

            Future<void> connectToPrinter(BluetoothDevice printer) async {
              try {
                final connected = await printingService.connectToPrinter(printer, maxRetries: 3);
                if (connected) {
                  setState(() => selectedPrinter = printer);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connected to ${printer.platformName}')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to connect to printer')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Connection failed: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Select Bluetooth Printer'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (printingService.isConnected)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.bluetooth_connected, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('Connected to ${printingService.selectedPrinter?.platformName ?? 'Printer'}'),
                          ],
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: isScanning ? null : scanPrinters,
                      icon: isScanning ? const CircularProgressIndicator() : const Icon(Icons.search),
                      label: Text(isScanning ? 'Scanning...' : 'Scan for Printers'),
                    ),
                    const SizedBox(height: 16),
                    if (availablePrinters.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availablePrinters.length,
                          itemBuilder: (context, index) {
                            final printer = availablePrinters[index];
                            return ListTile(
                              title: Text(printer.platformName ?? 'Unknown Printer'),
                              trailing: TextButton(
                                onPressed: () => connectToPrinter(printer),
                                child: const Text('Connect'),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Skip Printing'),
                ),
                ElevatedButton(
                  onPressed: printingService.isConnected ? () => Navigator.of(dialogContext).pop(true) : null,
                  child: const Text('Print Receipt'),
                ),
              ],
            );
          },
        );
      },
    ) ?? false;
  }

  Future<void> _updateInventory() async {
    final orderProvider = context.read<OrderProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final authProvider = context.read<AuthProvider>();

    print('🔍 [PlaceOrderScreen] Starting inventory update for ${orderProvider.cartItems.length} cart items');

    // Update local inventory quantities
    for (final cartItem in orderProvider.cartItems) {
      print('🔍 [PlaceOrderScreen] Processing cart item: ${cartItem.product.name}, quantity: ${cartItem.quantity}');

      final inventoryItem = inventoryProvider.inventory.firstWhere(
        (item) => item.product == cartItem.product.id,
        orElse: () => Inventory(
          shop: authProvider.user?.id ?? 1, product: cartItem.product.id!, quantity: cartItem.inventory.quantity, minStockLevel: 0, lastUpdated: DateTime.now()
        ),
      );

      print('🔍 [PlaceOrderScreen] Found inventory item: id=${inventoryItem.id}, product=${inventoryItem.product}, current_quantity=${inventoryItem.quantity}');

      if (inventoryItem.id != null) {
        final newQuantity = inventoryItem.quantity - cartItem.quantity;
        print('🔍 [PlaceOrderScreen] Updating inventory: old_quantity=${inventoryItem.quantity}, cart_quantity=${cartItem.quantity}, new_quantity=$newQuantity');

        final updatedInventory = inventoryItem.copyWith(
          quantity: newQuantity,
          lastUpdated: DateTime.now(),
        );

        final success = await inventoryProvider.updateInventoryItem(updatedInventory);
        print('🔍 [PlaceOrderScreen] Inventory update result: $success');
      } else {
        print('🔍 [PlaceOrderScreen] Inventory item not found in database, creating new one');
        // Create inventory item if it doesn't exist
        final newInventory = Inventory(
          shop: authProvider.user?.id ?? 1,
          product: cartItem.product.id!,
          quantity: cartItem.inventory.quantity - cartItem.quantity,
          minStockLevel: 0,
          lastUpdated: DateTime.now(),
        );

        final createdItem = await inventoryProvider.createInventoryItem(newInventory);
        if (createdItem != null) {
          print('🔍 [PlaceOrderScreen] Created new inventory item with id: ${createdItem.id}');
        } else {
          print('🔍 [PlaceOrderScreen] Failed to create inventory item');
        }
      }
    }

    print('🔍 [PlaceOrderScreen] Inventory update completed');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}







