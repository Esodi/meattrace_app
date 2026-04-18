import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';

/// Product Detail View - Complete information about a single product
class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productId = int.tryParse(widget.productId);
      if (productId == null) {
        setState(() {
          _error = 'Invalid product ID';
          _isLoading = false;
        });
        return;
      }

      final productProvider = context.read<ProductProvider>();
      final product = await productProvider.getProduct(productId);

      if (!mounted) return;
      setState(() {
        _product = product;
        _error = product == null ? 'Product not found' : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProduct() async {
    await _loadProduct();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.processorPrimary;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _product == null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _refreshProduct,
              color: primaryColor,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(primaryColor),
                  SliverToBoxAdapter(child: _buildContent(primaryColor)),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _product?.name ?? '',
          style: AppTypography.headlineSmall(color: Colors.white),
        ),
        background: _buildHeaderImage(primaryColor),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Navigate to edit screen
          },
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share product
          },
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildHeaderImage(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(color: primaryColor),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 100,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildContent(Color primaryColor) {
    return Column(
      children: [
        _buildQRSection(),
        const SizedBox(height: 16),
        _buildBasicInfoSection(primaryColor),
        const SizedBox(height: 16),
        _buildTraceabilitySection(primaryColor),
      ],
    );
  }

  Widget _buildQRSection() {
    // Use the actual QR code data from the product, fallback to batch number or product ID
    final String qrData =
        _product?.qrCode ??
        _product?.batchNumber ??
        'PRODUCT-${_product?.id ?? 'UNKNOWN'}';

    return CustomCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Product QR Code', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: _product?.qrCode != null && _product!.qrCode!.isNotEmpty
                  ? QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No QR Code',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              _product?.batchNumber ?? 'No batch',
              style: AppTypography.bodyLarge().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_product?.qrCode != null && _product!.qrCode!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'ID: ${_product?.id ?? 'N/A'}',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement print QR functionality
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Print functionality coming soon'),
                      ),
                    );
                    }
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement share QR functionality
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share functionality coming soon'),
                      ),
                    );
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(Color primaryColor) {
    final bool isAnimalPart =
        _product?.slaughterPartId != null || _product?.animalAnimalId != null;

    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Details', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),

            // Prominently display Animal Tag if this is an animal part
            if (isAnimalPart && _product?.animalAnimalId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Animal Tag',
                                style: AppTypography.labelMedium().copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _product!.animalAnimalId!,
                                style: AppTypography.headlineSmall().copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_product?.animalSpecies != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Species: ',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _product!.animalSpecies!,
                            style: AppTypography.bodyMedium().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_product?.slaughterPartName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.cut,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cut/Part: ',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _product!.slaughterPartName!,
                            style: AppTypography.bodyMedium().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],

            _buildInfoRow(
              Icons.category,
              'Product Type',
              _product?.productType ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              CustomIcons.meattraceIcon,
              'Batch Number',
              _product?.batchNumber ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.monitor_weight,
              'Weight',
              '${_product?.weight ?? 0} kg',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.attach_money,
              'Price',
              '\$${_product?.price.toStringAsFixed(2) ?? '0.00'}/kg',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Production Date',
              _formatDate(_product?.createdAt),
            ),
            if (_product?.processingUnitName != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.factory,
                'Processing Unit',
                _product!.processingUnitName!,
              ),
            ],
            if (_product?.description != null &&
                _product!.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _product!.description,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTraceabilitySection(Color primaryColor) {
    // Build traceability timeline based on available product data
    final List<Map<String, dynamic>> traceSteps = [];

    // Parse timeline events to build traceability chain
    if (_product?.timeline != null && _product!.timeline.isNotEmpty) {
      // Group timeline events by stage/location
      final sortedTimeline = List<ProductTimelineEvent>.from(_product!.timeline)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (var event in sortedTimeline) {
        // Avoid duplicate locations
        final existingStep = traceSteps.where(
          (s) => s['location'] == event.location,
        );
        if (existingStep.isEmpty) {
          IconData icon = Icons.location_on;
          String title = event.action;

          // Determine icon based on action/location
          if (event.action.toLowerCase().contains('abbatoir') ||
              event.action.toLowerCase().contains('origin')) {
            icon = Icons.agriculture;
            title = 'Origin Abbatoir';
          } else if (event.action.toLowerCase().contains('process') ||
              event.action.toLowerCase().contains('slaughter')) {
            icon = Icons.factory;
            title = 'Processing';
          } else if (event.action.toLowerCase().contains('transfer') ||
              event.action.toLowerCase().contains('ship')) {
            icon = Icons.local_shipping;
            title = 'Transfer';
          } else if (event.action.toLowerCase().contains('receive')) {
            icon = Icons.inventory;
            title = 'Received';
          }

          traceSteps.add({
            'title': title,
            'location': event.location,
            'icon': icon,
            'timestamp': event.timestamp,
          });
        }
      }
    }

    // If no timeline events, build basic traceability from available data
    if (traceSteps.isEmpty) {
      // Add processing unit
      if (_product?.processingUnitName != null) {
        traceSteps.add({
          'title': 'Processing',
          'location': _product!.processingUnitName!,
          'icon': Icons.factory,
        });
      }

      // Add transfer information if product was transferred
      if (_product?.transferredToName != null) {
        traceSteps.add({
          'title': 'Transferred To',
          'location': _product!.transferredToName!,
          'icon': Icons.local_shipping,
        });
      }

      // Add received information if product was received by shop
      if (_product?.receivedByName != null) {
        traceSteps.add({
          'title': 'Received By',
          'location': _product!.receivedByName!,
          'icon': Icons.store,
        });
      }

      // Add current location (default to processing unit)
      if (traceSteps.isEmpty && _product?.processingUnitName != null) {
        traceSteps.add({
          'title': 'Current Location',
          'location': _product!.processingUnitName!,
          'icon': Icons.location_on,
        });
      }
    }

    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Traceability', style: AppTypography.headlineSmall()),
                if (traceSteps.length > 1)
                  TextButton(
                    onPressed: () {
                      // Navigate to full traceability view
                      // context.push('/product-journey/${_product?.id}');
                    },
                    child: const Text('View Full Journey →'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (traceSteps.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No traceability information available',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...traceSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return _buildTraceStep(
                  step['title'] as String,
                  step['location'] as String,
                  step['icon'] as IconData,
                  primaryColor,
                  isFirst: index == 0,
                  isLast: index == traceSteps.length - 1,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceStep(
    String title,
    String location,
    IconData icon,
    Color primaryColor, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFirst ? primaryColor : primaryColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor.withValues(alpha: 0.5),
                      primaryColor.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyLarge(),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _error != null ? 'Error Loading Product' : 'Product Not Found',
              style: AppTypography.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(
                  label: 'Retry',
                  onPressed: _loadProduct,
                  variant: ButtonVariant.primary,
                  icon: Icons.refresh,
                ),
                const SizedBox(width: 12),
                CustomButton(
                  label: 'Go Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/processor-home');
                    }
                  },
                  variant: ButtonVariant.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
