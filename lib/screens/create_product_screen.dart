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

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _processingUnitController =
      TextEditingController();

  Animal? _selectedAnimal;
  ProductCategory? _selectedCategory;
  String _weightUnit = 'kg';
  bool _isSubmitting = false;
  Product? _createdProduct;

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
      appBar: AppBar(title: const Text('Create Product')),
      body: _createdProduct != null
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
                    _buildCategoryDropdown(),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildWeightField(),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildProcessingUnitField(),
                    SizedBox(height: isTablet ? 24 : 16),
                    _buildBatchNumberField(),
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
            .where((animal) => animal.slaughtered)
            .toList();

        return Semantics(
          label: 'Select a slaughtered animal for the product',
          child: DropdownButtonFormField<Animal>(
            initialValue: _selectedAnimal,
            decoration: const InputDecoration(
              labelText: 'Select Slaughtered Animal',
              border: OutlineInputBorder(),
              helperText: 'Choose from available slaughtered animals',
            ),
            items: slaughteredAnimals.map((animal) {
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

  Widget _buildCategoryDropdown() {
    return Consumer<ProductCategoryProvider>(
      builder: (context, categoryProvider, child) {
        return DropdownButtonFormField<ProductCategory>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Select Product Category',
            border: OutlineInputBorder(),
          ),
          items: categoryProvider.categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (value) =>
              value == null ? 'Please select a category' : null,
        );
      },
    );
  }

  Widget _buildWeightField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight',
              border: OutlineInputBorder(),
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
          value: _weightUnit,
          items: const [
            DropdownMenuItem(value: 'kg', child: Text('kg')),
            DropdownMenuItem(value: 'g', child: Text('g')),
            DropdownMenuItem(value: 'lbs', child: Text('lbs')),
          ],
          onChanged: (value) => setState(() => _weightUnit = value!),
        ),
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
    final qrSize = screenWidth > 600 ? 300.0 : 200.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Product created successfully',
              child: const Text(
                'Product Created Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label:
                  'QR code for product batch ${_createdProduct!.batchNumber}',
              child: QrImageView(
                data:
                    'product:${_createdProduct!.id}:${_createdProduct!.batchNumber}',
                version: QrVersions.auto,
                size: qrSize,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: 'Product batch number',
              child: Text(
                'Batch: ${_createdProduct!.batchNumber}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
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

    setState(() => _isSubmitting = true);
    final currentContext = context;
    final provider = context.read<ProductProvider>();

    final batchNumber = _batchNumberController.text.trim().isNotEmpty
        ? _batchNumberController.text.trim()
        : 'BATCH_${DateTime.now().millisecondsSinceEpoch}';

    final product = Product(
      processingUnit: int.tryParse(_processingUnitController.text) ?? 1,
      animal: _selectedAnimal!.id!,
      productType: 'Meat Product', // Default
      quantity: 1.0, // Default
      createdAt: DateTime.now(),
      name: 'Product from ${_selectedAnimal!.species}',
      batchNumber: batchNumber,
      weight: double.parse(_weightController.text),
      weightUnit: _weightUnit,
      price: 0.0, // Default
      description: 'Product created from slaughtered animal',
      manufacturer: 'Processing Unit ${_processingUnitController.text}',
      category: _selectedCategory!.id,
      timeline: [],
    );

    final createdProduct = await provider.createProduct(product);

    setState(() {
      _isSubmitting = false;
      _createdProduct = createdProduct;
    });

    if (createdProduct == null) {
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(const SnackBar(content: Text('Failed to create product')));
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _batchNumberController.dispose();
    _processingUnitController.dispose();
    super.dispose();
  }
}
