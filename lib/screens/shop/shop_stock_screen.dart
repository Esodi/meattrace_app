import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/external_vendor_provider.dart';
import '../../models/product.dart';
import '../../models/external_vendor.dart';
import '../../widgets/core/custom_app_bar.dart';
import '../../widgets/core/enhanced_back_button.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_typography.dart';

class ShopStockScreen extends StatefulWidget {
  const ShopStockScreen({super.key});

  @override
  State<ShopStockScreen> createState() => _ShopStockScreenState();
}

class _ShopStockScreenState extends State<ShopStockScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();

  // Selection state
  String _selectedProductType = 'Beef';
  ExternalVendor? _selectedVendor;
  bool _isProcessing = false;

  final List<String> _productOptions = [
    'Beef',
    'Mutton',
    'Pork',
    'Offals',
    'Sausage',
    'Burger Patty',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExternalVendorProvider>().fetchVendors();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      final productProvider = context.read<ProductProvider>();

      if (currentUser == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      // Register Product for Shop
      final product = Product(
        processingUnit: 0, // Brought from external/opening
        processingUnitName: _selectedVendor?.name ?? 'External Vendor',
        animal: 0,
        productType: _selectedProductType,
        quantity: 1,
        createdAt: now,
        name: _nameController.text.isNotEmpty
            ? _nameController.text.trim()
            : _selectedProductType,
        batchNumber: _batchController.text.isEmpty
            ? 'SHOP-INIT-${now.millisecondsSinceEpoch}'
            : _batchController.text.trim(),
        weight: weight,
        weightUnit: 'kg',
        price: price,
        description: _notesController.text.trim(),
        manufacturer: currentUser.username,
        timeline: [],
        isExternal: true,
        externalVendorName: _selectedVendor?.name ?? 'Opening Stock',
        acquisitionPrice: price,
        remainingWeight: weight,
        receivedBy: currentUser.id,
        receivedAt: now,
        receivedByShopId: currentUser.shopId,
      );

      await productProvider.createProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product Added Successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _weightController.clear();
    _priceController.clear();
    _batchController.clear();
    _notesController.clear();
    setState(() {
      _selectedVendor = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Shop Inventory Entry',
        leading: const EnhancedBackButton(fallbackRoute: '/shop-home'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoBanner(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Source & Cost'),
                    _buildVendorSelector(),
                    const SizedBox(height: AppTheme.space16),
                    _buildPriceField(),
                    const Divider(height: AppTheme.space32),

                    _buildSectionTitle('Product Details'),
                    _buildProductTypeSelector(),
                    const SizedBox(height: AppTheme.space16),
                    _buildProductNameField(),
                    const SizedBox(height: AppTheme.space16),
                    _buildBatchField(),
                    const SizedBox(height: AppTheme.space16),
                    _buildWeightField(),
                    const SizedBox(height: AppTheme.space16),
                    _buildNotesField(),
                    const SizedBox(height: AppTheme.space32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      color: AppColors.processorPrimary.withValues(
        alpha: 0.1,
      ), // Using processor primary as shop theme is similar
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: AppColors.processorPrimary,
            size: 20,
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              'Register products currently in your shop or bought externally.',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Text(
        title,
        style: AppTypography.titleMedium().copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVendorSelector() {
    return Consumer<ExternalVendorProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<ExternalVendor>(
          initialValue: _selectedVendor,
          decoration: const InputDecoration(
            labelText: 'Select Vendor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          items: [
            const DropdownMenuItem<ExternalVendor>(
              value: null,
              child: Text('Opening Stock / Internal'),
            ),
            ...provider.vendors.map(
              (v) => DropdownMenuItem(value: v, child: Text(v.name)),
            ),
          ],
          onChanged: (v) => setState(() => _selectedVendor = v),
        );
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Purchase Price / Value',
        border: OutlineInputBorder(),
        prefixText: 'TZS ',
        prefixIcon: Icon(Icons.payments_outlined),
      ),
    );
  }

  Widget _buildProductTypeSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedProductType,
      decoration: const InputDecoration(
        labelText: 'Product Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: _productOptions
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      onChanged: (val) => setState(() => _selectedProductType = val!),
    );
  }

  Widget _buildProductNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Product Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shopping_bag_outlined),
        hintText: 'e.g., Ribeye Steak',
      ),
    );
  }

  Widget _buildBatchField() {
    return TextFormField(
      controller: _batchController,
      decoration: const InputDecoration(
        labelText: 'Batch / Lot Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
      ),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Current Weight (kg)',
        border: OutlineInputBorder(),
        suffixText: 'kg',
        prefixIcon: Icon(Icons.scale_outlined),
      ),
      validator: (v) => v?.isEmpty == true ? 'Weight is required' : null,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _submitStock,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.processorPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Add to Shop Inventory', style: AppTypography.button()),
      ),
    );
  }
}
