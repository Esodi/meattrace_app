import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/animal_provider.dart';
import '../../models/animal.dart';
import '../../utils/anatomical_name_mapping.dart';
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
  final Map<int, bool> _expandedAnimals = {};             // Track expanded cards

  // New state management for accept/reject decisions
  final Map<int, String> _animalDecisions = {};          // animal_id -> 'accept' or 'reject'
  final Map<int, Map<String, dynamic>> _animalRejectionReasons = {}; // animal_id -> rejection data
  final Map<String, String> _partDecisions = {};         // 'animalId_partId' -> 'accept' or 'reject'
  final Map<String, Map<String, dynamic>> _partRejectionReasons = {}; // 'animalId_partId' -> rejection data

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
        // Check if whole animal is transferred and not received
        final wholeAnimalTransferred = animal.transferredTo != null;
        final wholeAnimalPending = wholeAnimalTransferred && animal.receivedBy == null;

        // Check if any parts are transferred and not received
        final hasPendingParts = animal.hasSlaughterParts &&
            animal.slaughterParts.any((p) => p.isTransferred && p.receivedBy == null);

        return wholeAnimalPending || hasPendingParts;
      }).toList();

      setState(() => _pendingAnimals = pending);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading animals: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final hasDecisions = _animalDecisions.isNotEmpty || _partDecisions.isNotEmpty;
    final totalAcceptedAnimals = _animalDecisions.values.where((d) => d == 'accept').length;
    final totalRejectedAnimals = _animalDecisions.values.where((d) => d == 'reject').length;
    final totalAcceptedParts = _partDecisions.values.where((d) => d == 'accept').length;
    final totalRejectedParts = _partDecisions.values.where((d) => d == 'reject').length;

    String decisionText;
    if (hasDecisions) {
      final parts = <String>[];
      if (totalAcceptedAnimals > 0) parts.add('$totalAcceptedAnimals accepted');
      if (totalRejectedAnimals > 0) parts.add('$totalRejectedAnimals rejected');
      if (totalAcceptedParts > 0) parts.add('$totalAcceptedParts parts accepted');
      if (totalRejectedParts > 0) parts.add('$totalRejectedParts parts rejected');
      decisionText = parts.join(', ');
    } else {
      decisionText = '';
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
          if (hasDecisions)
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
                    decisionText,
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
      bottomNavigationBar: hasDecisions
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
                  label: 'Review Decisions',
                  onPressed: _isLoading ? null : _showReviewScreen,
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
    // Action buttons are no longer needed in the new decision-based flow
    return const SizedBox.shrink();
  }

  Widget _buildAnimalCard(Animal animal) {
    final isSplitCarcass = animal.isSplitCarcass && animal.hasSlaughterParts;
    final isExpanded = _expandedAnimals[animal.id] ?? false;
    final decision = _animalDecisions[animal.id];

    // For whole carcass or when parts aren't loaded
    if (!isSplitCarcass) {
      return Card(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        elevation: decision != null ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(
            color: decision == 'accept'
                ? AppColors.success
                : decision == 'reject'
                    ? AppColors.error
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: AppTheme.space16),
              // Accept/Reject Radio Buttons
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        'Accept',
                        style: AppTypography.bodyMedium().copyWith(
                          color: decision == 'accept' ? AppColors.success : AppColors.textPrimary,
                          fontWeight: decision == 'accept' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: 'accept',
                      groupValue: decision,
                      onChanged: (value) {
                        setState(() {
                          _animalDecisions[animal.id!] = value!;
                          _animalRejectionReasons.remove(animal.id);
                        });
                      },
                      activeColor: AppColors.success,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        'Reject',
                        style: AppTypography.bodyMedium().copyWith(
                          color: decision == 'reject' ? AppColors.error : AppColors.textPrimary,
                          fontWeight: decision == 'reject' ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: 'reject',
                      groupValue: decision,
                      onChanged: (value) async {
                        final reason = await _showRejectionDialog(animal, null);
                        if (reason != null) {
                          setState(() {
                            _animalDecisions[animal.id!] = value!;
                            _animalRejectionReasons[animal.id!] = reason;
                          });
                        }
                      },
                      activeColor: AppColors.error,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // For split carcass with parts - show expandable card
    final transferredParts = animal.slaughterParts.where((p) => p.isTransferred && p.receivedBy == null).toList();
    final hasAnyPartDecisions = transferredParts.any((part) =>
        _partDecisions.containsKey('${animal.id}_${part.id}'));

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: hasAnyPartDecisions ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: hasAnyPartDecisions
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
                        if (hasAnyPartDecisions) ...[
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            '${_partDecisions.values.where((d) => d == 'accept').length} parts to accept, ${_partDecisions.values.where((d) => d == 'reject').length} parts to reject',
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

          // Expandable part list
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transferred Parts',
                    style: AppTypography.bodyMedium().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  ...transferredParts.map((part) {
                    final partKey = '${animal.id}_${part.id}';
                    final decision = _partDecisions[partKey];
                    final hasValidWeight = part.weight != null && part.weight > 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.space8),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getPartLabel(part),
                                    style: AppTypography.bodyMedium().copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (hasValidWeight)
                                  Text(
                                    '${part.weight.toStringAsFixed(2)} ${part.weightUnit}',
                                    style: AppTypography.bodySmall().copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                else
                                  Text(
                                    'Weight missing',
                                    style: AppTypography.bodySmall().copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text(
                                      'Accept',
                                      style: AppTypography.bodySmall().copyWith(
                                        color: decision == 'accept' ? AppColors.success : AppColors.textPrimary,
                                        fontWeight: decision == 'accept' ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    value: 'accept',
                                    groupValue: decision,
                                    onChanged: hasValidWeight ? (value) {
                                      setState(() {
                                        _partDecisions[partKey] = value!;
                                        _partRejectionReasons.remove(partKey);
                                      });
                                    } : null,
                                    activeColor: AppColors.success,
                                    dense: true,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text(
                                      'Reject',
                                      style: AppTypography.bodySmall().copyWith(
                                        color: decision == 'reject' ? AppColors.error : AppColors.textPrimary,
                                        fontWeight: decision == 'reject' ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    value: 'reject',
                                    groupValue: decision,
                                    onChanged: hasValidWeight ? (value) async {
                                      final reason = await _showRejectionDialog(animal, part);
                                      if (reason != null) {
                                        setState(() {
                                          _partDecisions[partKey] = value!;
                                          _partRejectionReasons[partKey] = reason;
                                        });
                                      }
                                    } : null,
                                    activeColor: AppColors.error,
                                    dense: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
        // Use the centralized anatomical name mapping utility
        return AnatomicalNameMapping().getDisplayName(key);
      }
    }
    return part.partType.displayName;
  }

  Future<Map<String, dynamic>?> _showRejectionDialog(Animal animal, SlaughterPart? part) async {
    final rejectionCategories = {
      'quality': 'Quality Issues',
      'documentation': 'Documentation Issues',
      'health_safety': 'Health & Safety',
      'compliance': 'Compliance Issues',
      'logistics': 'Logistics Issues',
      'other': 'Other',
    };

    final specificReasons = {
      'quality': [
        'Poor physical condition',
        'Contamination',
        'Incorrect weight',
        'Physical damage',
        'Expired/outdated',
      ],
      'documentation': [
        'Missing documentation',
        'Invalid documentation',
        'Incomplete records',
        'Wrong animal ID',
      ],
      'health_safety': [
        'Disease symptoms',
        'Parasites/insects',
        'Chemical residues',
        'Temperature issues',
      ],
      'compliance': [
        'Missing certification',
        'Traceability breach',
        'Regulatory violation',
      ],
      'logistics': [
        'Transport damage',
        'Delayed delivery',
        'Packaging issues',
      ],
      'other': ['Other (specify in notes)'],
    };

    String selectedCategory = 'quality';
    String selectedReason = specificReasons['quality']!.first;
    final notesController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          part != null
              ? 'Reject Part: ${_getPartLabel(part)}'
              : 'Reject Animal: ${animal.animalId}',
          style: AppTypography.headlineSmall(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide details for the rejection:',
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: AppTheme.space16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Rejection Category',
                  border: OutlineInputBorder(),
                ),
                items: rejectionCategories.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                    selectedReason = specificReasons[selectedCategory]!.first;
                  });
                },
              ),
              const SizedBox(height: AppTheme.space12),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  labelText: 'Specific Reason',
                  border: OutlineInputBorder(),
                ),
                items: specificReasons[selectedCategory]!.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              ),
              const SizedBox(height: AppTheme.space12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Provide any additional details...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'category': selectedCategory,
                'specific_reason': selectedReason,
                'notes': notesController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showReviewScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Review Decisions',
                    style: AppTypography.headlineMedium(),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Summary',
                              style: AppTypography.headlineSmall(),
                            ),
                            const SizedBox(height: AppTheme.space12),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success),
                                const SizedBox(width: AppTheme.space8),
                                Text(
                                  '${_animalDecisions.values.where((d) => d == 'accept').length + _partDecisions.values.where((d) => d == 'accept').length} items to accept',
                                  style: AppTypography.bodyMedium(),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Row(
                              children: [
                                Icon(Icons.cancel, color: AppColors.error),
                                const SizedBox(width: AppTheme.space8),
                                Text(
                                  '${_animalDecisions.values.where((d) => d == 'reject').length + _partDecisions.values.where((d) => d == 'reject').length} items to reject',
                                  style: AppTypography.bodyMedium(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Animals to Accept
                    if (_animalDecisions.values.where((d) => d == 'accept').isNotEmpty) ...[
                      Text(
                        'Animals to Accept',
                        style: AppTypography.headlineSmall(),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      ..._animalDecisions.entries
                          .where((entry) => entry.value == 'accept')
                          .map((entry) {
                        final animal = _pendingAnimals.firstWhere((a) => a.id == entry.key);
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.check_circle, color: AppColors.success),
                            title: Text(animal.animalId),
                            subtitle: Text('${animal.species} • Whole Carcass'),
                          ),
                        );
                      }),
                      const SizedBox(height: AppTheme.space16),
                    ],

                    // Animals to Reject
                    if (_animalDecisions.values.where((d) => d == 'reject').isNotEmpty) ...[
                      Text(
                        'Animals to Reject',
                        style: AppTypography.headlineSmall(),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      ..._animalDecisions.entries
                          .where((entry) => entry.value == 'reject')
                          .map((entry) {
                        final animal = _pendingAnimals.firstWhere((a) => a.id == entry.key);
                        final reason = _animalRejectionReasons[entry.key];
                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.cancel, color: AppColors.error),
                            title: Text(animal.animalId),
                            subtitle: Text(
                              reason != null
                                  ? '${reason['category']} • ${reason['specific_reason']}'
                                  : 'No reason provided',
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppTheme.space16),
                    ],

                    // Parts to Accept/Reject would go here
                    // Similar structure for parts...
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Edit'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: CustomButton(
                      label: 'Submit Decisions',
                      onPressed: _submitDecisions,
                      loading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDecisions() async {
    setState(() => _isLoading = true);

    try {
      // Prepare acceptance data
      final animalIds = _animalDecisions.entries
          .where((entry) => entry.value == 'accept')
          .map((entry) => entry.key)
          .toList();

      // Prepare part receives - group accepted parts by animal
      final partReceives = <Map<String, dynamic>>[];
      final acceptedPartsByAnimal = <int, List<int>>{};

      _partDecisions.entries
          .where((entry) => entry.value == 'accept')
          .forEach((entry) {
            final parts = entry.key.split('_');
            final animalId = int.parse(parts[0]);
            final partId = int.parse(parts[1]);

            if (!acceptedPartsByAnimal.containsKey(animalId)) {
              acceptedPartsByAnimal[animalId] = [];
            }
            acceptedPartsByAnimal[animalId]!.add(partId);
          });

      acceptedPartsByAnimal.forEach((animalId, partIds) {
        partReceives.add({
          'animal_id': animalId,
          'part_ids': partIds,
        });
      });

      // Prepare rejection data
      final animalRejections = _animalDecisions.entries
          .where((entry) => entry.value == 'reject')
          .map((entry) {
            final animalId = entry.key;
            final reason = _animalRejectionReasons[animalId];
            return {
              'animal_id': animalId,
              'category': reason?['category'] ?? 'other',
              'specific_reason': reason?['specific_reason'] ?? 'Other (specify in notes)',
              'notes': reason?['notes'] ?? '',
            };
          })
          .toList();

      // Prepare part rejections
      final partRejections = _partDecisions.entries
          .where((entry) => entry.value == 'reject')
          .map((entry) {
            final parts = entry.key.split('_');
            final animalId = int.parse(parts[0]);
            final partId = int.parse(parts[1]);
            final reason = _partRejectionReasons[entry.key];
            return {
              'part_id': partId,
              'category': reason?['category'] ?? 'other',
              'specific_reason': reason?['specific_reason'] ?? 'Other (specify in notes)',
              'notes': reason?['notes'] ?? '',
            };
          })
          .toList();

      // Submit to API
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      await animalProvider.receiveAnimals(
        animalIds,
        partReceives: partReceives,
        animalRejections: animalRejections,
        partRejections: partRejections,
      );

      if (mounted) {
        // Clear decision state to prevent resubmission
        setState(() {
          _animalDecisions.clear();
          _animalRejectionReasons.clear();
          _partDecisions.clear();
          _partRejectionReasons.clear();
        });

        // Refresh the animal data to reflect the updated received status
        await _loadPendingAnimals();

        Navigator.of(context).pop(); // Close review screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully processed ${animalIds.length + partReceives.length} acceptances and ${animalRejections.length + partRejections.length} rejections'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting decisions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
