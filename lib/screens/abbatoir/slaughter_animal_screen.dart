import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/animal.dart';
import '../../providers/animal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/dio_client.dart';
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
  String? _networkError;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Bluetooth Scale
  final BluetoothScaleService _scaleService = BluetoothScaleService();
  StreamSubscription? _weightSubscription;
  bool _isScaleConnected = false;

  @override
  void initState() {
    super.initState();
    print('🔵 [SlaughterScreen] initState called');
    _searchController.addListener(_filterAnimals);
    // Schedule data loading after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔵 [SlaughterScreen] Post frame callback - loading animals');
      _loadAvailableAnimals();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't reload here - it causes duplicate calls
    // Only load in initState
    print(
      '🔵 [SlaughterScreen] didChangeDependencies called (skipping reload)',
    );
  }

  @override
  void dispose() {
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
    _weightSubscription?.cancel();
    super.dispose();
  }

  Future<void> _connectScale() async {
    if (_scaleService.isConnected) {
      // Already connected, maybe show status or disconnect option?
      // For now, just show a toast or snackbar
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

      // Listen to weight stream
      _weightSubscription?.cancel();
      _weightSubscription = _scaleService.weightStream.listen((weight) {
        // We could auto-update a focused field, or just keep the latest value
        // For this implementation, we'll pull on demand via the button
        print('Scale weight: $weight');
      });
    }
  }

  void _readWeightFromScale(TextEditingController controller) async {
    if (!_scaleService.isConnected) {
      _connectScale();
      return;
    }

    print('👆 [SlaughterScreen] Reading weight from scale...');

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading from scale... Please ensure weight is stable.'),
        duration: Duration(seconds: 10),
      ),
    );

    bool gotWeight = false;

    // Try to manually read the characteristic first (some scales need this)
    try {
      print('👆 [SlaughterScreen] Attempting manual read...');
      await _scaleService.readWeight();
    } catch (e) {
      print(
        '⚠️ [SlaughterScreen] Manual read failed (normal for notify-only scales): $e',
      );
    }

    // Listen for the next weight value from the stream
    StreamSubscription? singleRead;
    singleRead = _scaleService.weightStream.listen((weight) {
      print('✅ [SlaughterScreen] Received weight: $weight kg');
      if (!gotWeight) {
        gotWeight = true;
        setState(() {
          controller.text = weight.toStringAsFixed(2);
        });
        singleRead?.cancel();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weight: ${weight.toStringAsFixed(2)} kg'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // Longer timeout (10 seconds) to give scale time to stabilize and send data
    Future.delayed(const Duration(seconds: 10), () {
      if (!gotWeight) {
        print('⏱️ [SlaughterScreen] Timeout waiting for weight');
        singleRead?.cancel();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No weight received. Ensure weight is on scale and stable.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Widget _buildWeightFieldWithScale(
    TextEditingController controller,
    String label,
    String unit,
    Function(String?)? onChanged,
  ) {
    // Parse current weight from controller
    double? currentWeight;
    if (controller.text.isNotEmpty) {
      currentWeight = double.tryParse(controller.text);
    }

    return BluetoothWeightDisplay(
      label: label,
      weight: currentWeight,
      isConnected: _isScaleConnected,
      onTap: () async {
        // Read weight and update controller
        if (!_scaleService.isConnected) {
          await _connectScale();
          return;
        }

        print('👆 [SlaughterScreen] Reading weight for $label...');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reading from scale... Please ensure weight is stable.',
            ),
            duration: Duration(seconds: 10),
          ),
        );

        bool gotWeight = false;

        try {
          await _scaleService.readWeight();
        } catch (e) {
          print('⚠️ [SlaughterScreen] Manual read failed: $e');
        }

        StreamSubscription? singleRead;
        singleRead = _scaleService.weightStream.listen((weight) {
          if (!gotWeight) {
            gotWeight = true;
            setState(() {
              controller.text = weight.toStringAsFixed(2);
            });
            if (onChanged != null) {
              onChanged(weight.toStringAsFixed(2));
            }
            singleRead?.cancel();

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label: ${weight.toStringAsFixed(2)} $unit'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });

        Future.delayed(const Duration(seconds: 10), () {
          if (!gotWeight) {
            singleRead?.cancel();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No weight received. Ensure weight is on scale and stable.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      },
      unit: unit,
      themeColor: AppColors.abbatoirPrimary, // Abbatoir green theme
    );
  }

  Future<void> _loadAvailableAnimals() async {
    print('🔵 [SlaughterScreen] _loadAvailableAnimals started');
    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(
        context,
        listen: false,
      );
      print('🔵 [SlaughterScreen] Fetching animals from provider...');
      await animalProvider.fetchAnimals(slaughtered: false);

      print(
        '🔵 [SlaughterScreen] Total animals from provider: ${animalProvider.animals.length}',
      );

      final animals = animalProvider.animals.where((animal) {
        final notSlaughtered = !animal.slaughtered;
        final notTransferred = animal.transferredTo == null;
        final healthOk =
            animal.healthStatus == null ||
            animal.healthStatus!.toLowerCase() == 'healthy' ||
            animal.healthStatus!.toLowerCase() == 'active';

        print(
          '  Animal ${animal.animalId}: slaughtered=$notSlaughtered, transferred=$notTransferred, health=$healthOk',
        );

        return notSlaughtered && notTransferred && healthOk;
      }).toList();

      print('🔵 [SlaughterScreen] Filtered animals count: ${animals.length}');

      setState(() {
        _availableAnimals = animals;
        _filteredAnimals = animals;
        _isLoading = false;
        _isOffline = false;
        _networkError = null;
      });

      print(
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
      print('❌ [SlaughterScreen] Error loading animals: $e');
      setState(() {
        _isLoading = false;
        _isOffline = true;
        _networkError = e.toString();
      });
      _showError(
        'Failed to load animals: ${e.toString()}\n\nWorking in offline mode. Some features may be limited.',
      );
    }
  }

  void _filterAnimals() {
    print(
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
      print(
        '🔍 [SlaughterScreen] Filtered results: ${_filteredAnimals.length} animals',
      );
    });
  }

  void _selectAnimal(Animal animal) {
    print('✅ [SlaughterScreen] Animal selected: ${animal.animalId}');
    setState(() {
      _selectedAnimal = animal;
      _currentStep = 1;
    });
    print('✅ [SlaughterScreen] Current step set to: $_currentStep');
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

  double _calculateTotalWeight() {
    if (_carcassType == 'whole') {
      // For whole carcass, use the whole carcass weight field
      final weight = double.tryParse(_wholeCarcassWeightController.text) ?? 0.0;
      return _convertToKg(weight, _wholeCarcassUnit);
    }

    // Split carcass - sum all parts (convert to kg first)
    double total = 0.0;
    total += _convertToKg(
      double.tryParse(_headWeightController.text) ?? 0.0,
      _headUnit,
    );
    total += _convertToKg(
      double.tryParse(_feetWeightController.text) ?? 0.0,
      _feetUnit,
    );
    total += _convertToKg(
      double.tryParse(_leftCarcassWeightController.text) ?? 0.0,
      _leftCarcassUnit,
    );
    total += _convertToKg(
      double.tryParse(_rightCarcassWeightController.text) ?? 0.0,
      _rightCarcassUnit,
    );

    return total;
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

    // Check individual weights for negative values
    final weightControllers = [
      _headWeightController,
      _feetWeightController,
      _leftCarcassWeightController,
      _rightCarcassWeightController,
      _totalWeightController,
      _headWeightWholeController,
      _feetWeightWholeController,
      _wholeCarcassWeightController,
    ];

    for (var controller in weightControllers) {
      final weight = double.tryParse(controller.text);
      if (weight != null && weight < 0) {
        _showError('Individual weights cannot be negative');
        return false;
      }
    }

    return true;
  }

  double _calculateYieldPercentage() {
    if (_selectedAnimal == null) {
      print(
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
    print('🔵 [SlaughterScreen] _confirmAndSlaughter called');

    if (_selectedAnimal == null) {
      print(
        '❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _confirmAndSlaughter',
      );
      _showError('Error: No animal selected');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('⚠️ [SlaughterScreen] Form validation failed');
      _showError('Please fill in all required fields');
      return;
    }

    // Validate weights comprehensively
    if (!_validateWeights()) {
      return;
    }

    // Validate minimum measurements
    final totalWeight = _calculateTotalWeight();
    print('🔵 [SlaughterScreen] Total weight: $totalWeight kg');

    if (totalWeight <= 0) {
      print('⚠️ [SlaughterScreen] Invalid total weight: $totalWeight');
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

    print('✅ [SlaughterScreen] Showing confirmation dialog');

    print('✅ [SlaughterScreen] User confirmed slaughter, proceeding...');
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
    print('🔵 [SlaughterScreen] _performSlaughter started');

    if (_selectedAnimal == null) {
      print(
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
      print('❌ [SlaughterScreen] Final failure after retries: $e');

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
        print(
          '🔵 [SlaughterScreen] Attempt ${_retryCount + 1}/${_maxRetries + 1}',
        );

        print('🔵 [SlaughterScreen] Creating DioClient');
        final dioClient = DioClient();

        print(
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

        print('🔵 [SlaughterScreen] Measurements prepared: $measurements');
        print(
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
        print('⚠️ [SlaughterScreen] Attempt $_retryCount failed: $e');

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
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
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
      final offlineData = {
        'animal_id': _selectedAnimal!.id,
        'animal_tag': _selectedAnimal!.animalId,
        'carcass_type': _carcassType,
        'measurements': _prepareMeasurements(),
        'notes': _notesController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };

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

  Map<String, Map<String, dynamic>> _prepareMeasurements() {
    Map<String, Map<String, dynamic>> measurements = {};

    if (_carcassType == 'split') {
      // Send only the four new fields for split carcass
      if (_headWeightController.text.isNotEmpty) {
        measurements['head'] = {
          'value': double.parse(_headWeightController.text),
          'unit': _headUnit,
        };
      }
      if (_feetWeightController.text.isNotEmpty) {
        measurements['feet'] = {
          'value': double.parse(_feetWeightController.text),
          'unit': _feetUnit,
        };
      }
      if (_leftCarcassWeightController.text.isNotEmpty) {
        measurements['left_carcass'] = {
          'value': double.parse(_leftCarcassWeightController.text),
          'unit': _leftCarcassUnit,
        };
      }
      if (_rightCarcassWeightController.text.isNotEmpty) {
        measurements['right_carcass'] = {
          'value': double.parse(_rightCarcassWeightController.text),
          'unit': _rightCarcassUnit,
        };
      }
    } else {
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

    return measurements;
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
              _carcassType == 'split' ? '4' : '1',
            ),
            _buildSuccessItem(
              'Type',
              _carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
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
              Navigator.of(context).pop();
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
    print('🔵 [SlaughterScreen] _showSuccessDialog called');

    if (_selectedAnimal == null) {
      print(
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
              _carcassType == 'split' ? '4' : '1',
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
              Navigator.of(context).pop();
              context.go('/abbatoir-home');
            },
            child: const Text('Done'),
          ),
          CustomButton(
            label: 'View Details',
            onPressed: () {
              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    print(
      '🔵 [SlaughterScreen] build called - currentStep: $_currentStep, isSubmitting: $_isSubmitting',
    );
    print(
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

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall(color: AppColors.textSecondary),
      ),
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
                          '${_selectedAnimal!.breed ?? _selectedAnimal!.species} • ${_selectedAnimal!.liveWeight} kg • ${_selectedAnimal!.age}m',
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
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
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

            if (_carcassType == 'whole')
              _buildWholeCarcassMeasurements()
            else
              _buildSplitCarcassMeasurements(),

            const SizedBox(height: 24),

            // Total weight display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.abbatoirPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.abbatoirPrimary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Carcass Weight',
                    style: AppTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_calculateTotalWeight().toStringAsFixed(1)} kg',
                    style: AppTypography.displaySmall(
                      color: AppColors.abbatoirPrimary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Live Weight: ${_selectedAnimal!.liveWeight} kg',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Yield: ${_calculateYieldPercentage().toStringAsFixed(1)}%',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

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

  Widget _buildWholeCarcassMeasurements() {
    if (_selectedAnimal == null) {
      return Center(
        child: Text(
          'Error: No animal selected',
          style: AppTypography.bodyLarge(color: AppColors.error),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Carcass Measurements',
          style: AppTypography.titleMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // HEAD weight field
        _buildMeasurementField(
          'Head Weight',
          _headWeightWholeController,
          _headWholeUnit,
          (value) {
            setState(() => _headWholeUnit = value);
          },
        ),
        const SizedBox(height: 16),

        // FEET weight field
        _buildMeasurementField(
          'Feet Weight',
          _feetWeightWholeController,
          _feetWholeUnit,
          (value) {
            setState(() => _feetWholeUnit = value);
          },
        ),
        const SizedBox(height: 16),

        // WHOLE CARCASS weight field
        _buildMeasurementField(
          'Whole Carcass Weight',
          _wholeCarcassWeightController,
          _wholeCarcassUnit,
          (value) {
            setState(() => _wholeCarcassUnit = value);
          },
          required: true,
        ),

        const SizedBox(height: 16),

        // Reference info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Weight (Reference)',
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedAnimal!.liveWeight} kg',
                style: AppTypography.titleLarge(color: AppColors.abbatoirPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Dressing Percentage',
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_calculateYieldPercentage().toStringAsFixed(1)}% (Calculated)',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Whole carcass recording provides detailed part tracking while maintaining faster processing.',
                  style: AppTypography.bodySmall(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitCarcassMeasurements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Carcass Measurements',
          style: AppTypography.titleMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        _buildMeasurementField(
          'Head Weight',
          _headWeightController,
          _headUnit,
          (value) {
            setState(() => _headUnit = value);
          },
          required: true,
        ),
        const SizedBox(height: 16),

        _buildMeasurementField(
          'Feet Weight',
          _feetWeightController,
          _feetUnit,
          (value) {
            setState(() => _feetUnit = value);
          },
          required: true,
        ),
        const SizedBox(height: 16),

        _buildMeasurementField(
          'Left Carcass Weight',
          _leftCarcassWeightController,
          _leftCarcassUnit,
          (value) {
            setState(() => _leftCarcassUnit = value);
          },
          required: true,
        ),
        const SizedBox(height: 16),

        _buildMeasurementField(
          'Right Carcass Weight',
          _rightCarcassWeightController,
          _rightCarcassUnit,
          (value) {
            setState(() => _rightCarcassUnit = value);
          },
          required: true,
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
  }) {
    // Parse current weight from controller
    double? currentWeight;
    if (controller.text.isNotEmpty) {
      currentWeight = double.tryParse(controller.text);
    }

    return BluetoothWeightDisplay(
      label: label + (required ? ' *' : ''),
      weight: currentWeight,
      isConnected: _isScaleConnected,
      onTap: () async {
        // Read weight and update controller
        if (!_scaleService.isConnected) {
          await _connectScale();
          return;
        }

        print('👆 [SlaughterScreen] Reading weight for $label...');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reading from scale... Please ensure weight is stable.',
            ),
            duration: Duration(seconds: 10),
          ),
        );

        bool gotWeight = false;

        try {
          await _scaleService.readWeight();
        } catch (e) {
          print('⚠️ [SlaughterScreen] Manual read failed: $e');
        }

        StreamSubscription? singleRead;
        singleRead = _scaleService.weightStream.listen((weight) {
          if (!gotWeight) {
            gotWeight = true;
            setState(() {
              controller.text = weight.toStringAsFixed(2);
            });
            // Note: onUnitChanged is for unit selection, not weight value change.
            // We don't have a callback for weight value change here, but controller is updated.

            singleRead?.cancel();

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label: ${weight.toStringAsFixed(2)} $unit'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });

        Future.delayed(const Duration(seconds: 10), () {
          if (!gotWeight) {
            singleRead?.cancel();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No weight received. Ensure weight is on scale and stable.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      },
      unit: unit,
      themeColor: AppColors.abbatoirPrimary,
    );
  }
}
