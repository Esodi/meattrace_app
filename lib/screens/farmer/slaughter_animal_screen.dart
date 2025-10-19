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
  final _torsoWeightController = TextEditingController();
  final _frontLegsController = TextEditingController();
  final _hindLegsController = TextEditingController();
  final _organsController = TextEditingController();
  
  // Measurement controller for whole carcass
  final _totalWeightController = TextEditingController();
  
  // Notes
  final _notesController = TextEditingController();
  
  // Unit selections
  String _headUnit = 'kg';
  String _torsoUnit = 'kg';
  String _frontLegsUnit = 'kg';
  String _hindLegsUnit = 'kg';
  String _organsUnit = 'kg';
  String _totalUnit = 'kg';
  
  // Custom measurements
  final List<Map<String, dynamic>> _customMeasurements = [];
  
  // State
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Animal> _availableAnimals = [];
  List<Animal> _filteredAnimals = [];

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
  void dispose() {
    _searchController.dispose();
    _headWeightController.dispose();
    _torsoWeightController.dispose();
    _frontLegsController.dispose();
    _hindLegsController.dispose();
    _organsController.dispose();
    _totalWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableAnimals() async {
    print('🔵 [SlaughterScreen] _loadAvailableAnimals started');
    setState(() => _isLoading = true);
    try {
      print('🔵 [SlaughterScreen] Getting AnimalProvider from context');
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      print('🔵 [SlaughterScreen] AnimalProvider obtained, clearing cache...');
      
      // Clear cache to ensure fresh data
      await animalProvider.clearAnimals();
      
      print('🔵 [SlaughterScreen] Fetching animals with slaughtered=false filter...');
      // Fetch only unslaughtered animals (animals available for slaughter)
      await animalProvider.fetchAnimals(slaughtered: false);
      print('🔵 [SlaughterScreen] Animals fetched, total count: ${animalProvider.animals.length}');
      
      // Filter for active/healthy animals only (not slaughtered, not transferred)
      final animals = animalProvider.animals.where((animal) {
        print('🔍 [SlaughterScreen] Checking animal ${animal.animalId}: slaughtered=${animal.slaughtered}, transferredTo=${animal.transferredTo}, healthStatus=${animal.healthStatus}');
        return !animal.slaughtered &&
          animal.transferredTo == null &&
          (animal.healthStatus == null || 
           animal.healthStatus!.toLowerCase() == 'healthy' ||
           animal.healthStatus!.toLowerCase() == 'active');
      }).toList();
      
      print('✅ [SlaughterScreen] Filtered animals count: ${animals.length}');
      
      setState(() {
        _availableAnimals = animals;
        _filteredAnimals = animals;
        _isLoading = false;
      });

      // Auto-select animal if animalId was provided
      if (widget.animalId != null) {
        print('🔵 [SlaughterScreen] Auto-selecting animal with ID: ${widget.animalId}');
        final targetAnimal = animals.where((animal) => animal.id.toString() == widget.animalId).toList();
        if (targetAnimal.isNotEmpty) {
          _selectAnimal(targetAnimal.first);
        } else {
          print('⚠️ [SlaughterScreen] Animal with ID ${widget.animalId} not found in available animals');
        }
      }
    } catch (e, stackTrace) {
      print('❌ [SlaughterScreen] Error in _loadAvailableAnimals: $e');
      print('❌ [SlaughterScreen] Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      _showError('Failed to load animals: ${e.toString()}');
    }
  }

  void _filterAnimals() {
    print('🔍 [SlaughterScreen] _filterAnimals called with query: "${_searchController.text}"');
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
      print('🔍 [SlaughterScreen] Filtered results: ${_filteredAnimals.length} animals');
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

  double _calculateTotalWeight() {
    if (_carcassType == 'whole') {
      return double.tryParse(_totalWeightController.text) ?? 0.0;
    }
    
    // Split carcass - sum all parts
    double total = 0.0;
    total += double.tryParse(_headWeightController.text) ?? 0.0;
    total += double.tryParse(_torsoWeightController.text) ?? 0.0;
    total += double.tryParse(_frontLegsController.text) ?? 0.0;
    total += double.tryParse(_hindLegsController.text) ?? 0.0;
    total += double.tryParse(_organsController.text) ?? 0.0;
    
    // Add custom measurements
    for (var measurement in _customMeasurements) {
      total += double.tryParse(measurement['controller'].text) ?? 0.0;
    }
    
    return total;
  }

  double _calculateYieldPercentage() {
    if (_selectedAnimal == null) {
      print('⚠️ [SlaughterScreen] _calculateYieldPercentage called with null _selectedAnimal');
      return 0.0;
    }
    
    final liveWeight = _selectedAnimal?.liveWeight ?? 0.0;
    final carcassWeight = _calculateTotalWeight();
    
    if (liveWeight == 0) return 0.0;
    return (carcassWeight / liveWeight) * 100;
  }

  void _addCustomMeasurement() {
    setState(() {
      _customMeasurements.add({
        'name': TextEditingController(),
        'controller': TextEditingController(),
        'unit': 'kg',
      });
    });
  }

  void _removeCustomMeasurement(int index) {
    setState(() {
      _customMeasurements[index]['name'].dispose();
      _customMeasurements[index]['controller'].dispose();
      _customMeasurements.removeAt(index);
    });
  }

  Future<void> _confirmAndSlaughter() async {
    print('🔵 [SlaughterScreen] _confirmAndSlaughter called');
    
    if (_selectedAnimal == null) {
      print('❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _confirmAndSlaughter');
      _showError('Error: No animal selected');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      print('⚠️ [SlaughterScreen] Form validation failed');
      _showError('Please fill in all required fields');
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

    print('✅ [SlaughterScreen] Showing confirmation dialog');
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Text('Confirm Slaughter'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animal: ${_selectedAnimal!.species} ${_selectedAnimal!.animalId}',
              style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${_carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass'}',
              style: AppTypography.bodyMedium(),
            ),
            Text(
              'Total Weight: ${totalWeight.toStringAsFixed(1)} kg',
              style: AppTypography.bodyMedium(),
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
                'This action is permanent and cannot be undone. The animal will be marked as slaughtered and measurements recorded.',
                style: AppTypography.bodySmall(color: AppColors.warning),
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
            label: 'Confirm',
            onPressed: () => Navigator.of(context).pop(true),
            customColor: AppColors.farmerPrimary,
            fullWidth: false,
          ),
        ],
      ),
    );

    if (confirmed != true) {
      print('⚠️ [SlaughterScreen] User cancelled slaughter confirmation');
      return;
    }

    print('✅ [SlaughterScreen] User confirmed slaughter, proceeding...');
    await _performSlaughter();
  }

  Future<void> _performSlaughter() async {
    print('🔵 [SlaughterScreen] _performSlaughter started');
    
    if (_selectedAnimal == null) {
      print('❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _performSlaughter');
      _showError('Error: No animal selected');
      return;
    }
    
    setState(() => _isSubmitting = true);

    try {
      print('🔵 [SlaughterScreen] Creating DioClient');
      final dioClient = DioClient();
      
      print('🔵 [SlaughterScreen] Creating carcass measurements FIRST (before marking as slaughtered)');
      // STEP 1: Create carcass measurements FIRST
      Map<String, dynamic> measurements = {};
      
      if (_carcassType == 'split') {
        // Add split carcass measurements
        if (_headWeightController.text.isNotEmpty) {
          measurements['head_weight'] = {
            'value': double.parse(_headWeightController.text),
            'unit': _headUnit,
          };
        }
        if (_torsoWeightController.text.isNotEmpty) {
          measurements['torso_weight'] = {
            'value': double.parse(_torsoWeightController.text),
            'unit': _torsoUnit,
          };
        }
        if (_frontLegsController.text.isNotEmpty) {
          measurements['front_legs_weight'] = {
            'value': double.parse(_frontLegsController.text),
            'unit': _frontLegsUnit,
          };
        }
        if (_hindLegsController.text.isNotEmpty) {
          measurements['hind_legs_weight'] = {
            'value': double.parse(_hindLegsController.text),
            'unit': _hindLegsUnit,
          };
        }
        if (_organsController.text.isNotEmpty) {
          measurements['organs_weight'] = {
            'value': double.parse(_organsController.text),
            'unit': _organsUnit,
          };
        }
        
        // Add custom measurements
        for (var measurement in _customMeasurements) {
          final name = (measurement['name'] as TextEditingController).text;
          final value = (measurement['controller'] as TextEditingController).text;
          if (name.isNotEmpty && value.isNotEmpty) {
            measurements[name.toLowerCase().replaceAll(' ', '_')] = {
              'value': double.parse(value),
              'unit': measurement['unit'],
            };
          }
        }
      } else {
        // Whole carcass - single measurement
        measurements['total_carcass_weight'] = {
          'value': double.parse(_totalWeightController.text),
          'unit': _totalUnit,
        };
      }

      // Add metadata
      measurements['carcass_type'] = _carcassType;
      if (_notesController.text.isNotEmpty) {
        measurements['notes'] = _notesController.text;
      }

      print('🔵 [SlaughterScreen] Measurements prepared: $measurements');
      print('🔵 [SlaughterScreen] Carcass type before API call: $_carcassType');
      print('🔵 [SlaughterScreen] Creating carcass measurement record');
      
      // Create carcass measurement record
      // IMPORTANT: Backend expects 'animal' (not 'animal_id') which is the database ID
      // NOTE: The backend automatically marks the animal as slaughtered when carcass measurements are created
      try {
        final measurementData = {
          'animal': _selectedAnimal!.id,  // Backend expects 'animal' field with the ID
          'carcass_type': _carcassType,
          'measurements': measurements,
        };
        print('🔵 [SlaughterScreen] Measurement data: $measurementData');
        
        final measurementResponse = await dioClient.dio.post(
          '/carcass-measurements/',
          data: measurementData,
        );
        print('✅ [SlaughterScreen] Carcass measurements created - Response: ${measurementResponse.statusCode}');
        print('✅ [SlaughterScreen] Animal automatically marked as slaughtered by backend');
        
        // STEP 2: For split carcass, create individual slaughter parts from measurements
        print('🔍 [SlaughterScreen] Checking carcass type: $_carcassType');
        if (_carcassType == 'split') {
          print('🔵 [SlaughterScreen] ✓ Carcass type is SPLIT - Creating slaughter parts...');
          print('🔍 [SlaughterScreen] Measurements object: $measurements');
          print('🔍 [SlaughterScreen] Measurements type: ${measurements.runtimeType}');
          print('🔍 [SlaughterScreen] Measurements length: ${measurements.length} entries');
          
          // Map of part names to standardized part types
          final partTypeMap = {
            'head_weight': 'Head',
            'torso_weight': 'Torso',
            'front_legs_weight': 'Front Legs',
            'hind_legs_weight': 'Hind Legs',
            'organs_weight': 'Organs',
          };
          
          int partsCreated = 0;
          int entriesProcessed = 0;
          
          for (var entry in measurements.entries) {
            entriesProcessed++;
            final measurementKey = entry.key;
            final measurementValue = entry.value;
            
            print('🔍 [SlaughterScreen] Processing entry #$entriesProcessed: key="$measurementKey", value=$measurementValue, type=${measurementValue.runtimeType}');
            
            // Skip metadata fields
            if (measurementKey == 'carcass_type' || measurementKey == 'notes') {
              print('  ⏭️  Skipping metadata field: $measurementKey');
              continue;
            }
            
            // Check if it's a weight measurement (has 'value' and 'unit')
            print('  🔍 Checking if value is Map: ${measurementValue is Map}');
            if (measurementValue is Map) {
              print('  🔍 Contains "value" key: ${measurementValue.containsKey('value')}');
              print('  🔍 Map contents: $measurementValue');
            }
            
            if (measurementValue is Map && measurementValue.containsKey('value')) {
              final partType = partTypeMap[measurementKey] ?? 
                  measurementKey.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
              
              final weight = measurementValue['value'];
              final unit = measurementValue['unit'] ?? 'kg';
              
              print('  📦 Preparing to create part: $partType');
              print('     - Weight: $weight (${weight.runtimeType})');
              print('     - Unit: $unit');
              print('     - Animal ID: ${_selectedAnimal!.id}');
              
              final partData = {
                'animal': _selectedAnimal!.id,
                'part_type': partType,
                'weight': weight,
                'weight_unit': unit,
                'description': 'Created from slaughter measurements',
              };
              print('     - POST data: $partData');
              
              try {
                print('  🚀 Sending POST request to /slaughter-parts/...');
                final partResponse = await dioClient.dio.post(
                  '/slaughter-parts/',
                  data: partData,
                );
                partsCreated++;
                print('  ✅ SUCCESS! Part created: $partType ($weight $unit)');
                print('     - Response status: ${partResponse.statusCode}');
                print('     - Response data: ${partResponse.data}');
              } catch (partError) {
                print('  ❌ FAILED to create slaughter part: $partType');
                print('     - Error: $partError');
                print('     - Error type: ${partError.runtimeType}');
                if (partError.toString().contains('DioException')) {
                  print('     - DioException details: $partError');
                }
                // Continue creating other parts even if one fails
              }
            } else {
              print('  ⏭️  Skipping entry (not a valid weight measurement): $measurementKey');
            }
          }
          
          print('🎯 [SlaughterScreen] SUMMARY:');
          print('   - Total entries in measurements: ${measurements.length}');
          print('   - Entries processed: $entriesProcessed');
          print('   - Parts successfully created: $partsCreated');
          
          if (partsCreated == 0) {
            print('⚠️ [SlaughterScreen] WARNING: NO slaughter parts were created!');
          } else {
            print('✅ [SlaughterScreen] Created $partsCreated slaughter parts');
          }
        } else {
          print('⏭️ [SlaughterScreen] Carcass type is WHOLE - skipping slaughter parts creation');
        }
      } catch (measurementError) {
        print('❌ [SlaughterScreen] Error creating carcass measurements: $measurementError');
        print('❌ [SlaughterScreen] Error type: ${measurementError.runtimeType}');
        throw Exception('Failed to create carcass measurements: $measurementError');
      }

      // Refresh animal list - FORCE FULL REFRESH (no cache)
      if (mounted) {
        print('🔵 [SlaughterScreen] Refreshing animal list - FULL REFRESH');
        final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
        // Clear local cache to force fresh data from server
        animalProvider.clearAnimals();
        // Fetch ALL animals (slaughtered + active)
        await animalProvider.fetchAnimals(slaughtered: null);
        print('✅ [SlaughterScreen] Animal list refreshed with ALL animals (slaughtered + active)');
        
        // Log slaughter activity
        print('🔵 [SlaughterScreen] Logging slaughter activity');
        try {
          final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
          await activityProvider.logSlaughter(
            animalId: _selectedAnimal!.id.toString(),
            animalTag: _selectedAnimal!.animalId,
          );
          print('✅ [SlaughterScreen] Slaughter activity logged');
        } catch (activityError) {
          print('⚠️ [SlaughterScreen] Failed to log activity: $activityError');
          // Non-critical error, continue
        }
      }

      setState(() => _isSubmitting = false);

      // Show success dialog
      if (mounted) {
        print('✅ [SlaughterScreen] Showing success dialog');
        _showSuccessDialog();
      }
    } catch (e, stackTrace) {
      print('❌ [SlaughterScreen] Error in _performSlaughter: $e');
      print('❌ [SlaughterScreen] Stack trace: $stackTrace');
      setState(() => _isSubmitting = false);
      _showError('Failed to record slaughter: ${e.toString()}');
    }
  }

  void _showSuccessDialog() {
    print('🔵 [SlaughterScreen] _showSuccessDialog called');
    
    if (_selectedAnimal == null) {
      print('❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _showSuccessDialog');
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
            _buildSuccessItem('Carcass Weight', '${_calculateTotalWeight().toStringAsFixed(1)} kg'),
            _buildSuccessItem('Parts Recorded', _carcassType == 'split' ? '${_customMeasurements.length + 5}' : '1'),
            _buildSuccessItem('Type', _carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass'),
            const SizedBox(height: 16),
            Text(
              'Next Steps:',
              style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• Create products from carcass', style: AppTypography.bodySmall()),
            Text('• View carcass details', style: AppTypography.bodySmall()),
            Text('• Transfer to processing unit', style: AppTypography.bodySmall()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/farmer-home');
            },
            child: const Text('Done'),
          ),
          CustomButton(
            label: 'View Details',
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/animals/${_selectedAnimal!.id}');
            },
            customColor: AppColors.farmerPrimary,
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
          Text(label + ':', style: AppTypography.bodyMedium(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 [SlaughterScreen] build called - currentStep: $_currentStep, isSubmitting: $_isSubmitting');
    print('🔵 [SlaughterScreen] selectedAnimal: ${_selectedAnimal?.animalId ?? "null"}');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.farmerPrimary,
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
                  Text('Recording slaughter...'),
                ],
              ),
            )
          : IndexedStack(
              index: _currentStep,
              children: [
                _buildAnimalSelectionStep(),
                _buildCarcassTypeStep(),
                _buildMeasurementStep(),
              ],
            ),
    );
  }

  Widget _buildAnimalSelectionStep() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: CustomTextField(
            controller: _searchController,
            label: 'Search animals',
            hint: 'Enter animal ID, name, species, or breed',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
        ),

        // Animal list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAnimals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets_outlined, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No active animals available'
                                : 'No animals match your search',
                            style: AppTypography.bodyLarge(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Only healthy, active animals can be slaughtered',
                            style: AppTypography.bodySmall(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAnimals.length,
                      itemBuilder: (context, index) {
                        final animal = _filteredAnimals[index];
                        return _buildAnimalCard(animal);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    return CustomCard(
      onTap: () => _selectAnimal(animal),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.farmerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getSpeciesEmoji(animal.species),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.animalId,
                    style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (animal.animalName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      animal.animalName!,
                      style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip('Breed: ${animal.breed ?? 'N/A'}'),
                      const SizedBox(width: 8),
                      _buildInfoChip('${animal.age.toInt()}m'),
                      const SizedBox(width: 8),
                      _buildInfoChip('${animal.liveWeight ?? 0} kg'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        animal.healthStatus ?? 'Healthy',
                        style: AppTypography.bodySmall(color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(Icons.arrow_forward_ios, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
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
    print('🔵 [SlaughterScreen] _buildCarcassTypeStep called');
    
    if (_selectedAnimal == null) {
      print('❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _buildCarcassTypeStep');
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
              customColor: AppColors.farmerPrimary,
            ),
          ],
        ),
      );
    }
    
    print('✅ [SlaughterScreen] Selected animal: ${_selectedAnimal!.animalId}');
    
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
                          style: AppTypography.titleLarge().copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedAnimal!.breed ?? _selectedAnimal!.species} • ${_selectedAnimal!.liveWeight} kg • ${_selectedAnimal!.age}m',
                          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
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
            style: AppTypography.titleLarge().copyWith(fontWeight: FontWeight.w600),
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
                    activeColor: AppColors.farmerPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Whole Carcass',
                          style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record total weight only',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Single measurement • Faster recording',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary).copyWith(fontStyle: FontStyle.italic),
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
                    activeColor: AppColors.farmerPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split Carcass',
                          style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record individual parts',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Head, Torso, Legs, Organs • Better traceability',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary).copyWith(fontStyle: FontStyle.italic),
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
            customColor: AppColors.farmerPrimary,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementStep() {
    print('🔵 [SlaughterScreen] _buildMeasurementStep called');
    
    if (_selectedAnimal == null) {
      print('❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _buildMeasurementStep');
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
              customColor: AppColors.farmerPrimary,
            ),
          ],
        ),
      );
    }
    
    print('✅ [SlaughterScreen] Selected animal: ${_selectedAnimal!.animalId}');
    
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
                      style: AppTypography.titleLarge().copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${_carcassType == 'split' ? 'Split Carcass' : 'Whole Carcass'}',
                      style: AppTypography.bodyMedium(color: AppColors.textSecondary),
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
                color: AppColors.farmerPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.farmerPrimary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Carcass Weight',
                    style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_calculateTotalWeight().toStringAsFixed(1)} kg',
                    style: AppTypography.displaySmall(
                      color: AppColors.farmerPrimary,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Live Weight: ${_selectedAnimal!.liveWeight} kg',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Yield: ${_calculateYieldPercentage().toStringAsFixed(1)}%',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
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
              customColor: AppColors.farmerPrimary,
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWholeCarcassMeasurements() {
    print('🔵 [SlaughterScreen] _buildWholeCarcassMeasurements called');
    
    if (_selectedAnimal == null) {
      print('❌ [SlaughterScreen] ERROR: _selectedAnimal is null in _buildWholeCarcassMeasurements');
      return Center(child: Text('Error: No animal selected', style: AppTypography.bodyLarge(color: AppColors.error)));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Carcass Weight',
          style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _totalWeightController,
                label: 'Weight',
                hint: 'Enter total weight',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Weight is required';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Enter valid weight';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _totalUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: ['kg', 'lbs', 'g'].map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: (value) => setState(() => _totalUnit = value!),
              ),
            ),
          ],
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
                style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedAnimal!.liveWeight} kg',
                style: AppTypography.titleLarge(color: AppColors.farmerPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Dressing Percentage',
                style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600),
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
                  'Whole carcass recording is faster but provides less detailed part tracking.',
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
          'Standard Measurements',
          style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        _buildMeasurementField('Head Weight', _headWeightController, _headUnit, (value) {
          setState(() => _headUnit = value);
        }),
        const SizedBox(height: 16),

        _buildMeasurementField('Torso Weight', _torsoWeightController, _torsoUnit, (value) {
          setState(() => _torsoUnit = value);
        }, required: true),
        const SizedBox(height: 16),

        _buildMeasurementField('Front Legs (Pair)', _frontLegsController, _frontLegsUnit, (value) {
          setState(() => _frontLegsUnit = value);
        }),
        const SizedBox(height: 16),

        _buildMeasurementField('Hind Legs (Pair)', _hindLegsController, _hindLegsUnit, (value) {
          setState(() => _hindLegsUnit = value);
        }),
        const SizedBox(height: 16),

        _buildMeasurementField('Organs (Optional)', _organsController, _organsUnit, (value) {
          setState(() => _organsUnit = value);
        }),

        const SizedBox(height: 24),

        // Custom measurements
        if (_customMeasurements.isNotEmpty) ...[
          Text(
            'Custom Measurements',
            style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          
          ..._customMeasurements.asMap().entries.map((entry) {
            final index = entry.key;
            final measurement = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: measurement['name'],
                      label: 'Part Name',
                      hint: 'e.g., Tail, Hide',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: measurement['controller'],
                      label: 'Weight',
                      hint: '0.0',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: measurement['unit'],
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: ['kg', 'lbs', 'g'].map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => measurement['unit'] = value!);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _removeCustomMeasurement(index),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
        ],

        // Add custom measurement button
        OutlinedButton.icon(
          onPressed: _addCustomMeasurement,
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Measurement'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.farmerPrimary,
            side: BorderSide(color: AppColors.farmerPrimary),
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: CustomTextField(
            controller: controller,
            label: label,
            hint: 'Enter weight',
            keyboardType: TextInputType.number,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Invalid';
                    }
                    return null;
                  }
                : null,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: unit,
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            items: ['kg', 'lbs', 'g'].map((u) {
              return DropdownMenuItem(value: u, child: Text(u));
            }).toList(),
            onChanged: (value) => onUnitChanged(value!),
          ),
        ),
      ],
    );
  }
}
