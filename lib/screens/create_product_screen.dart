import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../providers/product_category_provider.dart';
import '../providers/animal_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../models/animal.dart';
import '../models/product_category.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/enhanced_back_button.dart';
import '../services/bluetooth_printing_service.dart';
import '../utils/constants.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  Animal? _selectedAnimal;
  List<ProductCategory> _selectedCategories = [];
  Map<int, TextEditingController> _weightControllers = {};
  Map<int, String> _weightUnits = {};
  Map<int, TextEditingController> _quantityControllers = {};
  bool _isSubmitting = false;
  bool _isPrinting = false;
  List<Product> _createdProducts = [];

  // Animal selection state
  List<Animal> _availableAnimals = [];
  bool _isLoadingAnimals = false;
  String? _animalsError;

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
      context.read<ProductProvider>().fetchProducts(),
    ]);
    await _loadAvailableAnimals();
  }

  Future<void> _loadAvailableAnimals() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAnimals = true;
      _animalsError = null;
    });

    try {
      final animalProvider = context.read<AnimalProvider>();
      final productProvider = context.read<ProductProvider>();
      final authProvider = context.read<AuthProvider>();

      // Get current user's processing unit - assuming it's the user's ID for now
      // In a real implementation, this would come from user profile or separate service
      final currentUserId = authProvider.user?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get all products to check which animals have been used
      final usedAnimalIds = productProvider.products
          .map((product) => product.animal)
          .toSet();

      // Filter available animals
      final availableAnimals = animalProvider.animals.where((animal) {
        return animal.slaughtered &&
               animal.receivedBy != null &&
               animal.receivedBy == currentUserId && // Belongs to current user's processing unit
               !usedAnimalIds.contains(animal.id); // Not used for product creation
      }).toList();

      if (mounted) {
        setState(() {
          _availableAnimals = availableAnimals;
          _isLoadingAnimals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _animalsError = e.toString();
          _isLoadingAnimals = false;
        });
      }
    }
  }

  void _showAnimalSelectionDialog() async {
    final selectedAnimal = await showDialog<Animal>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Animal'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoadingAnimals
              ? const Center(child: LoadingIndicator())
              : _animalsError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading animals: $_animalsError',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _loadAvailableAnimals();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _availableAnimals.isEmpty
                      ? const Center(
                          child: Text(
                            'No available animals found.\nAnimals must be slaughtered, received at your processing unit, and not yet used for product creation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _availableAnimals.length,
                          itemBuilder: (context, index) {
                            final animal = _availableAnimals[index];
                            final isSelected = _selectedAnimal?.id == animal.id;
                            return ListTile(
                              title: Text(
                                animal.animalName != null
                                    ? '${animal.species} - ${animal.animalName}'
                                    : '${animal.species} - ${animal.animalId}',
                              ),
                              subtitle: Text(
                                'ID: ${animal.animalId} • Farm: ${animal.farmName}',
                              ),
                              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                              onTap: () => Navigator.of(context).pop(animal),
                            );
                          },
                        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedAnimal != null) {
      setState(() => _selectedAnimal = selectedAnimal);
    }
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
                    _buildAnimalSelection(),
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
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnimalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Received & Confirmed Animal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Select the animal from which products will be created. Only slaughtered animals that have been confirmed as received at your processing unit and not yet used for product creation are available.',
              child: const Icon(Icons.help_outline, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Select a slaughtered animal for the product',
          child: ElevatedButton(
            onPressed: _showAnimalSelectionDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedAnimal != null
                        ? (_selectedAnimal!.animalName != null
                            ? '${_selectedAnimal!.species} - ${_selectedAnimal!.animalName} (${_selectedAnimal!.animalId})'
                            : '${_selectedAnimal!.species} - ${_selectedAnimal!.animalId}')
                        : 'Select an animal...',
                    style: TextStyle(
                      color: _selectedAnimal != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_animalsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Error loading animals: $_animalsError',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
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
                  message: 'Choose one or more product categories. For each selected category, you will specify the quantity and weight of the product created.',
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
                        _quantityControllers[category.id!] = TextEditingController(text: '1');
                      } else {
                        _selectedCategories.remove(category);
                        _weightControllers[category.id!]?.dispose();
                        _weightControllers.remove(category.id!);
                        _weightUnits.remove(category.id!);
                        _quantityControllers[category.id!]?.dispose();
                        _quantityControllers.remove(category.id!);
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
              'Product Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Specify the quantity and weight for each selected product category. Values must be positive numbers.',
              child: const Icon(Icons.help_outline, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._selectedCategories.map((category) {
          final weightController = _weightControllers[category.id!]!;
          final quantityController = _quantityControllers[category.id!]!;
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
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Quantity is required';
                      }
                      final qty = double.tryParse(value);
                      if (qty == null || qty <= 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: weightController,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          onPressed: _isPrinting ? null : () => _printSingleProduct(product),
                          icon: const Icon(Icons.print),
                          tooltip: 'Print QR Code',
                        ),
                      ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Print all QR codes',
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _printAllProducts,
                      icon: const Icon(Icons.print),
                      label: _isPrinting
                          ? const LoadingIndicator()
                          : const Text('Print All'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Return to processing unit dashboard',
                    child: ElevatedButton(
                      onPressed: () => context.go('/processor-home'),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
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
        quantity: double.parse(_quantityControllers[category.id!]!.text),
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

  Future<void> _printSingleProduct(Product product) async {
    await _showPrinterSelectionDialog(product: product);
  }

  Future<void> _printAllProducts() async {
    await _showPrinterSelectionDialog(products: _createdProducts);
  }

  Future<void> _showPrinterSelectionDialog({Product? product, List<Product>? products}) async {
    final printingService = BluetoothPrintingService();

    // Request permissions
    final hasPermissions = await printingService.requestPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required for printing')),
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      // Scan for printers
      final printers = await printingService.scanPrinters();

      if (!mounted) return;

      if (printers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Bluetooth printers found')),
        );
        return;
      }

      // Show printer selection dialog
      final selectedPrinter = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Printer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final printer = printers[index];
                return ListTile(
                  title: Text(printer.platformName ?? 'Unknown Printer'),
                  onTap: () => Navigator.of(context).pop(printer),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedPrinter == null) return;

      // Connect to printer with retry logic
      final connected = await printingService.connectToPrinter(selectedPrinter, maxRetries: 3);
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to printer after multiple attempts')),
        );
        return;
      }

      // Print
      if (product != null) {
        final qrData = '${Constants.baseUrl}/product-info/view/${product.id}';
        await printingService.printQRCode(
          qrData,
          product.name,
          product.batchNumber,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printed QR code for ${product.name}')),
        );
      } else if (products != null) {
        for (final prod in products) {
          final qrData = '${Constants.baseUrl}/product-info/view/${prod.id}';
          await printingService.printQRCode(
            qrData,
            prod.name,
            prod.batchNumber,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printed ${products.length} QR codes')),
        );
      }

      // Disconnect
      await printingService.disconnect();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _batchNumberController.dispose();
    _processingUnitController.dispose();
    super.dispose();
  }
}








