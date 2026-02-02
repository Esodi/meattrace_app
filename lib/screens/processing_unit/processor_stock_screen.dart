import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/external_vendor_provider.dart';
import '../../models/animal.dart';
import '../../models/product.dart';
import '../../models/external_vendor.dart';
import '../../widgets/core/custom_app_bar.dart';
import '../../widgets/core/enhanced_back_button.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_typography.dart';
import '../../providers/product_category_provider.dart';
import '../../models/product_category.dart';

class ProcessorStockScreen extends StatefulWidget {
  const ProcessorStockScreen({super.key});

  @override
  State<ProcessorStockScreen> createState() => _ProcessorStockScreenState();
}

class _ProcessorStockScreenState extends State<ProcessorStockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _tagIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSpecies = 'Cow';
  SlaughterPartType _selectedPartType = SlaughterPartType.wholeCarcass;
  ExternalVendor? _selectedVendor;
  ProductCategory? _selectedCategory;
  bool _isProcessing = false;

  final List<String> _speciesOptions = ['Cow', 'Goat', 'Sheep', 'Pig'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExternalVendorProvider>().fetchVendors();
      context.read<ProductCategoryProvider>().fetchCategories();
      // Ensure user profile is fresh to have correct unitId
      context.read<AuthProvider>().refreshProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _tagIdController.dispose();
    _ageController.dispose();
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
      final animalProvider = context.read<AnimalProvider>();
      final productProvider = context.read<ProductProvider>();

      if (currentUser == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final tagId = _tagIdController.text.trim();
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final price = double.tryParse(_priceController.text) ?? 0.0;

      final unitId = currentUser.processingUnitId ?? 0;

      if (_tabController.index == 0) {
        // Register Slaughtered Animal
        final animal = Animal(
          abbatoir: 0, // External/Initial
          abbatoirName: _selectedVendor?.name ?? 'External Vendor',
          species: _selectedSpecies,
          animalId: tagId,
          animalName: _nameController.text.trim(),
          age: double.tryParse(_ageController.text) ?? 0,
          liveWeight: double.tryParse(_weightController.text) ?? 0,
          remainingWeight: double.tryParse(_weightController.text) ?? 0,
          gender: 'unknown',
          slaughtered: true,
          slaughteredAt: now,
          createdAt: now,
          acquisitionPrice: double.tryParse(_priceController.text) ?? 0,
          isExternal: true,
          externalVendorName: _selectedVendor?.name ?? 'Opening Stock',
          acquisitionDate: now,
          originType: 'INITIAL_STOCK',
          receivedBy: currentUser.id,
          receivedAt: now,
          transferredTo: unitId,
        );
        await animalProvider.createAnimal(animal);
      } else if (_tabController.index == 1) {
        // Register Slaughter Part
        final phantomAnimal = Animal(
          abbatoir: 0,
          abbatoirName: _selectedVendor?.name ?? 'External Vendor',
          species: _selectedSpecies,
          animalId: 'PART-HOLDER-${now.millisecondsSinceEpoch}',
          age: 0,
          gender: 'unknown',
          liveWeight: weight,
          remainingWeight: 0,
          createdAt: now,
          slaughtered: true,
          slaughteredAt: now,
          isExternal: true,
          externalVendorName: _selectedVendor?.name ?? 'Opening Stock',
          originType: 'INITIAL_STOCK',
          receivedBy: currentUser.id,
          receivedAt: now,
          transferredTo: unitId,
        );

        final createdAnimal = await animalProvider.createAnimal(phantomAnimal);
        if (createdAnimal?.id != null) {
          final part = SlaughterPart(
            animalId: createdAnimal!.id!,
            partType: _selectedPartType,
            weight: weight,
            weightUnit: 'kg',
            createdAt: now,
            description: _notesController.text.trim(),
            partId: tagId.isNotEmpty ? tagId : null,
            receivedBy: currentUser.id,
            receivedAt: now,
            transferredTo: unitId,
          );
          await animalProvider.createSlaughterPart(part);
        }
      } else {
        // Register Product
        if (_selectedCategory == null) {
          throw Exception('Please select a product category');
        }

        final product = Product(
          processingUnit: unitId,
          processingUnitName: currentUser.processingUnitName ?? 'Initial Stock',
          animal: null,
          productType: 'meat', // Coarse type for backend
          category: _selectedCategory?.id, // Fine-grained category ID
          quantity: 1,
          createdAt: now,
          name: _nameController.text.isNotEmpty
              ? _nameController.text.trim()
              : _selectedCategory!.name,
          batchNumber: _batchController.text.isEmpty
              ? 'PROC-INIT-${now.millisecondsSinceEpoch}'
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
        );
        final createdProduct = await productProvider.createProduct(product);
        if (createdProduct == null) throw Exception('Failed to create product');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getCategoryName()} Added Successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding stock: $e'),
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
    _tagIdController.clear();
    _ageController.clear();
    _weightController.clear();
    _priceController.clear();
    _batchController.clear();
    _notesController.clear();
    setState(() {
      _selectedVendor = null;
      _selectedCategory = null;
    });
  }

  String _getCategoryName() {
    switch (_tabController.index) {
      case 0:
        return 'Slaughtered Animal';
      case 1:
        return 'Slaughter Part';
      case 2:
        return 'Product';
      default:
        return 'Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Processor Stock Entry',
        leading: const EnhancedBackButton(fallbackRoute: '/processor-home'),
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.processorPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.processorPrimary,
            tabs: const [
              Tab(icon: Icon(Icons.checkroom), text: 'Slaughtered'),
              Tab(icon: Icon(Icons.restaurant), text: 'Parts'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'Products'),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Vendor & Price'),
                    _buildVendorSelector(),
                    const SizedBox(height: AppTheme.space16),
                    _buildPriceField(),
                    const Divider(height: AppTheme.space32),

                    _buildSectionTitle('Item Details'),
                    if (_tabController.index == 0 || _tabController.index == 1)
                      _buildSpeciesSelector(),
                    if (_tabController.index == 2) _buildCategorySelector(),
                    if (_tabController.index == 1) ...[
                      const SizedBox(height: AppTheme.space16),
                      _buildPartTypeSelector(),
                    ],
                    const SizedBox(height: AppTheme.space16),
                    if (_tabController.index != 2) ...[
                      _buildTagIdField(),
                      const SizedBox(height: AppTheme.space16),
                      if (_tabController.index == 0) ...[
                        _buildAnimalNameField(),
                        const SizedBox(height: AppTheme.space16),
                        _buildAgeField(),
                        const SizedBox(height: AppTheme.space16),
                      ],
                    ],
                    if (_tabController.index == 2) ...[
                      _buildProductNameField(),
                      const SizedBox(height: AppTheme.space16),
                      _buildBatchField(),
                    ],
                    const SizedBox(height: AppTheme.space16),
                    _buildWeightField(),
                    const SizedBox(height: AppTheme.space16),
                    _buildNotesField(),
                    const SizedBox(height: AppTheme.space32),
                    _buildSubmitButton(),
                    const SizedBox(height: AppTheme.space48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      color: AppColors.processorPrimary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.processorPrimary, size: 20),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              'Add animals, parts, or products brought from external sources.',
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
            prefixIcon: Icon(Icons.business),
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
        labelText: 'Acquisition Price / Value',
        border: OutlineInputBorder(),
        prefixText: 'TZS ',
        prefixIcon: Icon(Icons.payments_outlined),
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Species', style: AppTypography.labelMedium()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _speciesOptions.map((s) {
            final isSelected = _selectedSpecies == s;
            return ChoiceChip(
              label: Text(s),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedSpecies = s),
              selectedColor: AppColors.processorPrimary.withValues(alpha: 0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<ProductCategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final uniqueCategories = <int, ProductCategory>{};
        for (var cat in provider.categories) {
          if (cat.id != null) uniqueCategories[cat.id!] = cat;
        }

        return DropdownButtonFormField<ProductCategory>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Product Category',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: uniqueCategories.values
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name)))
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
          validator: (v) => v == null ? 'Please select a category' : null,
        );
      },
    );
  }

  Widget _buildPartTypeSelector() {
    return DropdownButtonFormField<SlaughterPartType>(
      initialValue: _selectedPartType,
      decoration: const InputDecoration(
        labelText: 'Part Type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.restaurant),
      ),
      items: SlaughterPartType.values
          .map(
            (type) =>
                DropdownMenuItem(value: type, child: Text(type.displayName)),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedPartType = val!),
    );
  }

  Widget _buildTagIdField() {
    return TextFormField(
      controller: _tagIdController,
      decoration: InputDecoration(
        labelText: _tabController.index == 1
            ? 'Part ID / Batch'
            : 'Animal Tag ID',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.tag),
      ),
      validator: (v) => v?.isEmpty == true ? 'Tag ID is required' : null,
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Age (months)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
      ),
    );
  }

  Widget _buildAnimalNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Animal Name (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.pets),
        hintText: 'e.g., Red Cow, Bessie',
      ),
    );
  }

  Widget _buildProductNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Product Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shopping_bag_outlined),
        hintText: 'e.g., Prime Beef Cubes',
      ),
    );
  }

  Widget _buildBatchField() {
    return TextFormField(
      controller: _batchController,
      decoration: const InputDecoration(
        labelText: 'Batch Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
        hintText: 'Leave empty to auto-generate',
      ),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Weight (kg)',
        border: OutlineInputBorder(),
        suffixText: 'kg',
        prefixIcon: Icon(Icons.monitor_weight_outlined),
      ),
      validator: (v) => v?.isEmpty == true ? 'Weight is required' : null,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Additional Notes',
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
            : Text('Add to Inventory', style: AppTypography.button()),
      ),
    );
  }
}
