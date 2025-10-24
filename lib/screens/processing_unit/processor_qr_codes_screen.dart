import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

/// Processor QR Codes Screen - View and manage product QR codes
class ProcessorQRCodesScreen extends StatefulWidget {
  const ProcessorQRCodesScreen({super.key});

  @override
  State<ProcessorQRCodesScreen> createState() => _ProcessorQRCodesScreenState();
}

class _ProcessorQRCodesScreenState extends State<ProcessorQRCodesScreen> {
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'QR Codes',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.textPrimary),
            tooltip: 'Scan QR Code',
            onPressed: () => context.push('/qr-scanner?source=processor'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by batch number or product name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Product QR Codes List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.processorPrimary,
                    ),
                  )
                : Consumer<ProductProvider>(
                    builder: (context, productProvider, child) {
                      final products = productProvider.products.where((product) {
                        if (_searchQuery.isEmpty) return true;
                        return product.name.toLowerCase().contains(_searchQuery) ||
                            product.batchNumber.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (products.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: AppColors.processorPrimary,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppTheme.space12,
                            mainAxisSpacing: AppTheme.space12,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return _buildQRCodeCard(products[index]);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(Product product) {
    final qrData = '${Constants.baseUrl}/product-info/view/${product.id}/';
    debugPrint('🔗 Generated QR Data: $qrData');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: () => _showQRCodeDialog(product, qrData),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppColors.processorPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                product.name,
                style: AppTypography.labelLarge().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.space4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.processorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  product.batchNumber,
                  style: AppTypography.caption().copyWith(
                    color: AppColors.processorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.processorPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 60,
                color: AppColors.processorPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'No QR Codes Available',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create products to generate QR codes'
                  : 'No products match your search',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(Product product, String qrData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product QR Code',
                    style: AppTypography.headlineMedium(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: AppColors.processorPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                product.name,
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.processorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Batch: ${product.batchNumber}',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.processorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share feature coming soon')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.processorPrimary,
                        side: BorderSide(color: AppColors.processorPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement download functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Download feature coming soon')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.processorPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
