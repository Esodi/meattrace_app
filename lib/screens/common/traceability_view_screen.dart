import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/animal.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TraceabilityViewScreen extends StatefulWidget {
  final Product product;

  const TraceabilityViewScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<TraceabilityViewScreen> createState() => _TraceabilityViewScreenState();
}

class _TraceabilityViewScreenState extends State<TraceabilityViewScreen> {
  Animal? _sourceAnimal;
  List<ProductTimelineEvent> _timeline = [];

  @override
  void initState() {
    super.initState();
    _timeline = widget.product.timeline;
    _loadSourceAnimal();
  }

  Future<void> _loadSourceAnimal() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/animals/${widget.product.animal}/');
      setState(() {
        _sourceAnimal = Animal.fromMap(response.data);
      });
    } catch (e) {
      print('Error loading source animal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Traceability'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share traceability
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share traceability coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.processorPrimary,
                    AppColors.processorPrimary.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Batch: ${widget.product.batchNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoBadge(
                        Icons.inventory_2,
                        widget.product.productType,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        Icons.monitor_weight,
                        '${widget.product.weight ?? 0} ${widget.product.weightUnit}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Journey Timeline
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Journey',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track the complete journey from farm to your table',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Source Animal
                  if (_sourceAnimal != null)
                    _buildTimelineItem(
                      isFirst: true,
                      isLast: false,
                      title: 'Farm Origin',
                      subtitle: _sourceAnimal!.abbatoirName,
                      description: 'Animal ID: ${_sourceAnimal!.animalId}\n'
                          'Species: ${_sourceAnimal!.species}\n'
                          'Age: ${_sourceAnimal!.age} months\n'
                          'Weight: ${_sourceAnimal!.liveWeight ?? 0} kg',
                      icon: Icons.agriculture,
                      iconColor: AppColors.farmerPrimary,
                      date: _sourceAnimal!.createdAt,
                    ),

                  // Timeline Events
                  ...(_timeline.asMap().entries.map((entry) {
                    final index = entry.key;
                    final event = entry.value;
                    final isLast = index == _timeline.length - 1 && widget.product.receivedBy == null;
                    
                    return _buildTimelineItem(
                      isFirst: false,
                      isLast: isLast,
                      title: _getStageTitle(event.stage),
                      subtitle: event.location,
                      description: event.action,
                      icon: _getStageIcon(event.stage),
                      iconColor: _getStageColor(event.stage),
                      date: event.timestamp,
                    );
                  })),

                  // Current Location (if received by shop)
                  if (widget.product.receivedBy != null)
                    _buildTimelineItem(
                      isFirst: false,
                      isLast: true,
                      title: 'Shop/Retail',
                      subtitle: 'Available for Sale',
                      description: 'Product received and ready for consumers\n'
                          'Received: ${_formatDate(widget.product.receivedAt!)}',
                      icon: Icons.store,
                      iconColor: AppColors.shopPrimary,
                      date: widget.product.receivedAt!,
                    ),
                ],
              ),
            ),

            // Product Details
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Manufacturer', widget.product.manufacturer),
                  _buildDetailRow('Batch Number', widget.product.batchNumber),
                  _buildDetailRow('Price', '\$${widget.product.price.toStringAsFixed(2)} per ${widget.product.weightUnit}'),
                  _buildDetailRow('Quantity', '${widget.product.quantity.toInt()} units'),
                  if (widget.product.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required bool isFirst,
    required bool isLast,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconColor,
    required DateTime date,
  }) {
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: Colors.grey.shade300,
        thickness: 2,
      ),
      indicatorStyle: IndicatorStyle(
        width: 50,
        height: 50,
        indicator: Container(
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStageTitle(int? stage) {
    if (stage == null) return 'Processing';
    switch (stage) {
      case 1:
        return 'Receiving';
      case 2:
        return 'Inspection';
      case 3:
        return 'Processing';
      case 4:
        return 'Packaging';
      case 5:
        return 'Quality Check';
      default:
        return 'Processing Stage $stage';
    }
  }

  IconData _getStageIcon(int? stage) {
    if (stage == null) return Icons.factory;
    switch (stage) {
      case 1:
        return Icons.download;
      case 2:
        return Icons.search;
      case 3:
        return Icons.build;
      case 4:
        return Icons.inventory;
      case 5:
        return Icons.verified;
      default:
        return Icons.factory;
    }
  }

  Color _getStageColor(int? stage) {
    if (stage == null) return AppColors.processorPrimary;
    switch (stage) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return AppColors.processorPrimary;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.green;
      default:
        return AppColors.processorPrimary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
