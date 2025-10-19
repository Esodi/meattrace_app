import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/animal.dart';
import '../../models/processing_unit.dart';
import '../../providers/animal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_card.dart';

class TransferAnimalsScreen extends StatefulWidget {
  const TransferAnimalsScreen({Key? key}) : super(key: key);

  @override
  State<TransferAnimalsScreen> createState() => _TransferAnimalsScreenState();
}

class _TransferAnimalsScreenState extends State<TransferAnimalsScreen> {
  int _currentStep = 0;
  final List<Animal> _selectedWholeAnimals = []; // For whole carcass transfers
  final Map<int, List<int>> _selectedPartsByAnimal = {}; // animalId -> List of partIds
  ProcessingUnit? _selectedProcessingUnit;
  bool _isLoading = false;
  List<Animal> _availableAnimals = [];
  List<ProcessingUnit> _processingUnits = [];
  final Map<int, bool> _expandedAnimals = {}; // Track expanded state for split carcass animals

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      
      // Fetch available animals (only slaughtered, not transferred)
      final animalsResponse = await dio.get('/animals/');
      final animalsList = (animalsResponse.data['results'] as List)
          .map((json) => Animal.fromMap(json))
          .where((animal) => animal.slaughtered && animal.transferredTo == null)
          .toList();
      
      // Fetch processing units
      final unitsResponse = await dio.get('/processing-units/');
      final unitsList = (unitsResponse.data['results'] as List)
          .map((json) => ProcessingUnit.fromJson(json))
          .toList();
      
      setState(() {
        _availableAnimals = animalsList;
        _processingUnits = unitsList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTransfer() async {
    if ((_selectedWholeAnimals.isEmpty && _selectedPartsByAnimal.isEmpty) || _selectedProcessingUnit == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      
      // Prepare whole animal IDs
      final wholeAnimalIds = _selectedWholeAnimals.map((a) => a.id).toList();
      
      // Prepare part transfers
      final partTransfers = _selectedPartsByAnimal.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => {
                'animal_id': entry.key,
                'part_ids': entry.value,
              })
          .toList();
      
      print('Transfer Submit - Whole Animals: $wholeAnimalIds, Part Transfers: $partTransfers');
      
      // Call the provider method with part transfers
      await animalProvider.transferAnimals(
        wholeAnimalIds,
        _selectedProcessingUnit!.id!,
        partTransfers: partTransfers.isEmpty ? null : partTransfers,
      );
      
      // Log activities based on transfer type
      final processorName = _selectedProcessingUnit!.name;
      
      if (wholeAnimalIds.isNotEmpty && partTransfers.isEmpty) {
        // Only whole animals transferred
        await activityProvider.logTransfer(
          count: wholeAnimalIds.length,
          processorName: processorName,
        );
      } else if (wholeAnimalIds.isEmpty && partTransfers.isNotEmpty) {
        // Only parts transferred
        for (var partTransfer in partTransfers) {
          final animalId = partTransfer['animal_id'];
          final animal = _availableAnimals.firstWhere((a) => a.id == animalId);
          final partIds = partTransfer['part_ids'] as List<int>;
          final parts = animal.slaughterParts.where((p) => partIds.contains(p.id)).toList();
          final partTypes = parts.map((p) => p.partType.displayName).toList();
          
          await activityProvider.logPartTransfer(
            animalId: animalId.toString(),
            animalTag: animal.animalId,
            partTypes: partTypes,
            processorName: processorName,
          );
        }
      } else {
        // Mixed transfer (whole animals + parts)
        await activityProvider.logMixedTransfer(
          wholeAnimalCount: wholeAnimalIds.length,
          partTransferCount: partTransfers.length,
          processorName: processorName,
        );
      }
      
      if (mounted) {
        final totalCount = wholeAnimalIds.length + partTransfers.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transferred $totalCount item(s)!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error transferring animals: $e')),
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
        backgroundColor: AppColors.farmerPrimary,
        foregroundColor: Colors.white,
        title: Text(
          'Transfer Animals',
          style: AppTypography.headlineMedium(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.farmerPrimary,
                ),
              ),
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () {
                if (_currentStep == 0 && _selectedWholeAnimals.isEmpty && _selectedPartsByAnimal.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one animal or parts to transfer')),
                  );
                  return;
                }
                if (_currentStep == 1 && _selectedProcessingUnit == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a processing unit')),
                  );
                  return;
                }
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submitTransfer();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Flexible(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.farmerPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            minimumSize: const Size(120, 48),
                          ),
                          child: Text(_currentStep == 2 ? 'Transfer' : 'Continue'),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Select Animals'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildSelectAnimalsStep(),
                ),
                Step(
                  title: const Text('Select Processing Unit'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildSelectProcessingUnitStep(),
                ),
                Step(
                  title: const Text('Confirm Transfer'),
                  isActive: _currentStep >= 2,
                  content: _buildConfirmStep(),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSelectAnimalsStep() {
    if (_availableAnimals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No animals available for transfer',
                style: AppTypography.titleMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Only slaughtered animals can be transferred',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableAnimals.length,
      itemBuilder: (context, index) {
        final animal = _availableAnimals[index];
        // Check if it's a split carcass - if marked as split, always treat as split with parts
        final isSplitCarcass = animal.isSplitCarcass;
        final isExpanded = _expandedAnimals[animal.id] ?? false;
        
        // For whole carcass only
        if (!isSplitCarcass) {
          final isSelected = _selectedWholeAnimals.contains(animal);
          
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedWholeAnimals.add(animal);
                  } else {
                    _selectedWholeAnimals.remove(animal);
                  }
                });
              },
              activeColor: AppColors.farmerPrimary,
              title: Text(
                animal.animalId,
                style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${animal.species} - ${animal.breed ?? "Unknown breed"}',
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age: ${animal.age} months • Weight: ${animal.liveWeight ?? 0} kg',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Whole Carcass',
                      style: AppTypography.bodySmall(color: AppColors.info),
                    ),
                  ),
                ],
              ),
              secondary: CircleAvatar(
                backgroundColor: AppColors.farmerPrimary.withOpacity(0.1),
                child: Icon(
                  _getSpeciesIcon(animal.species),
                  color: AppColors.farmerPrimary,
                ),
              ),
            ),
          );
        }
        
        // For split carcass - show expandable card for part selection
        // If no parts exist yet, allow selection as whole carcass transfer with split flag
        final hasParts = animal.slaughterParts.isNotEmpty;
        final selectedPartIds = _selectedPartsByAnimal[animal.id!] ?? [];
        final allPartsSelected = hasParts && selectedPartIds.length == animal.slaughterParts.length;
        final somePartsSelected = selectedPartIds.isNotEmpty;
        
        // If no parts, treat as selectable whole animal
        final isWholeAnimalSelected = !hasParts && _selectedWholeAnimals.contains(animal);
        
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.farmerPrimary.withOpacity(0.1),
                  child: Icon(
                    _getSpeciesIcon(animal.species),
                    color: AppColors.farmerPrimary,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        animal.animalId,
                        style: AppTypography.titleMedium().copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Split Carcass',
                        style: AppTypography.bodySmall(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${animal.species} - ${animal.breed ?? "Unknown breed"}',
                      style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    if (hasParts && somePartsSelected)
                      Text(
                        '${selectedPartIds.length}/${animal.slaughterParts.length} parts selected',
                        style: AppTypography.bodySmall(color: AppColors.farmerPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                      )
                    else if (!hasParts && isWholeAnimalSelected)
                      Text(
                        'Whole carcass selected',
                        style: AppTypography.bodySmall(color: AppColors.farmerPrimary)
                            .copyWith(fontWeight: FontWeight.bold),
                      )
                    else if (!hasParts)
                      Text(
                        'No parts defined yet - transfer as whole',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasParts) ...[
                      if (somePartsSelected && !allPartsSelected)
                        Icon(Icons.indeterminate_check_box, color: AppColors.farmerPrimary)
                      else if (allPartsSelected)
                        Icon(Icons.check_box, color: AppColors.farmerPrimary)
                      else
                        Icon(Icons.check_box_outline_blank, color: AppColors.textSecondary.withOpacity(0.3)),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                    ] else ...[
                      if (isWholeAnimalSelected)
                        Icon(Icons.check_box, color: AppColors.farmerPrimary)
                      else
                        Icon(Icons.check_box_outline_blank, color: AppColors.textSecondary.withOpacity(0.3)),
                    ],
                  ],
                ),
                onTap: () {
                  if (hasParts) {
                    setState(() {
                      _expandedAnimals[animal.id!] = !isExpanded;
                    });
                  } else {
                    // No parts - toggle whole animal selection
                    setState(() {
                      if (isWholeAnimalSelected) {
                        _selectedWholeAnimals.remove(animal);
                      } else {
                        _selectedWholeAnimals.add(animal);
                      }
                    });
                  }
                },
              ),
              if (isExpanded && hasParts) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Parts to Transfer',
                            style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (allPartsSelected) {
                                  // Deselect all
                                  _selectedPartsByAnimal[animal.id!] = [];
                                } else {
                                  // Select all
                                  _selectedPartsByAnimal[animal.id!] = animal.slaughterParts
                                      .where((p) => !p.isTransferred)
                                      .map((p) => p.id!)
                                      .toList();
                                }
                              });
                            },
                            icon: Icon(
                              allPartsSelected ? Icons.deselect : Icons.select_all,
                              size: 18,
                            ),
                            label: Text(allPartsSelected ? 'Deselect All' : 'Select All'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.farmerPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...animal.slaughterParts.map((part) {
                        final isPartSelected = selectedPartIds.contains(part.id);
                        final isAlreadyTransferred = part.isTransferred;
                        
                        return CheckboxListTile(
                          value: isPartSelected,
                          enabled: !isAlreadyTransferred,
                          onChanged: isAlreadyTransferred ? null : (selected) {
                            setState(() {
                              if (selected == true) {
                                if (_selectedPartsByAnimal[animal.id!] == null) {
                                  _selectedPartsByAnimal[animal.id!] = [];
                                }
                                _selectedPartsByAnimal[animal.id!]!.add(part.id!);
                              } else {
                                _selectedPartsByAnimal[animal.id!]?.remove(part.id!);
                              }
                            });
                          },
                          activeColor: AppColors.farmerPrimary,
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            part.partType.displayName,
                            style: AppTypography.bodyMedium(
                              color: isAlreadyTransferred 
                                  ? AppColors.textSecondary.withOpacity(0.5)
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${part.weight.toStringAsFixed(2)} ${part.weightUnit}${isAlreadyTransferred ? ' • Already transferred' : ''}',
                            style: AppTypography.bodySmall(
                              color: isAlreadyTransferred
                                  ? AppColors.textSecondary.withOpacity(0.5)
                                  : AppColors.textSecondary,
                            ),
                          ),
                          secondary: isAlreadyTransferred
                              ? Icon(Icons.check_circle, color: AppColors.success, size: 20)
                              : null,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectProcessingUnitStep() {
    if (_processingUnits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.factory_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No processing units available',
                style: AppTypography.titleMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your administrator to add processing units',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _processingUnits.length,
      itemBuilder: (context, index) {
        final unit = _processingUnits[index];
        final isSelected = _selectedProcessingUnit?.id == unit.id;

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            setState(() => _selectedProcessingUnit = unit);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.farmerPrimary.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.processorPrimary.withOpacity(0.1),
                child: Icon(Icons.factory, color: AppColors.processorPrimary),
              ),
              title: Text(
                unit.name,
                style: AppTypography.titleMedium().copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (unit.location != null) 
                    Text(
                      '📍 ${unit.location}',
                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    ),
                  if (unit.contactPhone != null) 
                    Text(
                      '📞 ${unit.contactPhone}',
                      style: AppTypography.bodySmall(color: AppColors.textSecondary),
                    ),
                ],
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: AppColors.farmerPrimary, size: 28)
                  : Icon(Icons.circle_outlined, color: AppColors.textSecondary.withOpacity(0.3)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transfer Summary',
          style: AppTypography.titleLarge().copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Whole Animals Section
        if (_selectedWholeAnimals.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.farmerPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.farmerPrimary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pets, color: AppColors.farmerPrimary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedWholeAnimals.length} Whole ${_selectedWholeAnimals.length == 1 ? "Animal" : "Animals"}',
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_selectedWholeAnimals.map((animal) => Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 4),
                  child: Text(
                    '• ${animal.animalId} (${animal.species})',
                    style: AppTypography.bodyMedium(),
                  ),
                ))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Selected Parts Section
        if (_selectedPartsByAnimal.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.content_cut, color: AppColors.warning, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Split Carcass Parts',
                      style: AppTypography.titleMedium().copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_selectedPartsByAnimal.entries.map((entry) {
                  final animal = _availableAnimals.firstWhere((a) => a.id == entry.key);
                  final selectedParts = animal.slaughterParts
                      .where((p) => entry.value.contains(p.id))
                      .toList();
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${animal.animalId} (${animal.species})',
                          style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...selectedParts.map((part) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 2),
                          child: Text(
                            '• ${part.partType.displayName} - ${part.weight.toStringAsFixed(2)} ${part.weightUnit}',
                            style: AppTypography.bodySmall(color: AppColors.textSecondary),
                          ),
                        )),
                      ],
                    ),
                  );
                })),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Destination Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.processorPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.processorPrimary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.factory, color: AppColors.processorPrimary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Destination',
                    style: AppTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProcessingUnit?.name ?? '',
                      style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_selectedProcessingUnit?.location != null)
                      Text(
                        'Location: ${_selectedProcessingUnit!.location}',
                        style: AppTypography.bodyMedium(),
                      ),
                    if (_selectedProcessingUnit?.contactPhone != null)
                      Text(
                        'Phone: ${_selectedProcessingUnit!.contactPhone}',
                        style: AppTypography.bodyMedium(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This action will transfer the selected animals to the processing unit. The receiving unit will need to accept the transfer.',
                  style: AppTypography.bodySmall(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      ],
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
