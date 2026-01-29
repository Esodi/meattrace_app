import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:meattrace_app/providers/product_provider.dart';
import 'package:meattrace_app/providers/product_category_provider.dart';
import 'package:meattrace_app/providers/animal_provider.dart';
import 'package:meattrace_app/providers/auth_provider.dart';
import 'package:meattrace_app/models/product.dart';
import 'package:meattrace_app/models/animal.dart';
import 'package:meattrace_app/models/product_category.dart';
import 'package:meattrace_app/widgets/core/custom_app_bar.dart';
import 'package:meattrace_app/widgets/core/enhanced_back_button.dart';
import 'package:meattrace_app/models/external_vendor.dart';
import 'package:meattrace_app/providers/external_vendor_provider.dart';
import 'package:meattrace_app/screens/common/external_vendors_screen.dart';
import 'package:meattrace_app/screens/common/initial_inventory_onboarding.dart';
import 'package:meattrace_app/services/bluetooth_printing_service.dart';
import 'package:meattrace_app/utils/constants.dart';
import 'package:meattrace_app/utils/app_colors.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:meattrace_app/widgets/processing_pipeline.dart';
import 'package:meattrace_app/services/bluetooth_scale_service.dart';
import 'package:meattrace_app/widgets/dialogs/scale_connection_dialog.dart';
import 'package:meattrace_app/widgets/bluetooth_weight_display.dart';

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
  final List<ProductCategory> _selectedCategories = [];
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, String> _weightUnits = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  bool _isSubmitting = false;
  bool _isPrinting = false;
  List<Product> _createdProducts = [];

  // Processing pipeline state
  late PipelineManager _pipelineManager;
  late List<PipelineStage> _pipelineStages;

  // Animal selection state
  List<Animal> _availableAnimals = [];
  List<SlaughterPart> _availableSlaughterParts = [];
  bool _isLoadingAnimals = false;
  String? _animalsError;

  // Selection mode: 'animal', 'part', or 'external'
  String _selectionMode = 'animal';
  SlaughterPart? _selectedPart;

  // External Vendor State
  bool _isExternalSource = false;
  ExternalVendor? _selectedVendor;
  final _externalPriceController = TextEditingController();
  final _externalWeightController = TextEditingController();

  // Bluetooth Scale
  final BluetoothScaleService _scaleService = BluetoothScaleService();
  StreamSubscription? _weightSubscription;
  bool _isScaleConnected = false;

  @override
  void initState() {
    super.initState();

    // Initialize pipeline stages
    _initializePipeline();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<ExternalVendorProvider>().fetchVendors();
      // Auto-fill processing unit field with the name of the logged-in processing unit
      final authProvider = context.read<AuthProvider>();
      final processingUnitName = authProvider.user?.processingUnitName ?? '';

      print(
        '🏭 [CREATE_PRODUCT] Processing Unit Name from AuthProvider: "$processingUnitName"',
      );
      print(
        '🏭 [CREATE_PRODUCT] Processing Unit ID: ${authProvider.user?.processingUnitId}',
      );
      print('🏭 [CREATE_PRODUCT] User Role: ${authProvider.user?.role}');

      _processingUnitController.text = processingUnitName;

      if (processingUnitName.isEmpty) {
        print('⚠️  [CREATE_PRODUCT] WARNING: Processing unit name is empty!');
        print(
          '⚠️  [CREATE_PRODUCT] This may indicate the user profile is not fully loaded.',
        );
      }

      await _loadData();
    });
  }

  void _initializePipeline() {
    _pipelineStages = [
      PipelineStage(
        id: 'validation',
        name: 'Form Validation',
        description: 'Validating product creation form and inputs',
      ),
      PipelineStage(
        id: 'preparation',
        name: 'Data Preparation',
        description: 'Preparing product data for submission',
      ),
      PipelineStage(
        id: 'submission',
        name: 'Product Creation',
        description: 'Creating products in the backend system',
      ),
      PipelineStage(
        id: 'completion',
        name: 'Process Completion',
        description: 'Finalizing and displaying results',
      ),
    ];

    _pipelineManager = PipelineManager(
      initialStages: _pipelineStages,
      config: PipelineConfig.adaptive(),
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final procUnitId = authProvider.user?.processingUnitId;
    await Future.wait([
      context.read<AnimalProvider>().fetchAnimals(),
      context.read<ProductCategoryProvider>().fetchCategories(),
      context.read<ProductProvider>().fetchProducts(
        processingUnitId: procUnitId,
      ),
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
      print(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );
      print(
        '🔍 [CREATE_PRODUCT] Loading available animals and slaughter parts...',
      );
      print(
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      );

      final animalProvider = context.read<AnimalProvider>();
      final productProvider = context.read<ProductProvider>();
      final authProvider = context.read<AuthProvider>();

      final currentUserId = authProvider.user?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('👤 [CREATE_PRODUCT] Current user ID: $currentUserId');
      print(
        '📦 [CREATE_PRODUCT] Total animals in provider: ${animalProvider.animals.length}',
      );

      print(
        '🏭 [CREATE_PRODUCT] Total products: ${productProvider.products.length}',
      );

      // Filter available whole animals (received and has remaining weight)
      // Note: We don't check if animal was "used" - we only check remaining_weight
      // This allows creating multiple products from the same animal until weight is depleted
      final availableAnimals = animalProvider.animals.where((animal) {
        final isSlaughtered = animal.slaughtered;
        final hasReceivedBy = animal.receivedBy != null;
        final matchesUser = animal.receivedBy == currentUserId;
        final hasRemainingWeight =
            animal.remainingWeight != null && animal.remainingWeight! > 0;

        final isAvailable =
            isSlaughtered && hasReceivedBy && matchesUser && hasRemainingWeight;

        if (animal.transferredTo != null || animal.receivedBy != null) {
          print('  🐄 Animal ${animal.animalId}:');
          print('     - slaughtered: $isSlaughtered');
          print(
            '     - received_by: ${animal.receivedBy} (matches user: $matchesUser)',
          );
          print('     - remaining_weight: ${animal.remainingWeight}');
          print('     - AVAILABLE: $isAvailable');
        }

        return isAvailable;
      }).toList();

      print(
        '✨ [CREATE_PRODUCT] Found ${availableAnimals.length} available whole animals',
      );

      // Load slaughter parts
      print('🔍 [CREATE_PRODUCT] Fetching slaughter parts...');
      final allSlaughterParts = await animalProvider.getSlaughterPartsList();

      // Filter slaughter parts for current user and has remaining weight
      // Note: We don't check usedInProduct - we only check remaining_weight
      // This allows creating multiple products from the same part until weight is depleted
      final availableSlaughterParts = allSlaughterParts.where((part) {
        final isReceived = part.receivedBy != null;
        final matchesUser = part.receivedBy == currentUserId;
        final hasRemainingWeight =
            part.remainingWeight != null && part.remainingWeight! > 0;

        final isAvailable = isReceived && matchesUser && hasRemainingWeight;

        if (part.receivedBy != null) {
          print('  🥩 Part ${part.id} (${part.partType.displayName}):');
          print(
            '     - received_by: ${part.receivedBy} (matches user: $matchesUser)',
          );
          print('     - remaining_weight: ${part.remainingWeight}');
          print('     - AVAILABLE: $isAvailable');
        }

        return isAvailable;
      }).toList();

      print(
        '🥩 [CREATE_PRODUCT] Found ${availableSlaughterParts.length} available slaughter parts',
      );
      for (var part in availableSlaughterParts) {
        print(
          '   ✅ Part ID ${part.id}: ${part.partType.displayName} from Animal ${part.animalId}',
        );
      }

      if (availableAnimals.isEmpty && availableSlaughterParts.isEmpty) {
        print('⚠️  [CREATE_PRODUCT] NO ANIMALS OR PARTS AVAILABLE!');
        print('   Possible reasons:');
        print(
          '   1. No animals/parts have been RECEIVED yet (only transferred)',
        );
        print(
          '   2. All received animals/parts have remaining_weight = 0 (fully used)',
        );
        print('   3. Animals/parts received by different user');
      }

      if (mounted) {
        setState(() {
          _availableAnimals = availableAnimals;
          _availableSlaughterParts = availableSlaughterParts;
          _isLoadingAnimals = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ [CREATE_PRODUCT] Error loading animals/parts: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _animalsError = e.toString();
          _isLoadingAnimals = false;
        });
      }
    }
  }

  void _showAnimalSelectionDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Animal or Part'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Toggle between animals and parts
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'animal',
                      label: Text('Whole Animals'),
                      icon: Icon(Icons.pets),
                    ),
                    ButtonSegment(
                      value: 'part',
                      label: Text('Slaughter Parts'),
                      icon: Icon(Icons.clear_all),
                    ),
                  ],
                  selected: {_selectionMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      _selectionMode = newSelection.first;
                    });
                    setState(() {
                      _selectionMode = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // List of items
                Expanded(
                  child: _isLoadingAnimals
                      ? const Center(child: CircularProgressIndicator())
                      : _animalsError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading: $_animalsError',
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
                      : _selectionMode == 'animal'
                      ? _buildAnimalsList()
                      : _buildSlaughterPartsList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['type'] == 'animal') {
          _selectedAnimal = result['data'] as Animal;
          _selectedPart = null;
          _selectionMode = 'animal';
        } else {
          _selectedPart = result['data'] as SlaughterPart;
          _selectedAnimal = null;
          _selectionMode = 'part';
        }
      });
    }
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    _processingUnitController.dispose();
    _batchNumberController.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    _externalPriceController.dispose();
    _externalWeightController.dispose();
    super.dispose();
  }

  Future<void> _connectScale() async {
    if (_scaleService.isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scale already connected')));
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => const ScaleConnectionDialog(),
    );

    if (result == true) {
      setState(() {
        _isScaleConnected = true;
      });

      _weightSubscription?.cancel();
      _weightSubscription = _scaleService.weightStream.listen((weight) {
        print('Scale weight: $weight');
      });
    }
  }

  void _readWeightFromScale(TextEditingController controller) {
    if (!_scaleService.isConnected) {
      _connectScale();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading from scale...'),
        duration: Duration(milliseconds: 500),
      ),
    );

    StreamSubscription? singleRead;
    singleRead = _scaleService.weightStream.listen((weight) {
      setState(() {
        controller.text = weight.toStringAsFixed(2);
      });
      singleRead?.cancel();
    });

    Future.delayed(const Duration(seconds: 2), () {
      singleRead?.cancel();
    });
  }

  Widget _buildAnimalsList() {
    if (_availableAnimals.isEmpty) {
      return const Center(
        child: Text(
          'No whole animals available.\n\nAnimals must be:\n• Slaughtered\n• Received at your processing unit\n• Not yet used for product creation\n• Have remaining weight available',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _availableAnimals.length,
      itemBuilder: (context, index) {
        final animal = _availableAnimals[index];
        final isSelected = _selectedAnimal?.id == animal.id;
        final remainingWeight =
            animal.remainingWeight ?? animal.liveWeight ?? 0.0;

        return ListTile(
          leading: const Icon(Icons.pets),
          title: Text(
            animal.animalName != null
                ? '${animal.species} - ${animal.animalName}'
                : '${animal.species} - ${animal.animalId}',
          ),
          subtitle: Text(
            'ID: ${animal.animalId} • Abbatoir: ${animal.abbatoirName}\nRemaining: ${remainingWeight.toStringAsFixed(2)} kg',
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () =>
              Navigator.of(context).pop({'type': 'animal', 'data': animal}),
        );
      },
    );
  }

  Widget _buildSlaughterPartsList() {
    if (_availableSlaughterParts.isEmpty) {
      return const Center(
        child: Text(
          'No slaughter parts available.\n\nParts must be:\n• From a slaughtered animal\n• Received at your processing unit\n• Not yet used for product creation\n• Have remaining weight available',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _availableSlaughterParts.length,
      itemBuilder: (context, index) {
        final part = _availableSlaughterParts[index];
        final isSelected = _selectedPart?.id == part.id;
        final remainingWeight = part.remainingWeight ?? part.weight;

        return ListTile(
          leading: const Icon(Icons.clear_all),
          title: Text(part.partType.displayName),
          subtitle: Text(
            'Total: ${part.weight} ${part.weightUnit} • Remaining: ${remainingWeight.toStringAsFixed(2)} ${part.weightUnit}\nOrigin Animal: ${part.animalId}',
            style: const TextStyle(fontSize: 13),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () =>
              Navigator.of(context).pop({'type': 'part', 'data': part}),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 32.0 : 16.0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Products',
        leading: EnhancedBackButton(fallbackRoute: '/processor-home'),
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
                    // Show pipeline when submitting
                    if (_isSubmitting) ...[
                      SizedBox(height: isTablet ? 24 : 16),
                      ProcessingPipeline(
                        stages: _pipelineManager.stages,
                        config: _pipelineManager.config,
                        onRetry: _retryFailedStages,
                        onCancel: _cancelSubmission,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnimalSelection() {
    String selectionText;
    if (_isExternalSource) {
      selectionText = _selectedVendor != null
          ? 'External: ${_selectedVendor!.name}'
          : 'Select External Vendor...';
    } else if (_selectedAnimal != null) {
      selectionText = _selectedAnimal!.animalName != null
          ? '${_selectedAnimal!.species} - ${_selectedAnimal!.animalName} (${_selectedAnimal!.animalId})'
          : '${_selectedAnimal!.species} - ${_selectedAnimal!.animalId}';
    } else if (_selectedPart != null) {
      selectionText =
          '${_selectedPart!.partType.displayName} (${_selectedPart!.weight} ${_selectedPart!.weightUnit}) - Origin Animal: ${_selectedPart!.animalId}';
    } else {
      selectionText = 'Select an animal or slaughter part...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Received Animal/Part',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Select a whole animal or slaughter part that has been confirmed as received at your processing unit. Only items not yet used for product creation are available.',
              child: const Icon(Icons.help_outline, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Source Toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Internal Stock'),
              icon: Icon(Icons.warehouse),
            ),
            ButtonSegment(
              value: true,
              label: Text('External Vendor'),
              icon: Icon(Icons.local_shipping),
            ),
          ],
          selected: {_isExternalSource},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isExternalSource = newSelection.first;
              if (_isExternalSource) {
                _selectionMode = 'external';
                _selectedAnimal = null;
                _selectedPart = null;
              } else {
                _selectionMode = 'animal';
                _selectedVendor = null;
              }
            });
          },
        ),
        const SizedBox(height: 16),

        if (_isExternalSource) ...[
          Row(
            children: [
              Expanded(
                child: Consumer<ExternalVendorProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<ExternalVendor>(
                      initialValue: _selectedVendor,
                      decoration: const InputDecoration(
                        labelText: 'Select Vendor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: provider.vendors.map((vendor) {
                        return DropdownMenuItem(
                          value: vendor,
                          child: Text(vendor.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVendor = value;
                        });
                      },
                      validator: (value) => _isExternalSource && value == null
                          ? 'Required'
                          : null,
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExternalVendorsScreen(),
                    ),
                  ).then((_) {
                    context.read<ExternalVendorProvider>().fetchVendors();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _externalPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Acquisition Price (Total)',
              border: OutlineInputBorder(),
              prefixText: 'TZS ',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _externalWeightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Available Weight / Total Quantity',
              border: OutlineInputBorder(),
              suffixText: 'kg',
              prefixIcon: Icon(Icons.scale),
            ),
            validator: (value) =>
                _isExternalSource && (value == null || value.isEmpty)
                ? 'Required'
                : null,
          ),
        ] else
          Semantics(
            label: 'Select a slaughtered animal or part for the product',
            child: ElevatedButton(
              onPressed: _showAnimalSelectionDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectionText,
                      style: TextStyle(
                        color:
                            (_selectedAnimal != null || _selectedPart != null)
                            ? Colors.black
                            : Colors.grey,
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
              'Error loading: $_animalsError',
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
                  message:
                      'Choose one or more product categories. For each selected category, you will specify the quantity and weight of the product created.',
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
                        if (category.id != null) {
                          _weightControllers[category.id!] =
                              TextEditingController();
                          _weightUnits[category.id!] = 'kg';
                          _quantityControllers[category.id!] =
                              TextEditingController(text: '1');
                          _priceControllers[category.id!] =
                              TextEditingController();
                        }
                      } else {
                        _selectedCategories.remove(category);
                        if (category.id != null) {
                          _weightControllers[category.id!]?.dispose();
                          _weightControllers.remove(category.id!);
                          _weightUnits.remove(category.id!);
                          _quantityControllers[category.id!]?.dispose();
                          _quantityControllers.remove(category.id!);
                          _priceControllers[category.id!]?.dispose();
                          _priceControllers.remove(category.id!);
                        }
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

  /// Convert weight to kilograms for consistent comparison
  double _convertToKg(double weight, String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return weight;
      case 'g':
        return weight / 1000.0;
      case 'lbs':
        return weight * 0.453592;
      default:
        return weight; // Default to kg if unknown
    }
  }

  /// Convert weight from kilograms to target unit
  double _convertFromKg(double weightInKg, String targetUnit) {
    switch (targetUnit.toLowerCase()) {
      case 'kg':
        return weightInKg;
      case 'g':
        return weightInKg * 1000.0;
      case 'lbs':
        return weightInKg / 0.453592;
      default:
        return weightInKg; // Default to kg if unknown
    }
  }

  Widget _buildWeightFields() {
    // Calculate available weight for validation (always in kg)
    final double maxAvailableWeight = _isExternalSource
        ? (double.tryParse(_externalWeightController.text) ?? 1000000.0)
        : _selectedAnimal != null
        ? (_selectedAnimal!.remainingWeight ??
              _selectedAnimal!.liveWeight ??
              0.0)
        : _selectedPart != null
        ? (_selectedPart!.remainingWeight ?? _selectedPart!.weight)
        : 0.0;

    print(
      '🔍 [CreateProductScreen] Max available weight: $maxAvailableWeight kg',
    );

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
              message:
                  'Specify the quantity and weight for each selected product category. Total weight cannot exceed ${maxAvailableWeight.toStringAsFixed(2)} kg.',
              child: const Icon(Icons.help_outline, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available weight: ${maxAvailableWeight.toStringAsFixed(2)} kg',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._selectedCategories.map((category) {
          if (category.id == null) return const SizedBox.shrink();
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                  // Bluetooth Weight Display
                  BluetoothWeightDisplay(
                    label: 'Product Weight',
                    weight: double.tryParse(weightController.text),
                    isConnected: _isScaleConnected,
                    unit: unit,
                    themeColor: AppColors.processorPrimary,
                    onTap: () async {
                      if (!_scaleService.isConnected) {
                        await _connectScale();
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reading from scale...'),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      bool gotWeight = false;
                      try {
                        await _scaleService.readWeight();
                      } catch (e) {
                        print('Error reading scale: $e');
                      }

                      StreamSubscription? singleRead;
                      singleRead = _scaleService.weightStream.listen((weight) {
                        if (!gotWeight) {
                          gotWeight = true;
                          setState(() {
                            weightController.text = weight.toStringAsFixed(2);
                          });

                          // Validate against max weight
                          final weightInKg = _convertToKg(weight, unit);
                          if (weightInKg > maxAvailableWeight) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Warning: Weight exceeds available amount (${maxAvailableWeight.toStringAsFixed(2)} kg)',
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Weight recorded: ${weight.toStringAsFixed(2)} $unit',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }

                          singleRead?.cancel();
                        }
                      });

                      // Timeout
                      Future.delayed(const Duration(seconds: 5), () {
                        if (!gotWeight) {
                          singleRead?.cancel();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Price Field
                  TextFormField(
                    controller: _priceControllers[category.id!],
                    decoration: const InputDecoration(
                      labelText: 'Price (TZS)',
                      border: OutlineInputBorder(),
                      prefixText: 'TZS ',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Enter a valid price';
                        }
                      }
                      return null;
                    },
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
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Processing Unit',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.factory),
        helperText: 'Auto-filled with your processing unit',
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
            ? const CircularProgressIndicator()
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ..._createdProducts.map(
              (product) => Card(
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isPrinting
                                ? null
                                : () => _printSingleProduct(product),
                            icon: const Icon(Icons.print),
                            tooltip: 'Print QR Code',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label:
                            'QR code for product batch ${product.batchNumber}',
                        child: QrImageView(
                          data:
                              '${Constants.baseUrl}/product-info/view/${product.id}/',
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
              ),
            ),
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
                          ? const CircularProgressIndicator()
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

    // Check if an animal or part or external vendor is selected
    if (!_isExternalSource &&
        _selectedAnimal == null &&
        _selectedPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an animal or slaughter part'),
        ),
      );
      return;
    }

    if (_isExternalSource && _selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an external vendor')),
      );
      return;
    }

    // Reset pipeline and start submission
    _pipelineManager.reset();
    _pipelineManager.startStage('validation');

    // Get the animal ID (either from selected animal or from the part's animal)
    final animalId = _isExternalSource
        ? 0
        : (_selectedAnimal?.id ?? _selectedPart!.animalId);
    final sourceName = _isExternalSource
        ? 'External Vendor (${_selectedVendor?.name})'
        : (_selectedAnimal != null
              ? '${_selectedAnimal!.species} (${_selectedAnimal!.animalId})'
              : '${_selectedPart!.partType.displayName} from Animal ${_selectedPart!.animalId}');

    print('🚀 [CreateProductScreen] Starting product creation process...');
    print('📊 [CreateProductScreen] Source: $sourceName');
    print('📊 [CreateProductScreen] Animal ID: $animalId');
    print(
      '📂 [CreateProductScreen] Selected categories: ${_selectedCategories.map((c) => c.name).join(', ')}',
    );

    setState(() => _isSubmitting = true);
    final currentContext = context;
    final provider = context.read<ProductProvider>();
    final createdProducts = <Product>[];
    final errors = <String>[];

    final baseBatchNumber = _batchNumberController.text.trim().isNotEmpty
        ? _batchNumberController.text.trim()
        : 'BATCH_${DateTime.now().millisecondsSinceEpoch}';

    print('🏷️ [CreateProductScreen] Base batch number: $baseBatchNumber');

    // Get processing unit info from AuthProvider
    final authProvider = context.read<AuthProvider>();
    final processingUnitName =
        authProvider.user?.processingUnitName ?? _processingUnitController.text;
    final processingUnitId =
        authProvider.user?.processingUnitId?.toString() ??
        _processingUnitController.text;

    try {
      // Validation stage complete
      _pipelineManager.completeStage('validation');
      _pipelineManager.startStage('preparation');

      // Simulate preparation progress
      for (double progress = 0.0; progress <= 1.0; progress += 0.2) {
        await Future.delayed(const Duration(milliseconds: 100));
        _pipelineManager.updateProgress('preparation', progress);
      }

      _pipelineManager.completeStage('preparation');
      _pipelineManager.startStage('submission');

      for (int i = 0; i < _selectedCategories.length; i++) {
        final category = _selectedCategories[i];
        final batchNumber = _selectedCategories.length > 1
            ? '${baseBatchNumber}_${i + 1}'
            : baseBatchNumber;

        // Update progress for current product
        final progress = (i + 1) / _selectedCategories.length;
        _pipelineManager.updateProgress('submission', progress);

        print(
          '🔄 [CreateProductScreen] Creating product ${i + 1}/${_selectedCategories.length} for category: ${category.name}',
        );

        final productName = _isExternalSource
            ? '${category.name} from ${_selectedVendor?.name}'
            : (_selectedAnimal != null
                  ? '${category.name} from ${_selectedAnimal!.species}'
                  : '${category.name} from ${_selectedPart!.partType.displayName}');

        final product = Product(
          animal: animalId,
          slaughterPartId: _isExternalSource ? null : _selectedPart?.id,
          productType: 'meat', // Must match backend choices
          createdAt: DateTime.now(),
          name: productName,
          weight: double.parse(_weightControllers[category.id!]!.text),
          weightUnit: _weightUnits[category.id!]!,
          quantity: double.parse(_quantityControllers[category.id!]!.text),
          batchNumber: batchNumber,
          price:
              double.tryParse(_priceControllers[category.id!]?.text ?? '0') ??
              0.0,
          description: _isExternalSource
              ? 'External acquisition from ${_selectedVendor?.name}'
              : (_selectedAnimal != null
                    ? 'Product created from slaughtered animal'
                    : 'Product created from slaughter part: ${_selectedPart!.partType.displayName}'),
          manufacturer: 'Processing Unit $processingUnitName',
          processingUnit: int.tryParse(processingUnitId) ?? 0,
          timeline: [],
          id: null, // Will be set by backend
          isExternal: _isExternalSource,
          externalVendorId: _selectedVendor?.id,
          externalVendorName: _selectedVendor?.name,
          acquisitionPrice: _isExternalSource
              ? double.tryParse(_externalPriceController.text)
              : null,
          remainingWeight: _isExternalSource
              ? double.tryParse(_weightControllers[category.id!]!.text)
              : null,
        );

        print(
          '📦 [CreateProductScreen] Product data: ${product.toMapForCreate()}',
        );

        try {
          final createdProduct = await provider.createProduct(product);
          if (createdProduct != null) {
            print(
              '✅ [CreateProductScreen] Product created successfully: ${createdProduct.name} (Batch: ${createdProduct.batchNumber})',
            );
            createdProducts.add(createdProduct);
          } else {
            final errorMsg =
                'Product creation returned null for ${category.name}';
            print('❌ [CreateProductScreen] $errorMsg');
            print('🔍 [CreateProductScreen] Provider error: ${provider.error}');
            errors.add(errorMsg);
          }
        } catch (e) {
          final errorMsg =
              'Exception creating product for ${category.name}: $e';
          print('💥 [CreateProductScreen] $errorMsg');
          errors.add(errorMsg);
        }
      }

      _pipelineManager.completeStage('submission');
      _pipelineManager.startStage('completion');

      // Simulate completion progress
      for (double progress = 0.0; progress <= 1.0; progress += 0.5) {
        await Future.delayed(const Duration(milliseconds: 50));
        _pipelineManager.updateProgress('completion', progress);
      }

      _pipelineManager.completeStage('completion');

      // Reload available animals and parts to reflect updated weights
      print(
        '🔄 [CreateProductScreen] Reloading available animals/parts after product creation...',
      );
      await _loadAvailableAnimals();
      print('✅ [CreateProductScreen] Available list reloaded');

      // Clear selection to allow creating more products
      _selectedAnimal = null;
      _selectedPart = null;
    } catch (e) {
      print('💥 [CreateProductScreen] Pipeline error: $e');
      _pipelineManager.failStage(
        'submission',
        'Unexpected error during processing: $e',
      );
    }

    setState(() {
      _isSubmitting = false;
      _createdProducts = createdProducts;
    });

    print(
      '📈 [CreateProductScreen] Creation summary: ${createdProducts.length} successful, ${errors.length} failed',
    );

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
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } else if (createdProducts.length < _selectedCategories.length) {
      final message =
          'Created ${createdProducts.length} of ${_selectedCategories.length} products';
      print('⚠️ [CreateProductScreen] Partial success: $message');

      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('$message\n\nErrors:\n${errors.take(2).join('\n')}'),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          currentContext,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } else {
      print('🎉 [CreateProductScreen] All products created successfully');
    }
  }

  void _retryFailedStages() {
    // Reset failed stages and retry submission
    _pipelineManager.reset();
    _submitForm();
  }

  void _cancelSubmission() {
    // Cancel the current submission
    setState(() => _isSubmitting = false);
    _pipelineManager.cancelStage('submission');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product creation cancelled')));
  }

  Future<void> _printSingleProduct(Product product) async {
    await _showPrinterSelectionDialog(product: product);
  }

  Future<void> _printAllProducts() async {
    await _showPrinterSelectionDialog(products: _createdProducts);
  }

  Future<void> _showPrinterSelectionDialog({
    Product? product,
    List<Product>? products,
  }) async {
    if (!mounted) return;

    setState(() => _isPrinting = true);

    try {
      final printingService = BluetoothPrintingService();

      // Request permissions
      print('🔐 [CreateProductScreen] Requesting Bluetooth permissions...');
      final hasPermissions = await printingService.requestPermissions();
      if (!hasPermissions) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required for printing'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      print('✅ [CreateProductScreen] Permissions granted');

      // Scan for printers
      print('🔍 [CreateProductScreen] Scanning for printers...');
      final printers = await printingService.scanPrinters();
      print('📱 [CreateProductScreen] Found ${printers.length} printers');

      if (!mounted) return;

      if (printers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No Bluetooth printers found. Make sure your printer is turned on and in pairing mode.',
            ),
            duration: Duration(seconds: 5),
          ),
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
                  leading: const Icon(Icons.print),
                  title: Text(
                    printer.platformName.isNotEmpty
                        ? printer.platformName
                        : 'Unknown Printer',
                  ),
                  subtitle: Text(printer.remoteId.toString()),
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

      if (!mounted) return;
      if (selectedPrinter == null) {
        print('❌ [CreateProductScreen] No printer selected');
        return;
      }

      print(
        '🔗 [CreateProductScreen] Connecting to printer: ${selectedPrinter.platformName}',
      );

      // Show connecting dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting to printer...'),
              ],
            ),
          ),
        );
      }

      // Connect to printer with retry logic
      bool connected = false;
      try {
        connected = await printingService.connectToPrinter(
          selectedPrinter,
          maxRetries: 3,
        );
      } catch (e) {
        print('❌ [CreateProductScreen] Connection error: $e');
        connected = false;
      }

      // Close connecting dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!connected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to printer. Please try again.'),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      print('✅ [CreateProductScreen] Connected successfully');

      // Print
      if (product != null) {
        print(
          '🖨️ [CreateProductScreen] Printing single product: ${product.name}',
        );
        final qrData = '${Constants.baseUrl}/product-info/view/${product.id}/';
        print('📊 [CreateProductScreen] QR Data: $qrData');

        await printingService.printQRCode(
          qrData,
          product.name,
          product.batchNumber,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Printed QR code for ${product.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        print('✅ [CreateProductScreen] Print completed for ${product.name}');
      } else if (products != null && products.isNotEmpty) {
        print('🖨️ [CreateProductScreen] Printing ${products.length} products');
        int successCount = 0;

        for (int i = 0; i < products.length; i++) {
          final prod = products[i];
          try {
            print(
              '🖨️ [CreateProductScreen] Printing ${i + 1}/${products.length}: ${prod.name}',
            );
            final qrData = '${Constants.baseUrl}/product-info/view/${prod.id}/';

            await printingService.printQRCode(
              qrData,
              prod.name,
              prod.batchNumber,
            );
            successCount++;
            print(
              '✅ [CreateProductScreen] Printed ${i + 1}/${products.length}',
            );

            // Small delay between prints
            if (i < products.length - 1) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } catch (e) {
            print('❌ [CreateProductScreen] Failed to print ${prod.name}: $e');
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Printed $successCount of ${products.length} QR codes',
            ),
            backgroundColor: successCount == products.length
                ? Colors.green
                : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        print(
          '✅ [CreateProductScreen] Batch print completed: $successCount/${products.length}',
        );
      }

      // Disconnect
      print('🔌 [CreateProductScreen] Disconnecting from printer...');
      await printingService.disconnect();
      print('✅ [CreateProductScreen] Disconnected successfully');
    } catch (e) {
      print('💥 [CreateProductScreen] Printing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
      print('🏁 [CreateProductScreen] Printing process completed');
    }
  }
}
