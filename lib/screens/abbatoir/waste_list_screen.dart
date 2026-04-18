import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/waste_provider.dart';
import '../../models/waste.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

class WasteListScreen extends StatefulWidget {
  const WasteListScreen({super.key});

  @override
  State<WasteListScreen> createState() => _WasteListScreenState();
}

class _WasteListScreenState extends State<WasteListScreen> {
  String? _selectedType;
  String? _selectedStage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WasteProvider>(context, listen: false).fetchWasteRecords();
    });
  }

  void _applyFilters() {
    Provider.of<WasteProvider>(context, listen: false).fetchWasteRecords(
      wasteType: _selectedType,
      stage: _selectedStage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Waste Records'),
        backgroundColor: AppColors.abbatoirPrimary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _applyFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<WasteProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.abbatoirPrimary,
                    ),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: AppTheme.iconXLarge,
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          provider.error!,
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.space16),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.abbatoirPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.wasteRecords.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: AppTheme.iconXLarge,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          'No waste records found.',
                          style: AppTypography.bodyLarge(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppTheme.space12,
                    right: AppTheme.space12,
                    bottom: AppTheme.space12,
                  ),
                  itemCount: provider.wasteRecords.length,
                  itemBuilder: (context, index) {
                    final waste = provider.wasteRecords[index];
                    return _buildWasteCard(waste, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const borderRadius = BorderRadius.all(Radius.circular(AppTheme.radiusMedium));

    return Container(
      margin: const EdgeInsets.all(AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                ),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: const OutlineInputBorder(
                  borderRadius: borderRadius,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: AppColors.abbatoirPrimary, width: 2),
                ),
              ),
              dropdownColor: Colors.white,
              initialValue: _selectedType,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                const DropdownMenuItem(value: 'evisceration', child: Text('Evisceration')),
                const DropdownMenuItem(value: 'processing', child: Text('Processing')),
                const DropdownMenuItem(value: 'rejection', child: Text('Rejection')),
                const DropdownMenuItem(value: 'trimming', child: Text('Trimming')),
                const DropdownMenuItem(value: 'spoilage', child: Text('Spoilage')),
                const DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Stage',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                ),
                filled: true,
                fillColor: AppColors.backgroundGray,
                border: const OutlineInputBorder(
                  borderRadius: borderRadius,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: borderRadius,
                  borderSide: BorderSide(color: AppColors.abbatoirPrimary, width: 2),
                ),
              ),
              dropdownColor: Colors.white,
              initialValue: _selectedStage,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Stages')),
                const DropdownMenuItem(value: 'abbatoir', child: Text('Abbatoir')),
                const DropdownMenuItem(value: 'processing_unit', child: Text('Processing Unit')),
                const DropdownMenuItem(value: 'shop', child: Text('Shop')),
              ],
              onChanged: (value) {
                setState(() => _selectedStage = value);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteCard(Waste waste, ThemeData theme) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.abbatoirPrimary.withValues(alpha: 0.12),
              child: const Icon(
                Icons.delete,
                color: AppColors.abbatoirPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${waste.wasteTypeDisplay} - ${waste.weightKg} kg',
                    style: AppTypography.titleMedium(),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Target: ${waste.animalId ?? "N/A"} (${waste.animalSpecies ?? "N/A"})',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Stage: ${waste.stageDisplay}',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  Text(
                    'Date: ${dateFormat.format(waste.recordedAt)}',
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  if (waste.notes != null && waste.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space6),
                    Text(
                      'Notes: ${waste.notes}',
                      style: AppTypography.bodySmall(
                        color: theme.colorScheme.onSurfaceVariant,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            if (waste.autoGenerated)
              Chip(
                label: const Text(
                  'Auto',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: AppColors.abbatoirPrimary,
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }
}
