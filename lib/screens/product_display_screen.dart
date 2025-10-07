import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/product.dart';
import '../providers/scan_provider.dart';
import '../widgets/loading_indicator.dart';

class ProductDisplayScreen extends StatefulWidget {
  final String productId;

  const ProductDisplayScreen({super.key, required this.productId});

  @override
  State<ProductDisplayScreen> createState() => _ProductDisplayScreenState();
}

class _ProductDisplayScreenState extends State<ProductDisplayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanProvider>().fetchProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, scanProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => scanProvider.fetchProduct(widget.productId),
              ),
            ],
          ),
          body: scanProvider.isLoading
              ? const LoadingIndicator()
              : scanProvider.error != null
              ? _buildErrorView(scanProvider.error!, scanProvider)
              : scanProvider.currentProduct != null
              ? _buildProductView(scanProvider.currentProduct!)
              : const Center(child: Text('No product data')),
        );
      },
    );
  }

  Widget _buildErrorView(String error, ScanProvider scanProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => scanProvider.fetchProduct(widget.productId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductView(Product product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manufacturer: ${product.manufacturer}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: \$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Weight: ${product.weight} ${product.weightUnit}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Batch: ${product.batchNumber}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Timeline
          const Text(
            'Product Timeline',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimeline(product),
        ],
      ),
    );
  }

  Widget _buildTimeline(Product product) {
    if (product.timeline.isEmpty) {
      return const Center(child: Text('No timeline data available'));
    }

    // Sort timeline by timestamp
    final sortedTimeline = List.from(product.timeline)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTimeline.length,
      itemBuilder: (context, index) {
        final event = sortedTimeline[index];
        final isFirst = index == 0;
        final isLast = index == sortedTimeline.length - 1;

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: Colors.blue,
            indicatorXY: 0.1,
            padding: const EdgeInsets.all(6),
          ),
          endChild: Container(
            constraints: const BoxConstraints(minHeight: 80),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.action,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year} ${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          beforeLineStyle: const LineStyle(color: Colors.blue, thickness: 2),
        );
      },
    );
  }
}








