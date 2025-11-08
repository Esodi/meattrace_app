import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/animal.dart';
import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/anatomical_name_mapping.dart';
import '../../widgets/core/status_badge.dart';
import '../../widgets/core/custom_button.dart';
import '../farmer/animal_detail_screen.dart';

/// Pending Processing Screen - Shows received animals/parts not yet processed into products
class PendingProcessingScreen extends StatefulWidget {
  const PendingProcessingScreen({super.key});

  @override
  State<PendingProcessingScreen> createState() => _PendingProcessingScreenState();
}

class _PendingProcessingScreenState extends State<PendingProcessingScreen> {
  bool _isLoading = false;
  List<Animal> _pendingAnimals = [];
  final Map<int, bool> _expandedAnimals = {}; // Track expanded state for split carcass
  String _searchQuery = '';
  String _selectedSpecies = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingProcessing();
    });
  }

  Future<void> _loadPendingProcessing() async {
    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Fetch all animals
      await animalProvider.fetchAnimals(slaughtered: null);

      final processingUnitId = authProvider.user?.processingUnitId;

      if (processingUnitId != null) {
        // Filter for animals/parts that are:
        // 1. Received by this processor (whole or parts)
        // 2. Not yet fully converted to products
        final pending = animalProvider.animals.where((animal) {
          // Check if whole animal is received and not used in product
          final wholeAnimalReceived = animal.receivedBy != null && 
                                       animal.transferredTo == processingUnitId;
          final wholeAnimalNotUsed = !animal.usedInProduct;
          final wholeAnimalPending = wholeAnimalReceived && wholeAnimalNotUsed;

          // Check if any parts are received and not used in product
          final hasPendingParts = animal.hasSlaughterParts &&
              animal.slaughterParts.any((p) => 
                p.receivedBy != null && 
                p.transferredTo == processingUnitId && 
                !p.usedInProduct
              );

          return wholeAnimalPending || hasPendingParts;
        }).toList();

        setState(() => _pendingAnimals = pending);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pending items: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Animal> get _filteredAnimals {
    return _pendingAnimals.where((animal) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          animal.animalId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          animal.species.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (animal.breed?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Species filter
      final matchesSpecies = _selectedSpecies == 'All' ||
          animal.species.toLowerCase() == _selectedSpecies.toLowerCase();

      return matchesSearch && matchesSpecies;
    }).toList();
  }

  List<String> get _availableSpecies {
    final species = _pendingAnimals.map((a) => a.species).toSet().toList();
    species.sort();
    return ['All', ...species];
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _filteredAnimals.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.processorPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Processing',
              style: AppTypography.headlineSmall().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_filteredAnimals.length} item(s) awaiting processing',
              style: AppTypography.caption().copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadPendingProcessing,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.processorPrimary,
              ),
            )
          : Column(
              children: [
                _buildFiltersSection(),
                if (hasData)
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadPendingProcessing,
                      color: AppColors.processorPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        itemCount: _filteredAnimals.length,
                        itemBuilder: (context, index) {
                          final animal = _filteredAnimals[index];
                          return _buildAnimalCard(animal);
                        },
                      ),
                    ),
                  )
                else
                  Expanded(child: _buildEmptyState()),
              ],
            ),
      floatingActionButton: hasData
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-product'),
              backgroundColor: AppColors.processorPrimary,
              icon: const Icon(Icons.add_box),
              label: const Text('Create Product'),
            )
          : null,
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by ID, species, or breed...',
              prefixIcon: Icon(Icons.search, color: AppColors.processorPrimary),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: AppTheme.space12),
          
          // Species filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableSpecies.map((species) {
                final isSelected = _selectedSpecies == species;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.space8),
                  child: FilterChip(
                    label: Text(species),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedSpecies = species);
                    },
                    selectedColor: AppColors.processorPrimary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
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
                Icons.inventory_2_outlined,
                size: 60,
                color: AppColors.processorPrimary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              _searchQuery.isEmpty
                  ? 'No Pending Items'
                  : 'No Items Found',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              _searchQuery.isEmpty
                  ? 'All received animals and parts have been processed into products.\nGreat work!'
                  : 'Try adjusting your search or filters.',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            if (_searchQuery.isEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => context.push('/receive-animals'),
                icon: const Icon(Icons.download),
                label: const Text('Receive Animals'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.processorPrimary,
                  side: BorderSide(color: AppColors.processorPrimary),
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              CustomButton(
                onPressed: _loadPendingProcessing,
                label: 'Refresh',
                icon: Icons.refresh,
                variant: ButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final isSplitCarcass = animal.isSplitCarcass && animal.hasSlaughterParts;
    final isExpanded = _expandedAnimals[animal.id] ?? false;

    // Determine pending status
    final wholeAnimalPending = animal.receivedBy != null && !animal.usedInProduct;
    final pendingParts = animal.slaughterParts
        .where((p) => p.receivedBy != null && !p.usedInProduct)
        .toList();
    final hasPendingParts = pendingParts.isNotEmpty;

    if (!isSplitCarcass || !hasPendingParts) {
      // Whole carcass card
      return _buildWholeAnimalCard(animal, wholeAnimalPending);
    } else {
      // Split carcass card with expandable parts
      return _buildSplitCarcassCard(animal, pendingParts, isExpanded);
    }
  }

  Widget _buildWholeAnimalCard(Animal animal, bool isPending) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(animalId: animal.id!.toString()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
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
                        Text(
                          animal.animalId,
                          style: AppTypography.bodyLarge().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                            if (animal.liveWeight != null)
                              _buildInfoChip(
                                Icons.monitor_weight,
                                '${animal.liveWeight!.toStringAsFixed(1)} kg (live)',
                              ),
                            _buildInfoChip(
                              Icons.calendar_today,
                              '${animal.age} months',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        label: 'Pending',
                        color: AppColors.warning,
                      ),
                      if (animal.receivedAt != null) ...[
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'Received',
                          style: AppTypography.caption().copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          _formatDate(animal.receivedAt!),
                          style: AppTypography.caption().copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitCarcassCard(Animal animal, List<SlaughterPart> pendingParts, bool isExpanded) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedAnimals[animal.id!] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: AppColors.processorPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.content_cut,
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
                                'Split Carcass',
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
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          '${pendingParts.length} part(s) pending processing',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.processorPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expansion indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
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

          // Expandable parts list
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusMedium),
                  bottomRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Column(
                children: pendingParts.map((part) {
                  return _buildPartItem(part);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartItem(SlaughterPart part) {
    final displayName = AnatomicalNameMapping().getDisplayName(
      part.partType.value,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cut,
            color: AppColors.processorPrimary,
            size: 20,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (part.description != null && part.description!.isNotEmpty)
                  Text(
                    part.description!,
                    style: AppTypography.caption().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${part.weight.toStringAsFixed(1)} ${part.weightUnit}',
            style: AppTypography.bodyMedium().copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
