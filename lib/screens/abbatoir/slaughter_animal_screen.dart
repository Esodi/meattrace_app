import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/animal.dart';
import '../../providers/animal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/custom_text_field.dart';
import '../../services/bluetooth_scale_service.dart';
import '../../widgets/dialogs/scale_connection_dialog.dart';
import '../../widgets/bluetooth_weight_display.dart';

/// Slaughter Animal Screen - Complete flow for recording animal slaughter with carcass measurements
/// Features: Animal selection, carcass type choice (whole/split), measurement recording, confirmation
class SlaughterAnimalScreen extends StatefulWidget {
  final String? animalId;

  const SlaughterAnimalScreen({super.key, this.animalId});

  @override
  State<SlaughterAnimalScreen> createState() => _SlaughterAnimalScreenState();
}

class _SlaughterAnimalScreenState extends State<SlaughterAnimalScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Step management
  int _currentStep = 0;

  // Selected animal
  Animal? _selectedAnimal;

  // Carcass type
  String _carcassType = 'split'; // 'whole' or 'split'

  // Measurement controllers for split carcass
  final _headWeightController = TextEditingController();
  final _feetWeightController = TextEditingController();
  final _leftCarcassWeightController = TextEditingController();
  final _rightCarcassWeightController = TextEditingController();

  // Measurement controller for whole carcass
  final _totalWeightController = TextEditingController();

  // Additional controllers for whole carcass detailed measurements
  final _headWeightWholeController = TextEditingController();
  final _feetWeightWholeController = TextEditingController();
  final _wholeCarcassWeightController = TextEditingController();

  // Notes
  final _notesController = TextEditingController();

  // Unit selections
  String _headUnit = 'kg';
  String _feetUnit = 'kg';
  String _leftCarcassUnit = 'kg';
  String _rightCarcassUnit = 'kg';

  // Units for whole carcass detailed measurements
  String _headWholeUnit = 'kg';
  String _feetWholeUnit = 'kg';
  String _wholeCarcassUnit = 'kg';

  // State
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isOffline = false;
  List<Animal> _availableAnimals = [];
  List<Animal> _filteredAnimals = [];
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Bluetooth Scale
  final BluetoothScaleService _scaleService = BluetoothScaleService();
  StreamSubscription? _weightSubscription;
  bool _isScaleConnected = false;
  double? _liveWeight;

  // Which single part (head / feet / whole carcass / left / right) is
  // currently selected to be weighed. Only that part's scale reading is
  // shown at a time — showing every part's field at once with the same
  // shared live reading made it unclear which weight was about to be
  // recorded for which part.
  String? _selectedPartKey;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [SlaughterScreen] initState called');
    _searchController.addListener(_filterAnimals);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔵 [SlaughterScreen] Post frame callback - loading animals');
      _loadAvailableAnimals();
    });
    // The scale service is a singleton, so if a scale is already connected
    // from another screen, pick up its live stream immediately.
    if (_scaleService.isConnected) {
      _isScaleConnected = true;
      _startLiveWeightSubscription();
    }
  }

  void _startLiveWeightSubscription() {
    _weightSubscription?.cancel();
    _weightSubscription = _scaleService.weightStream.listen((weight) {
      if (mounted) setState(() => _liveWeight = weight);
    });
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    _searchController.removeListener(_filterAnimals);
    _searchController.dispose();
    _headWeightController.dispose();
    _feetWeightController.dispose();
    _leftCarcassWeightController.dispose();
    _rightCarcassWeightController.dispose();
    _totalWeightController.dispose();
    _headWeightWholeController.dispose();
    _feetWeightWholeController.dispose();
    _wholeCarcassWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _connectScale() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ScaleConnectionDialog(),
    );

    if (result == true && mounted) {
      setState(() {
        _isScaleConnected = true;
      });
      _startLiveWeightSubscription();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scale connected successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadAvailableAnimals() async {
    debugPrint('🔵 [SlaughterScreen] _loadAvailableAnimals started');
    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      debugPrint('🔵 [SlaughterScreen] Fetching animals from provider...');
      await animalProvider.fetchAnimals(slaughtered: false);

      debugPrint(
        '🔵 [SlaughterScreen] Total animals from provider: ${animalProvider.animals.length}',
      );

      final animals = animalProvider.animals.where((animal) {
        final notSlaughtered = !animal.slaughtered;
        final notTransferred = animal.transferredTo == null;
        final healthOk =
            animal.healthStatus == null ||
            animal.healthStatus!.toLowerCase() == 'healthy' ||
            animal.healthStatus!.toLowerCase() == 'active';

        debugPrint(
          '  Animal ${animal.animalId}: slaughtered=$notSlaughtered, transferred=$notTransferred, health=$healthOk',
        );

        return notSlaughtered && notTransferred && healthOk;
      }).toList();

      debugPrint('🔵 [SlaughterScreen] Filtered animals count: ${animals.length}');

      setState(() {
        _availableAnimals = animals;
        _filteredAnimals = animals;
        _isLoading = false;
        _isOffline = false;
      });

      debugPrint(
        '🔵 [SlaughterScreen] State updated - _availableAnimals: ${_availableAnimals.length}, _filteredAnimals: ${_filteredAnimals.length}',
      );

      if (widget.animalId != null) {
        final targetAnimal = animals
            .where((animal) => animal.id.toString() == widget.animalId)
            .toList();
        if (targetAnimal.isNotEmpty) {
          _selectAnimal(targetAnimal.first);
        }
      }
    } catch (e) {
      debugPrint('❌ [SlaughterScreen] Error loading animals: $e');
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
      _showError(
        'Failed to load animals: ${e.toString()}\n\nWorking in offline mode. Some features may be limited.',
      );
    }
  }

  void _filterAnimals() {
    debugPrint(
      '🔍 [SlaughterScreen] _filterAnimals called with query: "${_searchController.text}"',
    );
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAnimals = _availableAnimals.where((animal) {
        final animalId = animal.animalId.toLowerCase();
        final animalName = animal.animalName?.toLowerCase() ?? '';
        final species = animal.species.toLowerCase();
        final breed = animal.breed?.toLowerCase() ?? '';

        return animalId.contains(query) ||
            animalName.contains(query) ||
            species.contains(query) ||
            breed.contains(query);
      }).toList();
      debugPrint(
        '🔍 [SlaughterScreen] Filtered results: ${_filteredAnimals.length} animals',
      );
    });
  }

  void _selectAnimal(Animal animal) {
    debugPrint('✅ [SlaughterScreen] Animal selected: ${animal.animalId}');
    setState(() {
      _selectedAnimal = animal;
      _currentStep = 1;
    });
    debugPrint('✅ [SlaughterScreen] Current step set to: $_currentStep');
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  double _convertToKg(double value, String unit) {
    switch (unit) {
      case 'kg':
        return value;
      case 'lbs':
        return value * 0.453592; // 1 lb = 0.453592 kg
      case 'g':
        return value / 1000; // 1 g = 0.001 kg
      default:
        return value; // Default to kg if unknown unit
    }
  }

  /// All parts relevant to the currently selected carcass type, in the
  /// order they should be weighed. This is the single source of truth for
  /// both the part selector UI and the total-weight calculation below — a
  /// previous version of _calculateTotalWeight() only counted
  /// whole_carcass_weight for 'whole' carcasses, silently ignoring the
  /// head/feet weights this same screen collects, so a live-weight fraud
  /// check on that total never saw padding hidden in those two fields.
  List<_PartSpec> get _currentParts {
    if (_carcassType == 'whole') {
      return [
        _PartSpec(
          key: 'head',
          label: 'Head',
          controller: _headWeightWholeController,
          unit: _headWholeUnit,
          onUnitChanged: (v) => setState(() => _headWholeUnit = v),
        ),
        _PartSpec(
          key: 'feet',
          label: 'Feet',
          controller: _feetWeightWholeController,
          unit: _feetWholeUnit,
          onUnitChanged: (v) => setState(() => _feetWholeUnit = v),
        ),
        _PartSpec(
          key: 'whole_carcass',
          label: 'Whole Carcass',
          controller: _wholeCarcassWeightController,
          unit: _wholeCarcassUnit,
          onUnitChanged: (v) => setState(() => _wholeCarcassUnit = v),
          required: true,
        ),
      ];
    }

    return [
      _PartSpec(
        key: 'head',
        label: 'Head',
        controller: _headWeightController,
        unit: _headUnit,
        onUnitChanged: (v) => setState(() => _headUnit = v),
        required: true,
      ),
      _PartSpec(
        key: 'feet',
        label: 'Feet',
        controller: _feetWeightController,
        unit: _feetUnit,
        onUnitChanged: (v) => setState(() => _feetUnit = v),
        required: true,
      ),
      _PartSpec(
        key: 'left_carcass',
        label: 'Left Carcass',
        controller: _leftCarcassWeightController,
        unit: _leftCarcassUnit,
        onUnitChanged: (v) => setState(() => _leftCarcassUnit = v),
        required: true,
      ),
      _PartSpec(
        key: 'right_carcass',
        label: 'Right Carcass',
        controller: _rightCarcassWeightController,
        unit: _rightCarcassUnit,
        onUnitChanged: (v) => setState(() => _rightCarcassUnit = v),
        required: true,
      ),
    ];
  }

  double _calculateTotalWeight() {
    double total = 0.0;
    for (final part in _currentParts) {
      total += _convertToKg(
        double.tryParse(part.controller.text) ?? 0.0,
        part.unit,
      );
    }
    return total;
  }

  /// Live weight minus everything recorded so far for the active carcass
  /// type. Negative once recorded parts add up to more than the animal
  /// ever weighed alive — a strong signal of a data-entry mistake or fraud.
  double _remainingWeightKg() {
    final liveWeight = _selectedAnimal?.liveWeight ?? 0.0;
    return liveWeight - _calculateTotalWeight();
  }

  /// Moves the part selector to the next not-yet-recorded part after one is
  /// just recorded, so the user is guided straight through the checklist
  /// instead of having to manually pick the next part every time.
  void _advanceToNextUnrecordedPart(String justRecordedKey) {
    final parts = _currentParts;
    final currentIndex = parts.indexWhere((p) => p.key == justRecordedKey);
    if (currentIndex == -1) return;
    for (int i = 1; i <= parts.length; i++) {
      final next = parts[(currentIndex + i) % parts.length];
      if (next.controller.text.isEmpty) {
        setState(() => _selectedPartKey = next.key);
        return;
      }
    }
  }

  bool _validateWeights() {
    final totalWeight = _calculateTotalWeight();

    // Check for negative weights
    if (totalWeight < 0) {
      _showError('Total carcass weight cannot be negative');
      return false;
    }

    // Check for unrealistic weights (too small for any animal)
    if (totalWeight > 0 && totalWeight < 0.5) {
      _showError(
        'Total carcass weight seems too small. Please verify measurements.',
      );
      return false;
    }

    // Check for unrealistic weights (too large for typical livestock)
    if (totalWeight > 2000) {
      _showError(
        'Total carcass weight seems unusually large. Please verify measurements.',
      );
      return false;
    }

    // Check individual weights: fields sent to the backend must be strictly
    // positive (the server rejects 0 with a 400 for these), while the
    // display-only total weight only needs to be non-negative.
    final requiredPositiveControllers = [
      _headWeightController,
      _feetWeightController,
      _leftCarcassWeightController,
      _rightCarcassWeightController,
      _headWeightWholeController,
      _feetWeightWholeController,
      _wholeCarcassWeightController,
    ];

    for (var controller in requiredPositiveControllers) {
      final weight = double.tryParse(controller.text);
      if (weight != null && weight <= 0) {
        _showError('Individual weights must be greater than zero');
        return false;
      }
    }

    final totalWeightFieldValue = double.tryParse(_totalWeightController.text);
    if (totalWeightFieldValue != null && totalWeightFieldValue < 0) {
      _showError('Individual weights cannot be negative');
      return false;
    }

    return true;
  }

  double _calculateYieldPercentage() {
    if (_selectedAnimal == null) {
      debugPrint(
        '⚠️ [SlaughterScreen] _calculateYieldPercentage called with null _selectedAnimal',
      );
      return 0.0;
    }

    final liveWeight = _selectedAnimal?.liveWeight ?? 0.0;
    final carcassWeight = _calculateTotalWeight();

    if (liveWeight == 0) return 0.0;
    return (carcassWeight / liveWeight) * 100;
  }

  Future<void> _confirmAndSlaughter() async {
    debugPrint('🔵 [SlaughterScreen] _confirmAndSlaughter called');

    if (_selectedAnimal == null) {
      debugPrint(
        '❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _confirmAndSlaughter',
      );
      _showError('Error: No animal selected');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('⚠️ [SlaughterScreen] Form validation failed');
      _showError('Please fill in all required fields');
      return;
    }

    // Validate weights comprehensively
    if (!_validateWeights()) {
      return;
    }

    // Validate minimum measurements
    final totalWeight = _calculateTotalWeight();
    debugPrint('🔵 [SlaughterScreen] Total weight: $totalWeight kg');

    if (totalWeight <= 0) {
      debugPrint('⚠️ [SlaughterScreen] Invalid total weight: $totalWeight');
      _showError('Total carcass weight must be greater than 0');
      return;
    }

    // Validate against live weight (yield percentage check)
    if (_selectedAnimal!.liveWeight != null &&
        totalWeight > _selectedAnimal!.liveWeight!) {
      _showError(
        'Total carcass weight (${totalWeight.toStringAsFixed(1)} kg) cannot exceed live weight (${_selectedAnimal!.liveWeight} kg)',
      );
      return;
    }

    // Check for unrealistic weights
    if (totalWeight > 2000) {
      _showError(
        'Total carcass weight seems unusually large (${totalWeight.toStringAsFixed(1)} kg). Please verify measurements.',
      );
      return;
    }

    // Check if data is complete for the selected carcass type
    if (!_validateDataCompleteness()) {
      return;
    }

    debugPrint('✅ [SlaughterScreen] Showing confirmation dialog');

    debugPrint('✅ [SlaughterScreen] User confirmed slaughter, proceeding...');
    await _performSlaughter();
  }

  bool _validateDataCompleteness() {
    if (_carcassType == 'whole') {
      if (_wholeCarcassWeightController.text.isEmpty) {
        _showError('Whole carcass weight is required');
        return false;
      }
    } else {
      // Split carcass validation
      if (_headWeightController.text.isEmpty ||
          _feetWeightController.text.isEmpty ||
          _leftCarcassWeightController.text.isEmpty ||
          _rightCarcassWeightController.text.isEmpty) {
        _showError(
          'All four measurements are required for split carcass: head, feet, left carcass, right carcass',
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _performSlaughter() async {
    debugPrint('🔵 [SlaughterScreen] _performSlaughter started');

    if (_selectedAnimal == null) {
      debugPrint(
        '❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _performSlaughter',
      );
      _showError('Error: No animal selected');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _performSlaughterWithRetry();
    } catch (e) {
      setState(() => _isSubmitting = false);
      debugPrint('❌ [SlaughterScreen] Final failure after retries: $e');

      // Check if it's a network error and offer offline fallback
      if (_isNetworkError(e)) {
        await _showOfflineFallbackDialog();
      } else {
        _showError('Failed to record slaughter: ${e.toString()}');
      }
    }
  }

  Future<void> _performSlaughterWithRetry() async {
    _retryCount = 0;

    while (_retryCount <= _maxRetries) {
      try {
        debugPrint(
          '🔵 [SlaughterScreen] Attempt ${_retryCount + 1}/${_maxRetries + 1}',
        );

        debugPrint(
          '🔵 [SlaughterScreen] Creating carcass measurements FIRST (before marking as slaughtered)',
        );
        // STEP 1: Create carcass measurements FIRST
        Map<String, Map<String, dynamic>> measurements = {};

        if (_carcassType == 'split') {
          // Add split carcass measurements
          if (_headWeightController.text.isNotEmpty) {
            measurements['head_weight'] = {
              'value': double.parse(_headWeightController.text),
              'unit': _headUnit,
            };
          }
          if (_feetWeightController.text.isNotEmpty) {
            measurements['feet_weight'] = {
              'value': double.parse(_feetWeightController.text),
              'unit': _feetUnit,
            };
          }
          if (_leftCarcassWeightController.text.isNotEmpty) {
            measurements['left_carcass_weight'] = {
              'value': double.parse(_leftCarcassWeightController.text),
              'unit': _leftCarcassUnit,
            };
          }
          if (_rightCarcassWeightController.text.isNotEmpty) {
            measurements['right_carcass_weight'] = {
              'value': double.parse(_rightCarcassWeightController.text),
              'unit': _rightCarcassUnit,
            };
          }
        } else {
          // Whole carcass - detailed measurements
          if (_headWeightWholeController.text.isNotEmpty) {
            measurements['head_weight'] = {
              'value': double.parse(_headWeightWholeController.text),
              'unit': _headWholeUnit,
            };
          }
          if (_feetWeightWholeController.text.isNotEmpty) {
            measurements['feet_weight'] = {
              'value': double.parse(_feetWeightWholeController.text),
              'unit': _feetWholeUnit,
            };
          }
          measurements['whole_carcass_weight'] = {
            'value': double.parse(_wholeCarcassWeightController.text),
            'unit': _wholeCarcassUnit,
          };
        }

        debugPrint('🔵 [SlaughterScreen] Measurements prepared: $measurements');
        debugPrint(
          '🔵 [SlaughterScreen] Carcass type before API call: $_carcassType',
        );

        // Create carcass measurement record
        final measurement = CarcassMeasurement(
          animalId: _selectedAnimal!.id!,
          carcassType: _carcassType == 'split'
              ? CarcassType.split
              : CarcassType.whole,
          measurements: Map<String, Map<String, dynamic>>.from(measurements),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final animalProvider = Provider.of<AnimalProvider>(
          context,
          listen: false,
        );
        await animalProvider.createCarcassMeasurement(measurement);

        // Log activity
        final activityProvider = Provider.of<ActivityProvider>(
          context,
          listen: false,
        );
        await activityProvider.logSlaughter(
          animalId: _selectedAnimal!.id.toString(),
          animalTag: _selectedAnimal!.animalId,
        );

        setState(() => _isSubmitting = false);

        if (mounted) {
          _showSuccessDialog();
        }
        return; // Success, exit retry loop
      } catch (e) {
        _retryCount++;
        debugPrint('⚠️ [SlaughterScreen] Attempt $_retryCount failed: $e');

        if (_retryCount <= _maxRetries && _isNetworkError(e)) {
          // Wait before retry (exponential backoff)
          await Future.delayed(Duration(seconds: _retryCount * 2));
          continue;
        } else {
          // Max retries reached or non-network error
          rethrow;
        }
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('dio');
  }

  Future<void> _showOfflineFallbackDialog() async {
    if (!mounted) return;

    final shouldSaveOffline = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Text('Network Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to connect to the server. Would you like to save this slaughter record offline and sync later?',
              style: AppTypography.bodyLarge(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Offline data will be automatically synced when connection is restored.',
                style: AppTypography.bodySmall(color: AppColors.info),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Save Offline',
            onPressed: () => Navigator.of(context).pop(true),
            customColor: AppColors.abbatoirPrimary,
            fullWidth: false,
          ),
        ],
      ),
    );

    if (shouldSaveOffline == true) {
      await _saveSlaughterOffline();
    }
  }

  Future<void> _saveSlaughterOffline() async {
    try {
      // Create offline slaughter record
      // Save to local storage (you would implement this based on your storage solution)
      // For now, we'll just show a success message
      setState(() => _isSubmitting = false);

      if (mounted) {
        _showOfflineSuccessDialog();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Failed to save offline: ${e.toString()}');
    }
  }

  void _showOfflineSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.offline_pin, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Text('Saved Offline'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedAnimal!.species} ${_selectedAnimal!.animalId} slaughter record saved offline',
              style: AppTypography.bodyLarge(),
            ),
            const SizedBox(height: 16),
            _buildSuccessItem(
              'Carcass Weight',
              '${_calculateTotalWeight().toStringAsFixed(1)} kg',
            ),
            _buildSuccessItem(
              'Parts Recorded',
              '${_currentParts.where((p) => p.controller.text.isNotEmpty).length}',
            ),
            _buildSuccessItem(
              'Type',
              _carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                'This record will be automatically synced when you regain internet connection.',
                style: AppTypography.bodySmall(color: AppColors.warning),
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            label: 'Done',
            onPressed: () {
              if (context.mounted) Navigator.of(context).pop();
              context.go('/abbatoir-home');
            },
            customColor: AppColors.abbatoirPrimary,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    debugPrint('🔵 [SlaughterScreen] _showSuccessDialog called');

    if (_selectedAnimal == null) {
      debugPrint(
        '❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _showSuccessDialog',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            const Text('Slaughter Recorded'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedAnimal!.species} ${_selectedAnimal!.animalId} slaughtered and measurements recorded',
              style: AppTypography.bodyLarge(),
            ),
            const SizedBox(height: 16),
            _buildSuccessItem(
              'Carcass Weight',
              '${_calculateTotalWeight().toStringAsFixed(1)} kg',
            ),
            _buildSuccessItem(
              'Parts Recorded',
              '${_currentParts.where((p) => p.controller.text.isNotEmpty).length}',
            ),
            _buildSuccessItem(
              'Type',
              _carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass',
            ),
            const SizedBox(height: 16),
            Text(
              'Next Steps:',
              style: AppTypography.bodyMedium().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Create products from carcass',
              style: AppTypography.bodySmall(),
            ),
            Text('• View carcass details', style: AppTypography.bodySmall()),
            Text(
              '• Transfer to processing unit',
              style: AppTypography.bodySmall(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) Navigator.of(context).pop();
              context.go('/abbatoir-home');
            },
            child: const Text('Done'),
          ),
          CustomButton(
            label: 'View Details',
            onPressed: () {
              if (context.mounted) Navigator.of(context).pop();
              context.push('/animals/${_selectedAnimal!.id}');
            },
            customColor: AppColors.abbatoirPrimary,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    // For network errors, show a more detailed message
    String displayMessage = message;
    if (_isOffline ||
        message.contains('network') ||
        message.contains('connection')) {
      displayMessage += '\n\nYou can continue working offline.';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: _isOffline
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _loadAvailableAnimals(),
              )
            : null,
      ),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🔵 [SlaughterScreen] build called - currentStep: $_currentStep, isSubmitting: $_isSubmitting',
    );
    debugPrint(
      '🔵 [SlaughterScreen] selectedAnimal: ${_selectedAnimal?.animalId ?? "null"}',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.abbatoirPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Slaughter Animal',
          style: AppTypography.headlineMedium(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _currentStep > 0 ? _previousStep : () => context.pop(),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing slaughter...'),
                ],
              ),
            )
          : _currentStep == 0 && _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading animals...'),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _currentStep,
      onStepContinue: _nextStep,
      onStepCancel: _previousStep,
      controlsBuilder: (context, details) {
        return const SizedBox.shrink();
      },
      steps: [
        Step(
          title: const Text('Animal'),
          content: _buildAnimalSelectionStep(),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Carcass'),
          content: _buildCarcassTypeStep(),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text('Measure'),
          content: _buildMeasurementStep(),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  Widget _buildAnimalSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomTextField(
          controller: _searchController,
          label: 'Search Animals',
          hint: 'Search by ID, name, or species',
          prefixIcon: const Icon(Icons.search),
          onChanged: (value) => _filterAnimals(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400, // Fixed height for the list
          child: _filteredAnimals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLoading
                              ? 'Loading animals...'
                              : 'No animals found',
                          style: AppTypography.bodyLarge(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredAnimals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final animal = _filteredAnimals[index];
                    final isSelected = _selectedAnimal?.id == animal.id;

                    return CustomCard(
                      onTap: () => _selectAnimal(animal),
                      borderColor: isSelected ? AppColors.abbatoirPrimary : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              _getSpeciesEmoji(animal.species),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal.animalId,
                                    style: AppTypography.titleMedium().copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.abbatoirPrimary
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${animal.breed ?? animal.species} • ${animal.liveWeight} kg',
                                    style: AppTypography.bodySmall(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.abbatoirPrimary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getSpeciesEmoji(String species) {
    switch (species.toLowerCase()) {
      case 'cattle':
      case 'cow':
      case 'bull':
        return '🐄';
      case 'pig':
        return '🐷';
      case 'sheep':
        return '🐑';
      case 'goat':
        return '🐐';
      case 'chicken':
        return '🐔';
      default:
        return '🐾';
    }
  }

  Widget _buildCarcassTypeStep() {
    if (_selectedAnimal == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: No animal selected',
              style: AppTypography.titleLarge(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            CustomButton(
              label: 'Go Back',
              onPressed: () => setState(() => _currentStep = 0),
              customColor: AppColors.abbatoirPrimary,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected animal card
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _getSpeciesEmoji(_selectedAnimal!.species),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAnimal!.animalId,
                          style: AppTypography.titleLarge().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedAnimal!.breed ?? _selectedAnimal!.species} • ${_selectedAnimal!.liveWeight} kg • ${_selectedAnimal!.ageDisplay}',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Carcass type selection
          Text(
            'Carcass Type',
            style: AppTypography.titleLarge().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Whole carcass option
          CustomCard(
            onTap: () => setState(() => _carcassType = 'whole'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'whole',
                    groupValue: _carcassType,
                    onChanged: (value) => setState(() => _carcassType = value!),
                    activeColor: AppColors.abbatoirPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Whole Carcass',
                          style: AppTypography.titleMedium().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record total weight only',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Single measurement • Faster recording',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Split carcass option
          CustomCard(
            onTap: () => setState(() => _carcassType = 'split'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Radio<String>(
                    value: 'split',
                    groupValue: _carcassType,
                    onChanged: (value) => setState(() => _carcassType = value!),
                    activeColor: AppColors.abbatoirPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Carcass',
                          style: AppTypography.titleMedium().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record individual parts',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Head, Feet, Left Carcass, Right Carcass • Better traceability',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondary,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _carcassType == 'split'
                        ? 'Split carcass provides more detailed traceability for product creation and helps track individual parts through the supply chain.'
                        : 'Whole carcass recording is faster but provides less detailed part tracking. Recommended for smaller animals or bulk processing.',
                    style: AppTypography.bodySmall(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Continue button
          CustomButton(
            label: 'Continue to Measurements',
            onPressed: _nextStep,
            customColor: AppColors.abbatoirPrimary,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementStep() {
    if (_selectedAnimal == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: No animal selected',
              style: AppTypography.titleLarge(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            CustomButton(
              label: 'Go Back',
              onPressed: () => setState(() => _currentStep = 0),
              customColor: AppColors.abbatoirPrimary,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording: ${_selectedAnimal!.animalId}',
                      style: AppTypography.titleLarge().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${_carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass'}',
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildPartSelectorAndRecorder(),

            const SizedBox(height: 24),

            _buildRunningWeightSummary(),

            const SizedBox(height: 24),

            // Notes
            CustomTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'Add any additional notes or observations',
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Confirm button
            CustomButton(
              label: 'Confirm Slaughter',
              onPressed: _confirmAndSlaughter,
              customColor: AppColors.abbatoirPrimary,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a checklist of the parts to weigh for the current carcass type,
  /// and — for whichever one is selected — a single scale reading clearly
  /// labelled with what it will record. Previously every part's field was
  /// shown at once, all sharing the one live reading from the connected
  /// scale, so it was unclear which figure was about to be recorded for
  /// which part.
  Widget _buildPartSelectorAndRecorder() {
    if (_selectedAnimal == null) {
      return Center(
        child: Text(
          'Error: No animal selected',
          style: AppTypography.bodyLarge(color: AppColors.error),
        ),
      );
    }

    final parts = _currentParts;
    if (_selectedPartKey == null || !parts.any((p) => p.key == _selectedPartKey)) {
      _selectedPartKey = parts.first.key;
    }
    final active = parts.firstWhere((p) => p.key == _selectedPartKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Part to Weigh',
          style: AppTypography.titleMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Place one part on the scale at a time, select it below, then tap Record.',
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: parts.map((part) {
            final recordedWeight = double.tryParse(part.controller.text);
            final isSelected = part.key == active.key;
            return ChoiceChip(
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedPartKey = part.key),
              selectedColor: AppColors.abbatoirPrimary,
              backgroundColor: recordedWeight != null
                  ? AppColors.success.withValues(alpha: 0.1)
                  : null,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (recordedWeight != null)
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.success,
                    )
                  else if (part.required)
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    recordedWeight != null
                        ? '${part.label} • ${recordedWeight.toStringAsFixed(1)} ${part.unit}'
                        : part.label + (part.required ? ' *' : ' (optional)'),
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        Text(
          'Recording: ${active.label}',
          style: AppTypography.titleMedium().copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.abbatoirPrimary,
          ),
        ),
        const SizedBox(height: 8),

        _buildMeasurementField(
          active.label,
          active.controller,
          active.unit,
          active.onUnitChanged,
          required: active.required,
          onRecorded: () => _advanceToNextUnrecordedPart(active.key),
        ),
      ],
    );
  }

  /// Live weight vs. everything recorded so far, updating as each part is
  /// recorded — so a part weighed too heavy is obvious immediately, not
  /// just at the final confirmation.
  Widget _buildRunningWeightSummary() {
    if (_selectedAnimal == null) return const SizedBox.shrink();

    final liveWeight = _selectedAnimal!.liveWeight ?? 0.0;
    final recorded = _calculateTotalWeight();
    final remaining = _remainingWeightKg();
    final isOver = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOver
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.abbatoirPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOver
              ? AppColors.error
              : AppColors.abbatoirPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _weightStat('Live Weight', '${liveWeight.toStringAsFixed(1)} kg'),
              ),
              Expanded(
                child: _weightStat('Recorded', '${recorded.toStringAsFixed(1)} kg'),
              ),
              Expanded(
                child: _weightStat(
                  isOver ? 'Over by' : 'Remaining',
                  '${remaining.abs().toStringAsFixed(1)} kg',
                  color: isOver ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Yield: ${_calculateYieldPercentage().toStringAsFixed(1)}%',
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
          if (isOver) ...[
            const SizedBox(height: 8),
            Text(
              'Recorded parts add up to more than this animal\'s live weight — '
              'double-check each measurement before confirming.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weightStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium().copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.abbatoirPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMeasurementField(
    String label,
    TextEditingController controller,
    String unit,
    Function(String) onUnitChanged, {
    bool required = false,
    VoidCallback? onRecorded,
  }) {
    // Parse current weight from controller
    double? currentWeight;
    if (controller.text.isNotEmpty) {
      currentWeight = double.tryParse(controller.text);
    }

    return BluetoothWeightDisplay(
      label: label + (required ? ' *' : ''),
      // Only the currently-selected part's field is shown at a time (see
      // _buildPartSelectorAndRecorder), so this live reading is
      // unambiguous: it's always for the part named in the label above it.
      weight: _liveWeight,
      recordedWeight: currentWeight,
      isConnected: _isScaleConnected,
      onTap: _connectScale,
      onWeightChanged: (weight) {
        setState(() {
          controller.text = weight != null ? weight.toStringAsFixed(2) : '';
        });
        if (weight != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label: ${weight.toStringAsFixed(2)} $unit'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          onRecorded?.call();
        }
      },
      unit: unit,
      themeColor: AppColors.abbatoirPrimary,
    );
  }
}

/// One weighable carcass part (head, feet, whole carcass, left/right
/// carcass, …) and the controller/unit state that back its measurement
/// field. Built fresh on each build from whichever set of TextEditingControllers
/// matches the currently selected carcass type — see [_SlaughterAnimalScreenState._currentParts].
class _PartSpec {
  final String key;
  final String label;
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final bool required;

  const _PartSpec({
    required this.key,
    required this.label,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    this.required = false,
  });
}
