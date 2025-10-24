import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/animal_provider.dart';
import '../../providers/activity_provider.dart';
import '../../models/animal.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/status_badge.dart';

/// Receive Animals Screen - Processor accepts incoming animal transfers
class ReceiveAnimalsScreen extends StatefulWidget {
  const ReceiveAnimalsScreen({super.key});

  @override
  State<ReceiveAnimalsScreen> createState() => _ReceiveAnimalsScreenState();
}

class _ReceiveAnimalsScreenState extends State<ReceiveAnimalsScreen> {
  bool _isLoading = false;
  List<Animal> _pendingAnimals = [];
  
  // State management for whole animals and parts
  final Set<int> _selectedWholeAnimals = {};
  final Map<int, List<int>> _selectedPartsByAnimal = {};  // animal_id -> [part_ids]
  final Map<int, bool> _expandedAnimals = {};             // Track expanded cards

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingAnimals();
    });
  }

  Future<void> _loadPendingAnimals() async {
    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);

      // Fetch all animals - backend now filters by processing unit automatically
      // based on user's role and linked processing unit
      await animalProvider.fetchAnimals(slaughtered: null);

      // Filter for animals that are transferred but not yet received
      // The backend get_queryset() already filters to show only animals
      // transferred to this processing unit (whole or parts)
      final pending = animalProvider.animals.where((animal) {
        // Check if whole animal is transferred OR if any parts are transferred
        final hasTransferredParts = animal.hasSlaughterParts && 
            animal.slaughterParts.any((p) => p.isTransferred);
        final wholeAnimalTransferred = animal.transferredTo != null;
        
        return (wholeAnimalTransferred || hasTransferredParts) && 
               animal.receivedBy == null;
      }).toList();

      print('🔍 RECEIVE_SCREEN - Total animals from API: ${animalProvider.animals.length}');
      print('🔍 RECEIVE_SCREEN - Pending to receive: ${pending.length}');
      
      setState(() => _pendingAnimals = pending);
    } catch (e) {
      print('❌ RECEIVE_SCREEN - Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading animals: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _receiveSelectedAnimals() async {
    if (_selectedWholeAnimals.isEmpty && _selectedPartsByAnimal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select animals or parts to receive')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      
      // Build part receives array: [{animal_id: X, part_ids: [1,2,3]}, ...]
      final partReceives = _selectedPartsByAnimal.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => {
            'animal_id': entry.key,
            'part_ids': entry.value,
          })
          .toList();
      
      // Receive animals and parts
      await animalProvider.receiveAnimals(
        _selectedWholeAnimals.toList(),
        partReceives: partReceives,
      );
      
      // Refresh the animal list - fetch all animals
      await animalProvider.fetchAnimals(slaughtered: null);

      // Calculate total items received
      final totalAnimals = _selectedWholeAnimals.length;
      final totalParts = _selectedPartsByAnimal.values.fold<int>(
        0, (sum, parts) => sum + parts.length
      );
      
      // Log activities based on receive type
      if (totalAnimals > 0 && partReceives.isEmpty) {
        // Only whole animals received
        await activityProvider.logReceive(count: totalAnimals);
      } else if (totalAnimals == 0 && partReceives.isNotEmpty) {
        // Only parts received
        for (var partReceive in partReceives) {
          final animalId = partReceive['animal_id'];
          final animal = _pendingAnimals.firstWhere((a) => a.id == animalId);
          final partIds = partReceive['part_ids'] as List<int>;
          final parts = animal.slaughterParts.where((p) => partIds.contains(p.id)).toList();
          final partTypes = parts.map((p) => _getPartLabel(p)).toList();
          
          await activityProvider.logPartReceive(
            animalId: animalId.toString(),
            animalTag: animal.animalId,
            partTypes: partTypes,
          );
        }
      } else {
        // Mixed receive (whole animals + parts)
        await activityProvider.logMixedReceive(
          wholeAnimalCount: totalAnimals,
          partReceiveCount: partReceives.length,
        );
      }
      
      String message;
      if (totalAnimals > 0 && totalParts > 0) {
        message = 'Successfully received $totalAnimals animal(s) and $totalParts part(s)';
      } else if (totalAnimals > 0) {
        message = 'Successfully received $totalAnimals animal(s)';
      } else {
        message = 'Successfully received $totalParts part(s)';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error receiving animals: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final hasSelections = _selectedWholeAnimals.isNotEmpty || _selectedPartsByAnimal.isNotEmpty;
    final totalAnimals = _selectedWholeAnimals.length;
    final totalParts = _selectedPartsByAnimal.values.fold<int>(0, (sum, parts) => sum + parts.length);
    
    String selectionText;
    if (totalAnimals > 0 && totalParts > 0) {
      selectionText = '$totalAnimals animal(s), $totalParts part(s)';
    } else if (totalAnimals > 0) {
      selectionText = '$totalAnimals Selected';
    } else if (totalParts > 0) {
      selectionText = '$totalParts part(s)';
    } else {
      selectionText = '';
    }
    
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
          'Receive Animals',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          if (hasSelections)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.processorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    selectionText,
                    style: AppTypography.labelMedium().copyWith(
                      color: AppColors.processorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.processorPrimary,
              ),
            )
          : _pendingAnimals.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildInfoBanner(),
                    _buildActionButtons(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPendingAnimals,
                        color: AppColors.processorPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          itemCount: _pendingAnimals.length,
                          itemBuilder: (context, index) {
                            final animal = _pendingAnimals[index];
                            return _buildAnimalCard(animal);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: hasSelections
          ? Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  label: totalAnimals > 0 && totalParts > 0
                      ? 'Receive $totalAnimals Animal(s) & $totalParts Part(s)'
                      : totalAnimals > 0
                          ? 'Receive $totalAnimals Animal(s)'
                          : 'Receive $totalParts Part(s)',
                  onPressed: _isLoading ? null : _receiveSelectedAnimals,
                  loading: _isLoading,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.info,
            size: 24,
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Transfers',
                  style: AppTypography.labelLarge().copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  '${_pendingAnimals.length} animal(s) waiting to be received',
                  style: AppTypography.bodyMedium().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasAnySelections = _selectedWholeAnimals.isNotEmpty || _selectedPartsByAnimal.isNotEmpty;
    final allWholePendingSelected = _pendingAnimals
        .where((a) => !a.isSplitCarcass || !a.hasSlaughterParts)
        .every((a) => _selectedWholeAnimals.contains(a.id));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  if (allWholePendingSelected && hasAnySelections) {
                    // Deselect all
                    _selectedWholeAnimals.clear();
                    _selectedPartsByAnimal.clear();
                  } else {
                    // Select all whole animals
                    _selectedWholeAnimals.addAll(
                      _pendingAnimals
                          .where((a) => !a.isSplitCarcass || !a.hasSlaughterParts)
                          .map((a) => a.id!)
                    );
                    // Select all transferred parts from split carcass animals
                    for (var animal in _pendingAnimals.where((a) => a.isSplitCarcass && a.hasSlaughterParts)) {
                      final transferredParts = animal.slaughterParts
                          .where((p) => p.isTransferred)
                          .map((p) => p.id!)
                          .toList();
                      if (transferredParts.isNotEmpty) {
                        _selectedPartsByAnimal[animal.id!] = transferredParts;
                      }
                    }
                  }
                });
              },
              icon: Icon(
                allWholePendingSelected && hasAnySelections
                    ? Icons.deselect
                    : Icons.select_all,
                size: 20,
              ),
              label: Text(
                allWholePendingSelected && hasAnySelections
                    ? 'Deselect All'
                    : 'Select All',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.processorPrimary,
                side: BorderSide(color: AppColors.processorPrimary),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: !hasAnySelections
                  ? null
                  : () {
                      setState(() {
                        _selectedWholeAnimals.clear();
                        _selectedPartsByAnimal.clear();
                      });
                    },
              icon: const Icon(Icons.clear, size: 20),
              label: const Text('Clear'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final isSplitCarcass = animal.isSplitCarcass && animal.hasSlaughterParts;
    final isExpanded = _expandedAnimals[animal.id] ?? false;
    
    // For whole carcass or when parts aren't loaded
    if (!isSplitCarcass) {
      final isSelected = _selectedWholeAnimals.contains(animal.id);
      
      return Card(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(
            color: isSelected
                ? AppColors.processorPrimary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWholeAnimals.remove(animal.id);
              } else {
                _selectedWholeAnimals.add(animal.id!);
              }
            });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                // Selection Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedWholeAnimals.add(animal.id!);
                      } else {
                        _selectedWholeAnimals.remove(animal.id);
                      }
                    });
                  },
                  activeColor: AppColors.processorPrimary,
                ),
                const SizedBox(width: AppTheme.space12),

                // Animal Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.processorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    _getSpeciesIcon(animal.species),
                    color: AppColors.processorPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),

                // Animal Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              animal.animalId,
                              style: AppTypography.bodyLarge().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space8,
                              vertical: AppTheme.space4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              'Whole Carcass',
                              style: AppTypography.caption().copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        '${animal.species}${animal.breed != null ? " • ${animal.breed}" : ""}',
                        style: AppTypography.bodyMedium().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Wrap(
                        spacing: AppTheme.space8,
                        runSpacing: AppTheme.space4,
                        children: [
                          _buildInfoChip(
                            Icons.monitor_weight,
                            '${animal.liveWeight ?? 0} kg',
                          ),
                          _buildInfoChip(
                            Icons.calendar_today,
                            '${animal.age} yrs',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Transfer Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(
                      label: 'Pending',
                      color: AppColors.warning,
                    ),
                    if (animal.transferredAt != null) ...[
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        _formatDate(animal.transferredAt!),
                        style: AppTypography.caption().copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // For split carcass with parts - show expandable card
    final selectedPartIds = _selectedPartsByAnimal[animal.id!] ?? [];
    final transferredParts = animal.slaughterParts.where((p) => p.isTransferred).toList();
    final allTransferredSelected = selectedPartIds.length == transferredParts.length &&
        transferredParts.isNotEmpty;
    final somePartsSelected = selectedPartIds.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: somePartsSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: somePartsSelected
              ? AppColors.processorPrimary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedAnimals[animal.id!] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMedium),
              topRight: Radius.circular(AppTheme.radiusMedium),
              bottomLeft: isExpanded ? Radius.zero : Radius.circular(AppTheme.radiusMedium),
              bottomRight: isExpanded ? Radius.zero : Radius.circular(AppTheme.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                children: [
                  // Animal Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.processorPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      _getSpeciesIcon(animal.species),
                      color: AppColors.processorPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),

                  // Animal Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                animal.animalId,
                                style: AppTypography.bodyLarge().copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space8,
                                vertical: AppTheme.space4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Text(
                                'Split Carcass',
                                style: AppTypography.caption().copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          '${animal.species}${animal.breed != null ? " • ${animal.breed}" : ""}',
                          style: AppTypography.bodyMedium().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (somePartsSelected) ...[
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            '${selectedPartIds.length}/${transferredParts.length} parts selected',
                            style: AppTypography.bodySmall().copyWith(
                              color: AppColors.processorPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Expansion indicator and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (somePartsSelected && !allTransferredSelected)
                            Icon(Icons.check_box_outline_blank, color: AppColors.processorPrimary, size: 20)
                          else if (allTransferredSelected)
                            Icon(Icons.check_box, color: AppColors.processorPrimary, size: 20)
                          else
                            Icon(Icons.check_box_outline_blank, 
                                color: AppColors.textSecondary.withValues(alpha: 0.3), size: 20),
                          const SizedBox(width: AppTheme.space8),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      StatusBadge(
                        label: 'Pending',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable part list
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transferred Parts',
                        style: AppTypography.bodyMedium().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (allTransferredSelected) {
                              // Deselect all
                              _selectedPartsByAnimal[animal.id!] = [];
                            } else {
                              // Select all transferred parts
                              _selectedPartsByAnimal[animal.id!] = transferredParts
                                  .map((p) => p.id!)
                                  .toList();
                            }
                          });
                        },
                        icon: Icon(
                          allTransferredSelected ? Icons.deselect : Icons.select_all,
                          size: 18,
                        ),
                        label: Text(allTransferredSelected ? 'Deselect All' : 'Select All'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.processorPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  ...transferredParts.map((part) {
                    final isPartSelected = selectedPartIds.contains(part.id);
                    
                    return CheckboxListTile(
                      value: isPartSelected,
                      onChanged: (selected) {
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
                      activeColor: AppColors.processorPrimary,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
                      title: Text(
                        _getPartLabel(part),
                        style: AppTypography.bodyMedium(),
                      ),
                      subtitle: Text(
                        '${part.weight.toStringAsFixed(2)} ${part.weightUnit}',
                        style: AppTypography.bodySmall().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: AppTheme.space4),
          Text(
            label,
            style: AppTypography.caption().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.processorPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox,
                size: 60,
                color: AppColors.processorPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'No Pending Transfers',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'There are no animals waiting to be received.\nCheck back later for new transfers.',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            OutlinedButton.icon(
              onPressed: _loadPendingAnimals,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.processorPrimary,
                side: BorderSide(color: AppColors.processorPrimary),
              ),
            ),
          ],
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Helper to get proper label for parts of type 'other'
  String _getPartLabel(SlaughterPart part) {
    if (part.partType == SlaughterPartType.other && part.description != null) {
      final regex = RegExp(r'Created from (.+) measurement');
      final match = regex.firstMatch(part.description!);
      if (match != null) {
        var key = match.group(1)!;
        // Remove '_weight' suffix if present
        key = key.replaceAll('_weight', '');
        
        // Map common measurement keys to proper anatomical names
        final Map<String, String> anatomicalNames = {
          'head': 'Head',
          'torso': 'Torso',
          'front_legs': 'Front Legs',
          'hind_legs': 'Hind Legs',
          'organs': 'Organs',
          'neck': 'Neck',
          'shoulder': 'Shoulder',
          'loin': 'Loin',
          'leg': 'Leg',
          'breast': 'Breast',
          'ribs': 'Ribs',
          'flank': 'Flank',
          'belly': 'Belly',
          'back': 'Back',
          'tail': 'Tail',
          'hide': 'Hide',
          'skin': 'Skin',
          'feet': 'Feet',
          'hooves': 'Hooves',
          'wings': 'Wings',
          'thighs': 'Thighs',
          'drumsticks': 'Drumsticks',
          'liver': 'Liver',
          'heart': 'Heart',
          'kidneys': 'Kidneys',
          'lungs': 'Lungs',
          'intestines': 'Intestines',
          'stomach': 'Stomach',
          'tongue': 'Tongue',
          'brain': 'Brain',
          'total_carcass': 'Total Carcass',
        };
        
        // Check if we have a predefined name for this key
        if (anatomicalNames.containsKey(key)) {
          return anatomicalNames[key]!;
        }
        
        // Otherwise, format the key by replacing underscores and capitalizing
        key = key.replaceAll('_', ' ');
        key = key.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
        return key;
      }
    }
    return part.partType.displayName;
  }
}
