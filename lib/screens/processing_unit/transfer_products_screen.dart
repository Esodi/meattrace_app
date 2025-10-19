import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_button.dart';

/// Transfer Products Screen for Processing Unit
/// Step 1: Select products to transfer
/// Step 2: Select destination shop
/// Step 3: Confirm and complete transfer
class TransferProductsScreen extends StatefulWidget {
  const TransferProductsScreen({super.key});

  @override
  State<TransferProductsScreen> createState() => _TransferProductsScreenState();
}

class _TransferProductsScreenState extends State<TransferProductsScreen> {
  int _currentStep = 0;
  final List<Product> _selectedProducts = [];
  Map<String, dynamic>? _selectedShop;
  bool _isLoading = false;
  bool _isTransferring = false;
  List<Product> _availableProducts = [];
  List<Map<String, dynamic>> _shops = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Fetch products
      await productProvider.fetchProducts();
      
      // Filter available products (not already transferred)
      final availableProducts = productProvider.products
          .where((product) => product.transferredTo == null)
          .toList();
      
      // Fetch shops
      final dio = DioClient().dio;
      final shopsResponse = await dio.get('/users/?user_type=shop');
      final shopsList = (shopsResponse.data['results'] as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();
      
      setState(() {
        _availableProducts = availableProducts;
        _shops = shopsList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTransfer() async {
    if (_selectedProducts.isEmpty || _selectedShop == null) {
      return;
    }

    setState(() => _isTransferring = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final shopId = _selectedShop!['id'];
      final productIds = _selectedProducts.map((p) => p.id!).toList();

      await productProvider.transferProducts(productIds, shopId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transferred ${_selectedProducts.length} product(s)'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/processor-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error transferring products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isTransferring = false);
    }
  }

  void _toggleProductSelection(Product product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  void _selectAllProducts() {
    setState(() {
      _selectedProducts.clear();
      _selectedProducts.addAll(_filteredProducts);
    });
  }

  void _deselectAllProducts() {
    setState(() {
      _selectedProducts.clear();
    });
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _availableProducts;
    }
    return _availableProducts.where((product) {
      final query = _searchQuery.toLowerCase();
      return product.name.toLowerCase().contains(query) ||
          product.batchNumber.toLowerCase().contains(query) ||
          product.productType.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/processor-home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              controlsBuilder: _buildStepControls,
              steps: [
                Step(
                  title: const Text('Select Products'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildProductSelectionStep(),
                ),
                Step(
                  title: const Text('Select Shop'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildShopSelectionStep(),
                ),
                Step(
                  title: const Text('Confirm'),
                  isActive: _currentStep >= 2,
                  content: _buildConfirmationStep(),
                ),
              ],
            ),
    );
  }

  Widget _buildStepControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (details.currentStep < 2)
            Expanded(
              child: ElevatedButton(
                onPressed: details.currentStep == 0 && _selectedProducts.isEmpty
                    ? null
                    : details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.processorPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  details.currentStep == 0 && _selectedProducts.isEmpty
                      ? 'Select products to continue'
                      : 'Continue',
                ),
              ),
            ),
          if (details.currentStep == 2)
            Expanded(
              child: ElevatedButton(
                onPressed: _isTransferring ? null : _submitTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isTransferring ? 'Transferring...' : 'Complete Transfer'),
              ),
            ),
          if (details.currentStep > 0) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                child: const Text('Back'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one product')),
      );
      return;
    }
    
    if (_currentStep == 1 && _selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shop')),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildProductSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedProducts.length} selected',
              style: AppTypography.bodyMedium().copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _selectAllProducts,
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('Select All'),
                ),
                TextButton.icon(
                  onPressed: _deselectAllProducts,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Products list
        if (_filteredProducts.isEmpty)
          _buildEmptyState()
        else
          ..._filteredProducts.map((product) => _buildProductCard(product)),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProducts.contains(product);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggleProductSelection(product),
        activeColor: AppTheme.primaryGreen,
        title: Text(
          product.name,
          style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Batch: ${product.batchNumber}',
              style: AppTypography.bodySmall(),
            ),
            Text(
              '${product.productType} • ${product.weight ?? 'N/A'} ${product.weightUnit}',
              style: AppTypography.bodySmall().copyWith(color: AppColors.textSecondary),
            ),
            Text(
              'Price: \$${product.price.toStringAsFixed(2)} • Qty: ${product.quantity}',
              style: AppTypography.bodySmall().copyWith(color: AppTheme.primaryGreen),
            ),
          ],
        ),
        secondary: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.inventory_2,
            color: AppTheme.primaryGreen,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildShopSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select destination shop for ${_selectedProducts.length} product(s)',
          style: AppTypography.bodyMedium().copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        if (_shops.isEmpty)
          _buildNoShopsState()
        else
          ..._shops.map((shop) => _buildShopCard(shop)),
      ],
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: RadioListTile<Map<String, dynamic>>(
        value: shop,
        groupValue: _selectedShop,
        onChanged: (value) {
          setState(() => _selectedShop = value);
        },
        activeColor: AppTheme.primaryGreen,
        title: Text(
          shop['username'] ?? 'Unknown Shop',
          style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              shop['email'] ?? 'No email',
              style: AppTypography.bodySmall().copyWith(color: AppColors.textSecondary),
            ),
            if (shop['organization_name'] != null) ...[
              const SizedBox(height: 2),
              Text(
                shop['organization_name'],
                style: AppTypography.bodySmall(),
              ),
            ],
          ],
        ),
        secondary: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.secondaryBurgundy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.storefront,
            color: AppTheme.secondaryBurgundy,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary header
        Text(
          'Transfer Summary',
          style: AppTypography.headlineSmall().copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Shop information
        CustomCard(
          color: AppTheme.secondaryBurgundy.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storefront, color: AppTheme.secondaryBurgundy),
                  const SizedBox(width: 8),
                  Text(
                    'Destination Shop',
                    style: AppTypography.bodyMedium().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _selectedShop?['username'] ?? 'Unknown',
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedShop?['organization_name'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  _selectedShop!['organization_name'],
                  style: AppTypography.bodySmall(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Products being transferred
        Text(
          'Products to Transfer (${_selectedProducts.length})',
          style: AppTypography.bodyLarge().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        ..._selectedProducts.map((product) => CustomCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.bodyMedium().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Batch: ${product.batchNumber}',
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    '${product.quantity} units',
                    style: AppTypography.bodySmall(),
                  ),
                ],
              ),
            ],
          ),
        )),

        const SizedBox(height: 16),

        // Total summary
        CustomCard(
          color: AppTheme.primaryGreen.withValues(alpha: 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Value',
                style: AppTypography.bodyLarge().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_calculateTotalValue().toStringAsFixed(2)}',
                style: AppTypography.headlineSmall().copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Warning message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warningOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Products will be transferred to the shop and marked as pending receipt.',
                  style: AppTypography.bodySmall().copyWith(
                    color: AppTheme.warningOrange.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateTotalValue() {
    return _selectedProducts.fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: AppTypography.headlineSmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create some products first before transferring',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Create Product',
              onPressed: () => context.go('/create-product'),
              customColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoShopsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No shops available',
              style: AppTypography.headlineSmall().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contact administrator to register shops',
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
}
