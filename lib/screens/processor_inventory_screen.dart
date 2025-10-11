import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import '../services/dio_client.dart';
import '../widgets/loading_indicator.dart';

class ProcessorInventoryScreen extends StatefulWidget {
  const ProcessorInventoryScreen({Key? key}) : super(key: key);

  @override
  State<ProcessorInventoryScreen> createState() => _ProcessorInventoryScreenState();
}

class _ProcessorInventoryScreenState extends State<ProcessorInventoryScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _refreshInventory(BuildContext context) async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  }

  Future<void> _regenerateQrCode(BuildContext context, Product product) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regenerating QR code...')),
      );

      final newQrCodeUrl = await _apiService.regenerateProductQrCode(product.id.toString());

      if (!mounted) return;

      // Update the product in the provider
      await Provider.of<ProductProvider>(context, listen: false).updateProduct(
        product.copyWith(qrCode: newQrCodeUrl),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code regenerated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to regenerate QR code: $e')),
      );
    }
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  tooltip: 'Regenerate QR Code',
                  onPressed: () => _regenerateQrCode(context, product),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Batch: ${product.batchNumber}'),
            Text('Type: ${product.productType}'),
            Text('Quantity: ${product.quantity}'),
            Text('Weight: ${product.weight} ${product.weightUnit}'),
            if (product.qrCode != null) ...[
              const SizedBox(height: 8),
              Image.network(
                '${DioClient.baseUrl}/media/${product.qrCode}',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processor Inventory'),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (productProvider.error != null) {
            return Center(
              child: Text(
                'Error loading inventory: ${productProvider.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final products = productProvider.products;
          if (products.isEmpty) {
            return const Center(
              child: Text('No products in inventory'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshInventory(context),
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) => _buildProductItem(context, products[index]),
            ),
          );
        },
      ),
    );
  }
}