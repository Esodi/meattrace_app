import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/animal.dart';
import '../../models/product.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

/// Create Product Screen - Convert received animals into products
class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedProductType = 'Fresh Meat';
  String _selectedWeightUnit = 'kg';
  String _selectedQualityGrade = 'Premium';
  List<Animal> _availableAnimals = [];
  int? _selectedAnimalId;
  bool _isLoading = false;

  final List<String> _productTypes = [
    'Fresh Meat',
    'Ground Beef',
    'Steak',
    'Ribs',
    'Roast',
    'Sausage',
    'Processed',
    'Other',
  ];

  final List<String> _qualityGrades = [
    'Premium',
    'Choice',
    'Select',
    'Standard',
  ];

  @override
  void initState() {
    super.initState();
    _generateBatchNumber();
    _loadAvailableAnimals();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchNumberController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _generateBatchNumber() {
    final now = DateTime.now();
    final batch = 'BTH-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    _batchNumberController.text = batch;
  }

  Future<void> _loadAvailableAnimals() async {
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      // Fetch all animals
      await animalProvider.fetchAnimals(slaughtered: null);

      if (currentUserId != null) {
        final available = animalProvider.animals.where((animal) {
          return animal.receivedBy == currentUserId && 
                 !animal.slaughtered &&
                 animal.healthStatus != 'Sick';
        }).toList();

        setState(() => _availableAnimals = available);
      }
    } catch (e) {
      debugPrint('Error loading animals: $e');
    }
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedAnimalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source animal')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create Product object
      final product = Product(
        processingUnit: authProvider.user!.id.toString(),
        animal: _selectedAnimalId!,
        productType: _selectedProductType,
        quantity: 1.0,
        createdAt: DateTime.now(),
        name: _nameController.text,
        batchNumber: _batchNumberController.text,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        weightUnit: _selectedWeightUnit,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descriptionController.text,
        manufacturer: authProvider.user!.username,
        timeline: [],
      );

      await productProvider.createProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating product: $e'),
            backgroundColor: AppColors.error,
          ),
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
          'Create Product',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Generate New Batch',
            onPressed: _generateBatchNumber,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.processorPrimary,
                    AppColors.processorPrimary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Product',
                          style: AppTypography.headlineMedium().copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Process animals into quality products',
                          style: AppTypography.bodyMedium().copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Source Animal Section
            _buildSectionHeader('Source Animal', Icons.pets),
            const SizedBox(height: AppTheme.space12),
            _buildSourceAnimalSelector(),
            const SizedBox(height: AppTheme.space24),

            // Product Details Section
            _buildSectionHeader('Product Details', Icons.info_outline),
            const SizedBox(height: AppTheme.space12),
            _buildProductDetailsCard(),
            const SizedBox(height: AppTheme.space24),

            // Measurements Section
            _buildSectionHeader('Measurements', Icons.monitor_weight),
            const SizedBox(height: AppTheme.space12),
            _buildMeasurementsCard(),
            const SizedBox(height: AppTheme.space24),

            // Additional Information Section
            _buildSectionHeader('Additional Information', Icons.description),
            const SizedBox(height: AppTheme.space12),
            _buildAdditionalInfoCard(),
            const SizedBox(height: AppTheme.space32),

            // Create Button
            CustomButton(
              label: 'Create Product',
              onPressed: _isLoading ? null : _createProduct,
              loading: _isLoading,
            ),
            const SizedBox(height: AppTheme.space16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.processorPrimary, size: 20),
        const SizedBox(width: AppTheme.space8),
        Text(
          title,
          style: AppTypography.headlineSmall().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceAnimalSelector() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Source Animal *',
            style: AppTypography.labelLarge(),
          ),
          const SizedBox(height: AppTheme.space8),
          if (_availableAnimals.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      'No animals available. Receive animals first.',
                      style: AppTypography.bodyMedium(),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<int>(
              value: _selectedAnimalId,
              decoration: InputDecoration(
                hintText: 'Choose an animal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              items: _availableAnimals.map((animal) {
                return DropdownMenuItem<int>(
                  value: animal.id,
                  child: Row(
                    children: [
                      Icon(
                        _getSpeciesIcon(animal.species),
                        color: AppColors.processorPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        '${animal.animalId} - ${animal.species} (${animal.liveWeight} kg)',
                        style: AppTypography.bodyMedium(),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAnimalId = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a source animal';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'e.g., Premium Beef Steak',
            prefixIcon: const Icon(Icons.label),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter product name';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _batchNumberController,
            label: 'Batch Number',
            hint: 'Auto-generated',
            prefixIcon: const Icon(Icons.qr_code),
            readOnly: true,
          ),
          const SizedBox(height: AppTheme.space16),
          DropdownButtonFormField<String>(
            value: _selectedProductType,
            decoration: InputDecoration(
              labelText: 'Product Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              prefixIcon: const Icon(Icons.category),
            ),
            items: _productTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedProductType = value!);
            },
          ),
          const SizedBox(height: AppTheme.space16),
          DropdownButtonFormField<String>(
            value: _selectedQualityGrade,
            decoration: InputDecoration(
              labelText: 'Quality Grade',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              prefixIcon: const Icon(Icons.grade),
            ),
            items: _qualityGrades.map((grade) {
              return DropdownMenuItem<String>(
                value: grade,
                child: Row(
                  children: [
                    ...List.generate(
                      _qualityGrades.indexOf(grade) + 1,
                      (index) => const Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(grade),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedQualityGrade = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _weightController,
                  label: 'Weight',
                  hint: '0.0',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedWeightUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  items: ['kg', 'lbs', 'g'].map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedWeightUnit = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          CustomTextField(
            controller: _priceController,
            label: 'Price per Unit',
            hint: '0.00',
            prefixIcon: const Icon(Icons.attach_money),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter price';
              }
              if (double.tryParse(value) == null) {
                return 'Invalid price';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomTextField(
        controller: _descriptionController,
        label: 'Description (Optional)',
        hint: 'Additional details about the product...',
        prefixIcon: const Icon(Icons.notes),
        maxLines: 4,
      ),
    );
  }

  IconData _getSpeciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cow':
      case 'cattle':
        return Icons.agriculture;
      case 'pig':
        return Icons.pets;
      case 'chicken':
        return Icons.egg;
      case 'sheep':
      case 'goat':
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }
}
