import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts();
      
      final product = productProvider.products.firstWhere(
        (p) => p.id.toString() == widget.productId,
        orElse: () => throw Exception('Product not found'),
      );
      
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildContent()),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.processorPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _product?.name ?? '',
          style: AppTypography.headlineSmall(color: Colors.white),
        ),
        background: _buildHeaderImage(),
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

  Widget _buildHeaderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.processorPrimary,
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 100,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildQRSection(),
        const SizedBox(height: 16),
        _buildBasicInfoSection(),
        const SizedBox(height: 16),
        _buildTraceabilitySection(),
        const SizedBox(height: 16),
        _buildCertificationsSection(),
        const SizedBox(height: 16),
        _buildActionsSection(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildQRSection() {
    return CustomCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Product QR Code', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(CustomIcons.MEATTRACE_ICON, size: 140),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _product?.batchNumber ?? 'No batch',
              style: AppTypography.bodyLarge(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Print QR
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Share QR
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

  Widget _buildBasicInfoSection() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Details', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.category, 'Product Type', _product?.productType ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(CustomIcons.MEATTRACE_ICON, 'Batch Number', _product?.batchNumber ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(Icons.monitor_weight, 'Weight', '${_product?.weight ?? 0} kg'),
            const Divider(height: 24),
            _buildInfoRow(Icons.attach_money, 'Price', '\$${_product?.price?.toStringAsFixed(2) ?? '0.00'}/kg'),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today, 'Production Date', _formatDate(_product?.createdAt)),
            if (_product?.description != null && _product!.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Description', style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.w600)),
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

  Widget _buildTraceabilitySection() {
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
                TextButton(
                  onPressed: () {
                    // Navigate to full traceability view
                  },
                  child: const Text('View Full Journey →'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTraceStep('Origin Farm', 'Green Valley Farm', true),
            _buildTraceStep('Processing', 'MeatCo Processing Unit', false),
            _buildTraceStep('Current Location', 'Warehouse A', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceStep(String title, String location, bool isFirst) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.processorPrimary : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyLarge()),
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

  Widget _buildCertificationsSection() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Certifications', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCertificationBadge('✓ Organic', Colors.green),
                _buildCertificationBadge('✓ Grade A', Colors.blue),
                _buildCertificationBadge('✓ Halal', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTypography.bodyMedium(color: color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          CustomButton(
            label: 'Transfer Product',
            onPressed: () {
              // Navigate to transfer screen
            },
            variant: ButtonVariant.primary,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Edit Details',
                  onPressed: () {
                    // Navigate to edit screen
                  },
                  variant: ButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'View Stock',
                  onPressed: () {
                    // Navigate to stock screen
                  },
                  variant: ButtonVariant.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text('Product not found', style: AppTypography.headlineMedium()),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Go Back',
            onPressed: () => context.pop(),
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
