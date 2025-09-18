import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../models/product_timeline.dart';
import '../widgets/loading_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<ProductTimelineItem> _timeline = [];
  bool _isLoading = true;
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch product details
      final product = await _fetchProductDetails(widget.productId);
      if (product != null) {
        setState(() => _product = product);
        // Fetch timeline
        await _fetchTimeline(widget.productId);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load product details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Product?> _fetchProductDetails(int productId) async {
    // Mock API call - in real app, use ProductService
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return Product(
      id: productId,
      processingUnit: 1,
      animal: 1,
      productType: 'Beef Steak',
      quantity: 5.0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      name: 'Premium Beef Steak',
      batchNumber: 'BATCH_001',
      weight: 10.5,
      weightUnit: 'kg',
      price: 25.99,
      description: 'High-quality beef steak from grass-fed cattle',
      manufacturer: 'ABC Meat Processing',
      category: 1,
      timeline: [],
    );
  }

  Future<void> _fetchTimeline(int productId) async {
    // Mock timeline data
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _timeline = [
        ProductTimelineItem(
          stage: 'Farm',
          description: 'Animal raised at Farm A',
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
          location: 'Farm A, Rural Area',
        ),
        ProductTimelineItem(
          stage: 'Processing',
          description: 'Processed at Unit 1, Batch BATCH_001',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          location: 'Processing Plant',
        ),
        ProductTimelineItem(
          stage: 'Shop',
          description: 'Received at Main Shop',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          location: 'Main Shop, Downtown',
        ),
      ];
    });
  }

  void _onRefresh() async {
    await _loadData();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    // No pagination for now
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: LoadingIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProduct,
            tooltip: 'Share product details',
          ),
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: _reportIssue,
            tooltip: 'Report issue',
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductHeader(),
              SizedBox(height: isTablet ? 32 : 24),
              _buildProductInfo(),
              SizedBox(height: isTablet ? 32 : 24),
              _buildTimeline(),
              SizedBox(height: isTablet ? 32 : 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Card(
        elevation: 8,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product ${_product!.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Batch: ${_product!.batchNumber}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.monitor_weight,
                          size: 16,
                          color: Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Weight: ${_product!.weight} ${_product!.weightUnit}',
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Category', 'Meat Product'), // Mock data
            _buildInfoRow('Origin Animal', 'Animal #${_product!.animal}'),
            _buildInfoRow(
              'Processing Unit',
              'Unit ${_product!.processingUnit}',
            ),
            _buildInfoRow('Batch Number', _product!.batchNumber),
            _buildInfoRow(
              'Created At',
              DateFormat('yyyy-MM-dd').format(_product!.createdAt),
            ),
            _buildInfoRow('Expiry Date', '2025-12-31'), // Mock data
            _buildInfoRow('Nutritional Info', 'High in protein'), // Mock data
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildTimeline() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Product Timeline',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF212121),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Progress indicator
            LinearProgressIndicator(
              value: 0.75, // Mock progress
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 8),
            const Text(
              '75% Complete',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timeline.length,
              itemBuilder: (context, index) {
                final item = _timeline[index];
                final isFirst = index == 0;
                final isLast = index == _timeline.length - 1;

                return TimelineTile(
                  alignment: TimelineAlign.manual,
                  lineXY: 0.1,
                  isFirst: isFirst,
                  isLast: isLast,
                  indicatorStyle: IndicatorStyle(
                    width: 24,
                    color: _getStageColor(item.stage),
                    padding: const EdgeInsets.all(8),
                    iconStyle: IconStyle(
                      color: Colors.white,
                      iconData: _getStageIcon(item.stage),
                    ),
                  ),
                  endChild: Container(
                    margin: const EdgeInsets.only(left: 16, bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.stage,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(item.timestamp),
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (item.location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFF9E9E9E),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location!,
                                  style: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  beforeLineStyle: LineStyle(
                    color: _getStageColor(item.stage),
                    thickness: 3,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'farm':
        return const Color(0xFF4CAF50);
      case 'processing':
        return const Color(0xFFFF9800);
      case 'shop':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getStageIcon(String stage) {
    switch (stage.toLowerCase()) {
      case 'farm':
        return Icons.agriculture;
      case 'processing':
        return Icons.factory;
      case 'shop':
        return Icons.store;
      default:
        return Icons.circle;
    }
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF212121),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewFullTraceability,
                  icon: const Icon(Icons.timeline),
                  label: const Text('View Full\nTraceability'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareProduct,
                  icon: const Icon(Icons.share),
                  label: const Text('Share\nDetails'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reportIssue,
              icon: const Icon(Icons.report_problem),
              label: const Text('Report Issue'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF44336),
                side: const BorderSide(color: Color(0xFFF44336), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullTraceability() async {
    // Mock URL - in real app, open web view or external app
    final url = 'https://example.com/traceability/${widget.productId}';
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    } else {
      Fluttertoast.showToast(msg: 'Could not open traceability link');
    }
  }

  void _shareProduct() {
    final text =
        '''
Product Details:
ID: ${_product!.id}
Batch: ${_product!.batchNumber}
Weight: ${_product!.weight} ${_product!.weightUnit}
Created: ${DateFormat('yyyy-MM-dd').format(_product!.createdAt)}
''';
    Share.share(text);
  }

  void _reportIssue() {
    // Mock report functionality
    Fluttertoast.showToast(msg: 'Report functionality not implemented yet');
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}
