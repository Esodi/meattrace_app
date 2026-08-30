import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:meattrace_app/providers/product_provider.dart';
import 'package:meattrace_app/providers/product_category_provider.dart';
import 'package:meattrace_app/providers/auth_provider.dart';
import 'package:meattrace_app/models/product.dart';
import 'package:meattrace_app/models/animal.dart';
import 'package:meattrace_app/models/product_category.dart';
import 'package:meattrace_app/services/animal_service.dart';
import 'package:meattrace_app/widgets/core/custom_app_bar.dart';
import 'package:meattrace_app/widgets/core/enhanced_back_button.dart';
import 'package:meattrace_app/models/external_vendor.dart';
import 'package:meattrace_app/providers/external_vendor_provider.dart';
import 'package:meattrace_app/screens/common/external_vendors_screen.dart';
import 'package:meattrace_app/services/bluetooth_printing_service.dart';
import 'package:meattrace_app/widgets/printer/bluetooth_permission_dialog.dart';
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
  static const int _sourcePageSize = 20;
  final AnimalService _animalService = AnimalService();
  List<Animal> _availableAnimals = [];
  List<SlaughterPart> _availableSlaughterParts = [];
  bool _isLoadingAnimals = false;
  String? _animalsError;
  int _animalsPage = 1;
  bool _hasMoreAnimals = true;
  int _partsPage = 1;
  bool _hasMoreParts = true;
  bool _isLoadingMoreSources = false;

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
  double? _liveWeight;

  @override
  void initState() {
    super.initState();

    // Initialize pipeline stages
    _initializePipeline();

    // The scale service is a singleton, so if a scale is already connected
    // from another screen, pick up its live stream immediately.
    if (_scaleService.isConnected) {
      _isScaleConnected = true;
      _startLiveWeightSubscription();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<ExternalVendorProvider>().fetchVendors();
      // Auto-fill processing unit field with the name of the logged-in processing unit
      final authProvider = context.read<AuthProvider>();
      final processingUnitName = authProvider.user?.processingUnitName ?? '';

      debugPrint(
        '🏭 [CREATE_PRODUCT] Processing Unit Name from AuthProvider: "$processingUnitName"',
      );
      debugPrint(
        '🏭 [CREATE_PRODUCT] Processing Unit ID: ${authProvider.user?.processingUnitId}',
      );
      debugPrint('🏭 [CREATE_PRODUCT] User Role: ${authProvider.user?.role}');

      _processingUnitController.text = processingUnitName;

      if (processingUnitName.isEmpty) {
        debugPrint('⚠️  [CREATE_PRODUCT] WARNING: Processing unit name is empty!');
        debugPrint(
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
      context.read<ProductCategoryProvider>().fetchCategories(),
      context.read<ProductProvider>().fetchProducts(
        processingUnitId: procUnitId,
      ),
    ]);
    await _loadAvailableAnimals();
  }

  /// Whole animals still need this client-side check: 'has_remaining_weight'
  /// and 'slaughtered' are pushed server-side (see the fetch call), but
  /// which processing unit an item "belongs to" isn't - the backend already
  /// scopes the queryset to every unit the user is a member of, and
  /// hasReceivedBy is kept as a permissive fallback for parts received by a
  /// teammate at the same unit.
  bool _animalBelongsToUnit(Animal animal, int? procUnitId) =>
      procUnitId == null ||
      animal.transferredTo == procUnitId ||
      animal.receivedBy != null;

  bool _partBelongsToUnit(SlaughterPart part, int? procUnitId) =>
      procUnitId == null ||
      part.transferredTo == procUnitId ||
      part.receivedBy != null;

  /// Fetches one page of animals and applies the eligibility filter,
  /// updating _hasMoreAnimals from the response's 'next' link.
  Future<List<Animal>> _fetchAnimalsPage(int page, int? procUnitId) async {
    final result = await _animalService.getAnimals(
      slaughtered: true,
      hasRemainingWeight: true,
      ordering: '-received_at',
      page: page,
      pageSize: _sourcePageSize,
    );
    final raw = result['results'] as List<Animal>;
    _hasMoreAnimals = result['next'] != null;
    return raw.where((a) => _animalBelongsToUnit(a, procUnitId)).toList();
  }

  Future<List<SlaughterPart>> _fetchPartsPage(int page, int? procUnitId) async {
    final result = await _animalService.getSlaughterParts(
      hasRemainingWeight: true,
      ordering: '-received_at',
      page: page,
      pageSize: _sourcePageSize,
    );
    final raw = result['results'] as List<SlaughterPart>;
    _hasMoreParts = result['next'] != null;
    return raw.where((p) => _partBelongsToUnit(p, procUnitId)).toList();
  }

  Future<void> _loadAvailableAnimals() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAnimals = true;
      _animalsError = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user?.id == null) {
        throw Exception('User not authenticated');
      }
      final procUnitId = authProvider.user?.processingUnitId;

      _animalsPage = 1;
      _partsPage = 1;
      _hasMoreAnimals = true;
      _hasMoreParts = true;

      final results = await Future.wait([
        _fetchAnimalsPage(_animalsPage, procUnitId),
        _fetchPartsPage(_partsPage, procUnitId),
      ]);

      if (mounted) {
        setState(() {
          _availableAnimals = results[0] as List<Animal>;
          _availableSlaughterParts = results[1] as List<SlaughterPart>;
          _isLoadingAnimals = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CREATE_PRODUCT] Error loading animals/parts: $e');
      if (mounted) {
        setState(() {
          _animalsError = e.toString();
          _isLoadingAnimals = false;
        });
      }
    }
  }

  /// Fetches the next page of whichever source(s) still have more, appends
  /// to the existing lists in place, and rebuilds the (already-open) source
  /// sheet via [setSheetState] - the sheet is a separate overlay route, so
  /// the outer screen's setState alone wouldn't reach it.
  Future<void> _loadMoreSources(void Function(void Function()) setSheetState) async {
    if (_isLoadingMoreSources || (!_hasMoreAnimals && !_hasMoreParts)) return;

    setSheetState(() => _isLoadingMoreSources = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final procUnitId = authProvider.user?.processingUnitId;

      if (_hasMoreAnimals) {
        final page = await _fetchAnimalsPage(_animalsPage + 1, procUnitId);
        _animalsPage++;
        _availableAnimals.addAll(page);
      }
      if (_hasMoreParts) {
        final page = await _fetchPartsPage(_partsPage + 1, procUnitId);
        _partsPage++;
        _availableSlaughterParts.addAll(page);
      }
    } catch (e) {
      debugPrint('❌ [CREATE_PRODUCT] Error loading more animals/parts: $e');
    } finally {
      if (mounted) {
        setSheetState(() => _isLoadingMoreSources = false);
      }
    }
  }

  void _showAnimalSelectionDialog() async {
    final scrollController = ScrollController();
    // StatefulBuilder's builder re-runs on every setSheetState call, so the
    // listener is attached once here (outside that closure) rather than
    // inside it, which would otherwise pile up a new listener per rebuild.
    var listenerAttached = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            if (!listenerAttached) {
              listenerAttached = true;
              scrollController.addListener(() {
                if (!scrollController.hasClients) return;
                final nearBottom = scrollController.position.pixels >=
                    scrollController.position.maxScrollExtent - 300;
                if (nearBottom) _loadMoreSources(setSheetState);
              });
            }

            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Animal or Part',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _isLoadingAnimals
                          ? const Center(child: CircularProgressIndicator())
                          : _animalsError != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
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
                                        Navigator.of(sheetContext).pop();
                                        _loadAvailableAnimals();
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildCombinedSourceList(scrollController),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    scrollController.dispose();

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
        _resetProductEntryFields();
      });
    }
  }

  String _animalDisplayLabel(Animal? animal, int fallbackId) {
    if (animal == null) return 'Animal #$fallbackId';
    return animal.animalName != null && animal.animalName!.isNotEmpty
        ? '${animal.species} - ${animal.animalName}'
        : '${animal.species} - ${animal.animalId}';
  }

  /// Same "species - name/ID" format as _animalDisplayLabel, but read
  /// directly off the part's own species/animal_name/animal_id fields
  /// (carried by the backend alongside the part) rather than requiring a
  /// separate animal lookup.
  String _partOriginLabel(SlaughterPart part) {
    if (part.species == null) return 'Animal #${part.animalId}';
    return part.animalName != null && part.animalName!.isNotEmpty
        ? '${part.species} - ${part.animalName}'
        : '${part.species} - ${part.animalCode ?? part.animalId}';
  }

  /// Clear weight/quantity/price entries so a new source doesn't inherit the
  /// previous animal or part's values (including any stale Bluetooth reading).
  void _resetProductEntryFields() {
    for (final controller in _weightControllers.values) {
      controller.clear();
    }
    for (final controller in _quantityControllers.values) {
      controller.text = '1';
    }
    for (final controller in _priceControllers.values) {
      controller.clear();
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

  void _startLiveWeightSubscription() {
    _weightSubscription?.cancel();
    _weightSubscription = _scaleService.weightStream.listen((weight) {
      if (mounted) setState(() => _liveWeight = weight);
    });
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
      _startLiveWeightSubscription();
    }
  }

  /// Combined, grouped source list for the selection sheet: whole animals
  /// (still directly available) are shown as single tiles; animals that have
  /// been broken into slaughter parts are shown as one expandable group per
  /// animal (rather than as a separate "Slaughter Parts" tab), since a part
  /// on its own doesn't carry the animal's identity — see _partOriginLabel,
  /// which resolves it the same way the whole-animal tiles and the
  /// traceability dashboard do. Only ~20 items are fetched at a time
  /// server-side (see _fetchAnimalsPage/_fetchPartsPage); scrolling near the
  /// bottom of [controller] triggers loading the next page.
  Widget _buildCombinedSourceList(ScrollController controller) {
    if (_availableAnimals.isEmpty && _availableSlaughterParts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No animals or slaughter parts available.\n\nItems must be:\n• Slaughtered\n• Received at your processing unit\n• Have remaining weight available',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final Map<int, List<SlaughterPart>> partsByAnimal = {};
    for (final part in _availableSlaughterParts) {
      partsByAnimal.putIfAbsent(part.animalId, () => []).add(part);
    }

    // Sort by most recent activity (received, or last part received) so a
    // just-received or just-modified animal surfaces at the top instead of
    // being buried among older ones.
    final entries = <(DateTime sortTime, Widget tile)>[
      for (final animal in _availableAnimals)
        (animal.receivedAt ?? animal.createdAt, _buildWholeAnimalTile(animal)),
      for (final group in partsByAnimal.entries)
        (
          group.value
              .map((p) => p.receivedAt ?? p.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          _buildAnimalPartsGroupTile(group.key, group.value),
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    final tiles = [for (final entry in entries) entry.$2];
    if (_isLoadingMoreSources) {
      tiles.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => tiles[index],
    );
  }

  Widget _buildWholeAnimalTile(Animal animal) {
    final isSelected = _selectedAnimal?.id == animal.id;
    final remainingWeight =
        animal.remainingWeight ?? animal.effectiveTransferWeight ?? 0.0;

    return Card(
      elevation: 0,
      color: isSelected
          ? AppColors.processorPrimary.withValues(alpha: 0.08)
          : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.processorPrimary : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.pets),
        title: Text(
          _animalDisplayLabel(animal, animal.id ?? 0),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'ID: ${animal.animalId} • Abbatoir: ${animal.abbatoirName}\nRemaining: ${remainingWeight.toStringAsFixed(2)} kg',
        ),
        isThreeLine: true,
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.chevron_right),
        onTap: () {
          if (context.mounted) {
            Navigator.of(context).pop({'type': 'animal', 'data': animal});
          }
        },
      ),
    );
  }

  Widget _buildAnimalPartsGroupTile(int animalId, List<SlaughterPart> parts) {
    final label = _partOriginLabel(parts.first);
    final totalRemaining = parts.fold<double>(
      0.0,
      (sum, p) => sum + (p.remainingWeight ?? p.weight),
    );
    final isAnySelected = parts.any((p) => _selectedPart?.id == p.id);

    return Card(
      elevation: 0,
      color: isAnySelected
          ? AppColors.processorPrimary.withValues(alpha: 0.08)
          : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAnySelected
              ? AppColors.processorPrimary
              : Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.pets),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${parts.length} part${parts.length > 1 ? 's' : ''} available • '
            'Total remaining: ${totalRemaining.toStringAsFixed(2)} kg',
          ),
          trailing: isAnySelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.expand_more),
          children: parts.map((part) {
            final remainingWeight = part.remainingWeight ?? part.weight;
            final isSelected = _selectedPart?.id == part.id;

            return ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              leading: const Icon(Icons.clear_all, size: 20),
              title: Text(part.partType.displayName),
              subtitle: Text(
                'Remaining: ${remainingWeight.toStringAsFixed(2)} ${part.weightUnit} of ${part.weight} ${part.weightUnit}',
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                if (context.mounted) {
                  Navigator.of(context).pop({'type': 'part', 'data': part});
                }
              },
            );
          }).toList(),
        ),
      ),
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
      final originLabel = _partOriginLabel(_selectedPart!);
      final remaining = _selectedPart!.remainingWeight ?? _selectedPart!.weight;
      selectionText =
          '${_selectedPart!.partType.displayName} (${remaining.toStringAsFixed(2)} ${_selectedPart!.weightUnit} remaining) - $originLabel';
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
              _resetProductEntryFields();
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
          _buildSourcePickerCard(selectionText),
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

  /// A prominent, tappable "picker card" for opening the source-selection
  /// sheet — replaces a plain button so the most important choice on this
  /// screen (what the products are made from) is hard to miss, and clearly
  /// reflects whether a source has been picked yet.
  Widget _buildSourcePickerCard(String selectionText) {
    final hasSelection = _selectedAnimal != null || _selectedPart != null;

    return Semantics(
      label: 'Select a slaughtered animal or part for the product',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showAnimalSelectionDialog,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasSelection
                ? AppColors.processorPrimary.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasSelection
                  ? AppColors.processorPrimary
                  : Colors.grey.shade300,
              width: hasSelection ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.processorPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSelection ? Icons.check_circle : Icons.pets,
                  color: AppColors.processorPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelection ? 'SOURCE SELECTED' : 'TAP TO SELECT A SOURCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: hasSelection
                            ? AppColors.processorPrimary
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectionText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hasSelection ? Colors.black87 : Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
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

  Widget _buildWeightFields() {
    // Calculate available weight for validation (always in kg)
    final double maxAvailableWeight = _isExternalSource
      ? (double.tryParse(_externalWeightController.text) ?? 1000000.0)
      : _selectedAnimal != null
      ? (_selectedAnimal!.remainingWeight ??
        _selectedAnimal!.effectiveTransferWeight ??
        0.0)
      : _selectedPart != null
      ? (_selectedPart!.remainingWeight ?? _selectedPart!.weight)
      : 0.0;

    debugPrint(
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
                  // All product weight fields on this screen share the one
                  // connected scale, so they all show the same live reading —
                  // weigh the batch currently on the scale, then tap Record
                  // on the category card for that batch.
                  BluetoothWeightDisplay(
                    label: 'Product Weight',
                    weight: _liveWeight,
                    recordedWeight: double.tryParse(weightController.text),
                    isConnected: _isScaleConnected,
                    unit: unit,
                    themeColor: AppColors.processorPrimary,
                    onTap: _connectScale,
                    onWeightChanged: (weight) {
                      setState(() {
                        weightController.text =
                            weight != null ? weight.toStringAsFixed(2) : '';
                      });
                      if (weight != null && context.mounted) {
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
                      }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      }
      return;
    }

    // Check if an animal or part or external vendor is selected
    if (!_isExternalSource &&
        _selectedAnimal == null &&
        _selectedPart == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an animal or slaughter part'),
        ),
      );
      }
      return;
    }

    if (_isExternalSource && _selectedVendor == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an external vendor')),
      );
      }
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

    debugPrint('🚀 [CreateProductScreen] Starting product creation process...');
    debugPrint('📊 [CreateProductScreen] Source: $sourceName');
    debugPrint('📊 [CreateProductScreen] Animal ID: $animalId');
    debugPrint(
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

    debugPrint('🏷️ [CreateProductScreen] Base batch number: $baseBatchNumber');

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

        debugPrint(
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

        debugPrint(
          '📦 [CreateProductScreen] Product data: ${product.toMapForCreate()}',
        );

        try {
          final createdProduct = await provider.createProduct(product);
          if (createdProduct != null) {
            debugPrint(
              '✅ [CreateProductScreen] Product created successfully: ${createdProduct.name} (Batch: ${createdProduct.batchNumber})',
            );
            createdProducts.add(createdProduct);
          } else {
            final errorMsg =
                'Product creation returned null for ${category.name}';
            debugPrint('❌ [CreateProductScreen] $errorMsg');
            debugPrint('🔍 [CreateProductScreen] Provider error: ${provider.error}');
            errors.add(errorMsg);
          }
        } catch (e) {
          final errorMsg =
              'Exception creating product for ${category.name}: $e';
          debugPrint('💥 [CreateProductScreen] $errorMsg');
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
      debugPrint(
        '🔄 [CreateProductScreen] Reloading available animals/parts after product creation...',
      );
      await _loadAvailableAnimals();
      debugPrint('✅ [CreateProductScreen] Available list reloaded');

      // Clear selection to allow creating more products
      _selectedAnimal = null;
      _selectedPart = null;
    } catch (e) {
      debugPrint('💥 [CreateProductScreen] Pipeline error: $e');
      _pipelineManager.failStage(
        'submission',
        'Unexpected error during processing: $e',
      );
    }

    setState(() {
      _isSubmitting = false;
      _createdProducts = createdProducts;
    });

    debugPrint(
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

      debugPrint('🚨 [CreateProductScreen] Showing error snackbar: $errorMessage');

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
      debugPrint('⚠️ [CreateProductScreen] Partial success: $message');

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
      debugPrint('🎉 [CreateProductScreen] All products created successfully');
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

      // Request permissions, re-prompting (or guiding to Settings) rather
      // than just erroring out if they weren't granted yet.
      debugPrint('🔐 [CreateProductScreen] Requesting Bluetooth permissions...');
      if (!mounted) return;
      final hasPermissions = await ensureBluetoothPermissions(context);
      if (!hasPermissions) {
        return;
      }
      debugPrint('✅ [CreateProductScreen] Permissions granted');

      // Scan for printers
      debugPrint('🔍 [CreateProductScreen] Scanning for printers...');
      final printers = await printingService.scanPrinters();
      debugPrint('📱 [CreateProductScreen] Found ${printers.length} printers');

      if (!mounted) return;

      if (printers.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No Bluetooth printers found. Make sure your printer is turned on and in pairing mode.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        }
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
        debugPrint('❌ [CreateProductScreen] No printer selected');
        return;
      }

      debugPrint(
        '🔗 [CreateProductScreen] Connecting to printer: ${selectedPrinter.platformName}',
      );

      // Show connecting dialog on root navigator to avoid popping the page
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => const AlertDialog(
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
        debugPrint('❌ [CreateProductScreen] Connection error: $e');
        connected = false;
      }

      // Close connecting dialog using root navigator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!connected) {
        if (!mounted) return;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to printer. Please try again.'),
            duration: Duration(seconds: 4),
          ),
        );
        }
        return;
      }

      debugPrint('✅ [CreateProductScreen] Connected successfully');

      // Print
      if (product != null) {
        debugPrint(
          '🖨️ [CreateProductScreen] Printing single product: ${product.name}',
        );
        final qrData = '${Constants.baseUrl}/product-info/view/${product.id}/';
        debugPrint('📊 [CreateProductScreen] QR Data: $qrData');

        await printingService.printQRCode(
          qrData,
          product.name,
          product.batchNumber,
        );

        if (!mounted) return;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Printed QR code for ${product.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        }
        debugPrint('✅ [CreateProductScreen] Print completed for ${product.name}');
      } else if (products != null && products.isNotEmpty) {
        debugPrint('🖨️ [CreateProductScreen] Printing ${products.length} products');
        int successCount = 0;

        for (int i = 0; i < products.length; i++) {
          final prod = products[i];
          try {
            debugPrint(
              '🖨️ [CreateProductScreen] Printing ${i + 1}/${products.length}: ${prod.name}',
            );
            final qrData = '${Constants.baseUrl}/product-info/view/${prod.id}/';

            await printingService.printQRCode(
              qrData,
              prod.name,
              prod.batchNumber,
            );
            successCount++;
            debugPrint(
              '✅ [CreateProductScreen] Printed ${i + 1}/${products.length}',
            );

            // Small delay between prints
            if (i < products.length - 1) {
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } catch (e) {
            debugPrint('❌ [CreateProductScreen] Failed to print ${prod.name}: $e');
          }
        }

        if (!mounted) return;
        if (context.mounted) {
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
        }
        debugPrint(
          '✅ [CreateProductScreen] Batch print completed: $successCount/${products.length}',
        );
      }

      // Disconnect
      debugPrint('🔌 [CreateProductScreen] Disconnecting from printer...');
      await printingService.disconnect();
      debugPrint('✅ [CreateProductScreen] Disconnected successfully');
    } catch (e) {
      debugPrint('💥 [CreateProductScreen] Printing error: $e');
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
      debugPrint('🏁 [CreateProductScreen] Printing process completed');
    }
  }
}
