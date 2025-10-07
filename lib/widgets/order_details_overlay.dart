import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';

class OrderDetailsOverlay extends StatefulWidget {
  final int orderId;

  const OrderDetailsOverlay({super.key, required this.orderId});

  @override
  State<OrderDetailsOverlay> createState() => _OrderDetailsOverlayState();
}

class _OrderDetailsOverlayState extends State<OrderDetailsOverlay> {
  Order? _order;
  List<Product> _products = [];
  Shop? _shop;
  bool _isLoading = true;
  String? _error;

  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() => _isLoading = true);

      // Fetch order details
      final order = await _orderService.getOrder(widget.orderId);
      _order = order;

      // Fetch shop details
      final shops = await _productService.getShops();
      try {
        final shopData = shops.firstWhere(
          (shop) => shop['id'] == order.shop,
        );
        _shop = Shop.fromJson(shopData);
      } catch (e) {
        // Shop not found, keep _shop as null
      }

      // Fetch product details for each order item
      final products = <Product>[];
      for (final item in order.items) {
        try {
          final product = await _productService.getProduct(item.product);
          products.add(product);
        } catch (e) {
          // If product fetch fails, continue with others
          print('Failed to fetch product ${item.product}: $e');
        }
      }
      _products = products;

    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _buildOrderDetailsView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load order details',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsView() {
    if (_order == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Header with close and action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${_order!.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareOrder,
                tooltip: 'Share Order',
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _downloadOrder,
                tooltip: 'Download Details',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Metadata
                _buildOrderMetadata(),

                const SizedBox(height: 24),

                // Products Section
                _buildProductsSection(),

                const SizedBox(height: 24),

                // Supply Chain Section
                _buildSupplyChainSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderMetadata() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', '#${_order!.id}'),
            _buildInfoRow('Date & Time',
              DateFormat('MMM dd, yyyy HH:mm').format(_order!.createdAt)),
            _buildInfoRow('Status', _order!.status.toUpperCase()),
            if (_shop != null) _buildInfoRow('Shop', _shop!.name),
            if (_order!.deliveryAddress != null)
              _buildInfoRow('Delivery Address', _order!.deliveryAddress!),
            if (_order!.notes != null)
              _buildInfoRow('Notes', _order!.notes!),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Pricing Summary
            const Text(
              'Pricing Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Total Amount',
              '\$${_order!.totalAmount.toStringAsFixed(2)}'),
            // Add taxes and discounts if available in the model
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            ..._order!.items.map((item) {
              Product? product;
              try {
                product = _products.firstWhere(
                  (p) => p.id == item.product,
                );
              } catch (e) {
                product = null;
              }

              return _buildProductItem(item, product);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(OrderItem item, Product? product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product?.name ?? 'Product #${item.product}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '\$${item.unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Quantity: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)} = \$${item.subtotal.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (product != null) ...[
            const SizedBox(height: 8),
            Text(
              product.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (product.batchNumber.isNotEmpty)
                  _buildChip('Batch: ${product.batchNumber}'),
                const SizedBox(width: 8),
                if (product.weight != null)
                  _buildChip('${product.weight} ${product.weightUnit}'),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Product details not available',
              style: TextStyle(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplyChainSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supply Chain Traceability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            ..._products.map((product) => _buildProductTraceability(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTraceability(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),

          // Timeline
          if (product.timeline.isNotEmpty) ...[
            ...product.timeline.map((event) => _buildTimelineEvent(event)),
          ] else ...[
            const Text(
              'Supply chain timeline not available',
              style: TextStyle(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(ProductTimelineEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  event.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(event.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _shareOrder() {
    final orderText = '''
Order #${_order!.id}
Date: ${DateFormat('MMM dd, yyyy HH:mm').format(_order!.createdAt)}
Status: ${_order!.status}
Total: \$${_order!.totalAmount.toStringAsFixed(2)}

Products:
${_order!.items.map((item) {
      Product? product;
      try {
        product = _products.firstWhere(
          (p) => p.id == item.product,
        );
      } catch (e) {
        product = null;
      }
      return '- ${product?.name ?? 'Product #${item.product}'} (${item.quantity}x) - \$${item.subtotal.toStringAsFixed(2)}';
    }).join('\n')}
    '''.trim();

    Share.share(orderText, subject: 'Order #${_order!.id} Details');
  }

  void _downloadOrder() {
    // TODO: Implement PDF download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon')),
    );
  }
}







