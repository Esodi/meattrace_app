import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/product_provider.dart';
import '../providers/product_category_provider.dart';
import '../providers/animal_provider.dart';
import '../models/product.dart';
import '../models/animal.dart';
import '../models/product_category.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _processingUnitController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  Animal? _selectedAnimal;
  List<ProductCategory> _selectedCategories = [];
  Map<int, TextEditingController> _weightControllers = {};
  Map<int, String> _weightUnits = {};
  bool _isSubmitting = false;
  List<Product> _createdProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<AnimalProvider>().fetchAnimals(),
      context.read<ProductCategoryProvider>().fetchCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 32.0 : 16.0;

    return Scaffold(
      appBar: createEnhancedAppBarWithBackButton(
        title: 'Create Products',
        fallbackRoute: '/processor-home',
      ),
      body: _createdProducts.isNotEmpty
          ? _buildSuccessView()
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimalDropdown(),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildCategoryMultiSelect(),
                    if (_selectedCategories.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 24 : 16),
                      _buildWeightFields(),
                    ],
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildProcessingUnitField(),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildBatchNumberField(),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildQuantityField(),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnimalDropdown() {
    return Consumer<AnimalProvider>(
      builder: (context, animalProvider, child) {
        final slaughteredAnimals = animalProvider.animals
            .where((animal) => animal.slaughtered && animal.receivedBy != null)
            .toList();

        return Semantics(
          label: 'Select a slaughtered animal for the product',
          child: DropdownButtonFormField<Animal>(
            initialValue: _selectedAnimal,
            decoration: InputDecoration(
              labelText: 'Select Received & Confirmed Animal',
              border: const OutlineInputBorder(),
              helperText: 'Choose from available received animals',
              suffixIcon: Tooltip(
                message: 'Select the animal from which products will be created. Only slaughtered animals that have been confirmed as received at your processing unit are available.',
                child: const Icon(Icons.help_outline, size: 18),
              ),
            ),
            items: slaughteredAnimals.isEmpty
                ? [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'No received animals available. Please receive animals first.',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]
                : slaughteredAnimals.map((animal) {
                    return DropdownMenuItem(
                      value: animal,
                      child: Text(
                        '${animal.species} - ${animal.animalId ?? animal.id}',
                      ),
                    );
                  }).toList(),
            onChanged: (value) => setState(() => _selectedAnimal = value),
            validator: (value) =>
                value == null ? 'Please select an animal' : null,
          ),
        );
      },
    );
  }

  Widget _buildCategoryMultiSelect() {
    return Consumer<ProductCategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Select Product Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Choose one or more product categories. For each selected category, you will specify the weight of the product created.',
                  child: const Icon(Icons.help_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryProvider.categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                        _weightControllers[category.id!] = TextEditingController();
                        _weightUnits[category.id!] = 'kg';
                      } else {
                        _selectedCategories.remove(category);
                        _weightControllers[category.id!]?.dispose();
                        _weightControllers.remove(category.id!);
                        _weightUnits.remove(category.id!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one category',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWeightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Product Weights',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Specify the weight for each selected product category. Weights must be positive numbers.',
              child: const Icon(Icons.help_outline, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._selectedCategories.map((category) {
          final controller = _weightControllers[category.id!]!;
          final unit = _weightUnits[category.id!]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Weight',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Weight is required';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null || weight <= 0) {
                              return 'Enter a valid weight';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: unit,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                        ],
                        onChanged: (value) => setState(() => _weightUnits[category.id!] = value!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProcessingUnitField() {
    return TextFormField(
      controller: _processingUnitController,
      decoration: const InputDecoration(
        labelText: 'Processing Unit',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Processing unit is required' : null,
    );
  }

  Widget _buildBatchNumberField() {
    return TextFormField(
      controller: _batchNumberController,
      decoration: const InputDecoration(
        labelText: 'Batch Number',
        border: OutlineInputBorder(),
        hintText: 'Leave empty for auto-generation',
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantity',
        border: OutlineInputBorder(),
        hintText: 'Number of products to create',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Quantity is required';
        }
        final quantity = double.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'Enter a valid quantity';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        child: _isSubmitting
            ? const LoadingIndicator()
            : const Text('Create Product'),
      ),
    );
  }

  Widget _buildSuccessView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrSize = screenWidth > 600 ? 200.0 : 150.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Products created successfully',
              child: Text(
                '${_createdProducts.length} Product${_createdProducts.length > 1 ? 's' : ''} Created Successfully!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ..._createdProducts.map((product) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'QR code for product batch ${product.batchNumber}',
                      child: QrImageView(
                        data: 'product:${product.id}:${product.batchNumber}',
                        version: QrVersions.auto,
                        size: qrSize,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Product batch number',
                      child: Text(
                        'Batch: ${product.batchNumber}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Return to previous screen',
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    print('🚀 [CreateProductScreen] Starting product creation process...');
    print('📊 [CreateProductScreen] Selected animal: ${_selectedAnimal?.species} (ID: ${_selectedAnimal?.id})');
    print('📂 [CreateProductScreen] Selected categories: ${_selectedCategories.map((c) => c.name).join(', ')}');

    setState(() => _isSubmitting = true);
    final currentContext = context;
    final provider = context.read<ProductProvider>();
    final createdProducts = <Product>[];
    final errors = <String>[];

    final baseBatchNumber = _batchNumberController.text.trim().isNotEmpty
        ? _batchNumberController.text.trim()
        : 'BATCH_${DateTime.now().millisecondsSinceEpoch}';

    print('🏷️ [CreateProductScreen] Base batch number: $baseBatchNumber');

    for (int i = 0; i < _selectedCategories.length; i++) {
      final category = _selectedCategories[i];
      final batchNumber = _selectedCategories.length > 1
          ? '${baseBatchNumber}_${i + 1}'
          : baseBatchNumber;

      print('🔄 [CreateProductScreen] Creating product ${i + 1}/${_selectedCategories.length} for category: ${category.name}');

      final product = Product(
        processingUnit: _processingUnitController.text,
        animal: _selectedAnimal!.id!,
        productType: 'meat', // Must match backend choices
        quantity: double.parse(_quantityController.text),
        createdAt: DateTime.now(),
        name: '${category.name} from ${_selectedAnimal!.species}',
        batchNumber: batchNumber,
        weight: double.parse(_weightControllers[category.id!]!.text),
        weightUnit: _weightUnits[category.id!]!,
        price: 0.0, // Default
        description: 'Product created from slaughtered animal',
        manufacturer: 'Processing Unit ${_processingUnitController.text}',
        category: category.id,
        timeline: [],
      );

      print('📦 [CreateProductScreen] Product data: ${product.toMapForCreate()}');

      try {
        final createdProduct = await provider.createProduct(product);
        if (createdProduct != null) {
          print('✅ [CreateProductScreen] Product created successfully: ${createdProduct.name} (Batch: ${createdProduct.batchNumber})');
          createdProducts.add(createdProduct);
        } else {
          final errorMsg = 'Product creation returned null for ${category.name}';
          print('❌ [CreateProductScreen] $errorMsg');
          print('🔍 [CreateProductScreen] Provider error: ${provider.error}');
          errors.add(errorMsg);
        }
      } catch (e) {
        final errorMsg = 'Exception creating product for ${category.name}: $e';
        print('💥 [CreateProductScreen] $errorMsg');
        errors.add(errorMsg);
      }
    }

    setState(() {
      _isSubmitting = false;
      _createdProducts = createdProducts;
    });

    print('📈 [CreateProductScreen] Creation summary: ${createdProducts.length} successful, ${errors.length} failed');

    if (createdProducts.isEmpty) {
      // Show detailed error message
      String errorMessage = 'Failed to create products';
      if (errors.isNotEmpty) {
        errorMessage += '\n\nErrors:\n${errors.join('\n')}';
      }
      if (provider.error != null && provider.error!.isNotEmpty) {
        errorMessage += '\n\nProvider Error: ${provider.error}';
      }

      print('🚨 [CreateProductScreen] Showing error snackbar: $errorMessage');

      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } else if (createdProducts.length < _selectedCategories.length) {
      final message = 'Created ${createdProducts.length} of ${_selectedCategories.length} products';
      print('⚠️ [CreateProductScreen] Partial success: $message');

      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('$message\n\nErrors:\n${errors.take(2).join('\n')}'),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } else {
      print('🎉 [CreateProductScreen] All products created successfully');
    }
  }

  @override
  void dispose() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    _batchNumberController.dispose();
    _processingUnitController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
