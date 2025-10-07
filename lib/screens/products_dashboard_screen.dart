import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';
import '../services/bluetooth_printing_service.dart';
import '../utils/responsive.dart';
import 'create_product_screen.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  bool _isSelectionMode = false;
  final Set<int> _selectedProducts = {};
  bool _isInventoryMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = GoRouterState.of(context).uri.toString();
      _isInventoryMode = currentRoute.contains('/inventory');
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: _isSelectionMode
            ? 'Select Products (${_selectedProducts.length})'
            : (_isInventoryMode ? 'Inventory' : 'Products Dashboard'),
        onBackPressed: () => context.go(_isInventoryMode ? '/shop-home' : '/processor-home'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _selectedProducts.isNotEmpty ? _batchPrintQRCodes : null,
              tooltip: 'Batch print QR codes',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedProducts.clear();
              }),
              tooltip: 'Cancel selection',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: 'Select products',
            ),
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
        ],
      ),
      floatingActionButton: _isInventoryMode ? null : FloatingActionButton(
        heroTag: null,
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
      margin: EdgeInsets.all(Responsive.getPadding(context)),
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
      // In inventory mode, only show received products
      if (_isInventoryMode && product.receivedBy == null) {
        return false;
      }

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
          final status = _getProductStatus(product);
          final isSelected = _selectedProducts.contains(product.id);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
            child: ListTile(
              leading: _isSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleProductSelection(product.id!),
                    )
                  : null,
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${product.id ?? 'N/A'}'),
                  Text('Batch: ${product.batchNumber}'),
                  Text('Weight: ${product.weight} ${product.weightUnit}'),
                  Text('Created: ${product.createdAt.toString().split(' ')[0]}'),
                  Text('Status: $status'),
                  if (_isInventoryMode) ...[
                    Text('Price: \$${product.price}'),
                    Text('Received: ${product.receivedAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}'),
                  ],
                ],
              ),
              trailing: _isSelectionMode
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: Colors.green),
                          onPressed: () => _showQROptions(product),
                          tooltip: 'QR Code options',
                        ),
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
              onTap: _isSelectionMode
                  ? () => _toggleProductSelection(product.id!)
                  : () => _showProductDetails(product),
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
        padding: EdgeInsets.all(Responsive.getPadding(context)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.getGridCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final status = _getProductStatus(product);
          final isSelected = _selectedProducts.contains(product.id);

          return Card(
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleProductSelection(product.id!)
                  : () => _showProductDetails(product),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSelectionMode)
                          Align(
                            alignment: Alignment.topRight,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (value) => _toggleProductSelection(product.id!),
                            ),
                          ),
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('ID: ${product.id ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                        Text('Batch: ${product.batchNumber}', style: const TextStyle(fontSize: 12)),
                        Text('Weight: ${product.weight} ${product.weightUnit}', style: const TextStyle(fontSize: 12)),
                        Text('Created: ${product.createdAt.toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
                        Text('Status: $status', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        if (_isInventoryMode) ...[
                          Text('Price: \$${product.price}', style: const TextStyle(fontSize: 12)),
                          Text('Received: ${product.receivedAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                        ],
                        const Spacer(),
                        if (!_isSelectionMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code, size: 18, color: Colors.green),
                                onPressed: () => _showQROptions(product),
                                tooltip: 'QR Code options',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                onPressed: () => _showEditDialog(product),
                                tooltip: 'Edit product',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () => _showDeleteDialog(product),
                                tooltip: 'Delete product',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
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

  String _getProductStatus(Product product) {
    // For now, determine status based on QR code presence and timeline
    if (product.qrCode != null && product.qrCode!.isNotEmpty) {
      return 'Active';
    }
    if (product.timeline.isNotEmpty) {
      return 'Processed';
    }
    return 'Created';
  }

  void _showQROptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Code Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Regenerate QR Code'),
              onTap: () {
                Navigator.of(context).pop();
                _regenerateQRCode(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print QR Code'),
              onTap: () {
                Navigator.of(context).pop();
                _printQRCode(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Export QR Code'),
              onTap: () {
                Navigator.of(context).pop();
                _exportQRCode(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _regenerateQRCode(Product product) async {
    // For now, show a dialog to confirm regeneration
    // In a real implementation, this would call an API endpoint
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate QR Code'),
        content: Text('Are you sure you want to regenerate the QR code for "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Call API to regenerate QR code
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR code regeneration not yet implemented')),
              );
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _printQRCode(Product product) async {
    await _showPrinterSelectionDialog(product: product);
  }

  Future<void> _showPrinterSelectionDialog({Product? product, List<Product>? products}) async {
    final printingService = BluetoothPrintingService();

    // Request permissions
    final hasPermissions = await printingService.requestPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required for printing')),
      );
      return;
    }

    try {
      // Scan for printers
      final printers = await printingService.scanPrinters();

      if (!mounted) return;

      if (printers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Bluetooth printers found')),
        );
        return;
      }

      // Show printer selection dialog
      final selectedPrinter = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final printer = printers[index];
                return ListTile(
                  title: Text(printer.platformName ?? 'Unknown Printer'),
                  onTap: () => Navigator.of(context).pop(printer),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedPrinter == null) return;

      // Connect to printer with retry logic
      final connected = await printingService.connectToPrinter(selectedPrinter, maxRetries: 3);
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to printer after multiple attempts')),
        );
        return;
      }

      // Print
      if (product != null) {
        final qrData = product.qrCode ?? 'https://meat-trace.com/product/${product.id}';
        await printingService.printQRCode(qrData, product.name, product.batchNumber);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printed QR code for ${product.name}')),
        );
      } else if (products != null) {
        for (final prod in products) {
          final qrData = prod.qrCode ?? 'https://meat-trace.com/product/${prod.id}';
          await printingService.printQRCode(qrData, prod.name, prod.batchNumber);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printed ${products.length} QR codes')),
        );
      }

      // Disconnect
      await printingService.disconnect();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printing failed: $e')),
      );
    }
  }

  void _exportQRCode(Product product) async {
    try {
      final qrData = product.qrCode ?? 'https://meat-trace.com/product/${product.id}';

      // Generate QR image
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 300.0;
      qrPainter.paint(canvas, const Size(size, size));

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_${product.id}.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'QR Code for ${product.name} (Batch: ${product.batchNumber})',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code exported successfully')),
        );
      } else {
        throw Exception('Failed to generate QR image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export QR code: $e')),
      );
    }
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts.add(productId);
      }
    });
  }

  void _batchPrintQRCodes() async {
    if (_selectedProducts.isEmpty) return;

    final provider = context.read<ProductProvider>();
    final selectedProducts = provider.products
        .where((product) => _selectedProducts.contains(product.id))
        .toList();

    await _showPrinterSelectionDialog(products: selectedProducts);

    setState(() {
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}







