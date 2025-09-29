import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../models/shop_receipt.dart';
import '../providers/product_provider.dart';
import '../services/shop_receipt_service.dart';
import '../widgets/loading_indicator.dart';

class ReceiveProductScreen extends StatefulWidget {
  const ReceiveProductScreen({super.key});

  @override
  State<ReceiveProductScreen> createState() => _ReceiveProductScreenState();
}

class _ReceiveProductScreenState extends State<ReceiveProductScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _receivedDateController = TextEditingController();

  Product? _selectedProduct;
  Shop? _selectedShop;
  DateTime _receivedDate = DateTime.now();
  bool _isSubmitting = false;
  bool _isScanning = false;
  List<Product> _searchResults = [];
  List<Shop> _shops = []; // Mock shops for now

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _receivedDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(_receivedDate);
    _loadShops();
  }

  Future<void> _loadShops() async {
    // Mock shops - in real app, fetch from API
    setState(() {
      _shops = [
        Shop(id: 1, name: 'Main Shop', location: 'Downtown'),
        Shop(id: 2, name: 'Branch Shop', location: 'Suburb'),
      ];
      _selectedShop = _shops.first; // Auto-select first shop
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Product'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan QR', icon: Icon(Icons.qr_code_scanner)),
            Tab(text: 'Manual Search', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildQRScanTab(), _buildManualSearchTab()],
      ),
    );
  }

  Widget _buildQRScanTab() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.red,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Scan product QR code',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Visibility(
          visible: _selectedProduct != null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _buildProductPreview(),
        ),
      ],
    );
  }

  Widget _buildManualSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Products',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty && _searchController.text.isEmpty
              ? const Center(child: Text('Start typing to search products'))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
                    return ListTile(
                      title: Text('Product ${product.id}'),
                      subtitle: Text('Batch: ${product.batchNumber}'),
                      onTap: () => setState(() => _selectedProduct = product),
                    );
                  },
                ),
        ),
        Visibility(
          visible: _selectedProduct != null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _buildProductPreview(),
        ),
      ],
    );
  }

  Widget _buildProductPreview() {
    if (_selectedProduct == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product ID: ${_selectedProduct!.id}'),
            Text('Batch: ${_selectedProduct!.batchNumber}'),
            Text(
              'Weight: ${_selectedProduct!.weight != null ? '${_selectedProduct!.weight} ${_selectedProduct!.weightUnit}' : 'N/A'}',
            ),
            const SizedBox(height: 16),
            _buildReceiptForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptForm() {
    return Form(
      child: Column(
        children: [
          DropdownButtonFormField<Shop>(
            initialValue: _selectedShop,
            decoration: const InputDecoration(
              labelText: 'Shop',
              border: OutlineInputBorder(),
            ),
            items: _shops.map((shop) {
              return DropdownMenuItem(
                value: shop,
                child: Text('${shop.name} - ${shop.location}'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedShop = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _receivedDateController,
            decoration: const InputDecoration(
              labelText: 'Received Date',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: _selectDate,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReceipt,
              child: _isSubmitting
                  ? const LoadingIndicator()
                  : const Text('Receive Product'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanning) {
        setState(() => _isScanning = true);
        await _processQRCode(scanData.code!);
        setState(() => _isScanning = false);
      }
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    // Assume QR code format: 'product:{id}:{batch}'
    final parts = qrCode.split(':');
    if (parts.length >= 3 && parts[0] == 'product') {
      final productId = int.tryParse(parts[1]);
      if (productId != null) {
        final product = await context.read<ProductProvider>().fetchProductByQR(
          qrCode,
        );
        if (product != null) {
          setState(() => _selectedProduct = product);
          Fluttertoast.showToast(msg: 'Product scanned successfully');
        } else {
          Fluttertoast.showToast(msg: 'Product not found');
        }
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    // Mock search - in real app, search API
    final results = context
        .read<ProductProvider>()
        .products
        .where(
          (product) =>
              product.batchNumber.toLowerCase().contains(query.toLowerCase()) ||
              product.id.toString().contains(query),
        )
        .toList();
    setState(() => _searchResults = results);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _receivedDate = picked;
        _receivedDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitReceipt() async {
    if (_selectedProduct == null || _selectedShop == null) {
      Fluttertoast.showToast(msg: 'Please select product and shop');
      return;
    }

    setState(() => _isSubmitting = true);
    final currentContext = context;
    final productId = _selectedProduct!.id;

    final receipt = ShopReceipt(
      shop: _selectedShop!.id!,
      product: _selectedProduct!.id!,
      receivedQuantity: _selectedProduct!.weight ?? 0.0,
      receivedAt: _receivedDate,
    );

    try {
      await ShopReceiptService().recordReceipt(receipt);
      Fluttertoast.showToast(msg: 'Product received successfully');
      currentContext.go('/product-detail/$productId');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to record receipt: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // qrController?.dispose(); // No longer necessary with qr_code_scanner_plus
    _searchController.dispose();
    _receivedDateController.dispose();
    super.dispose();
  }
}
