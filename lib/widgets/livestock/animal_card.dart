import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart' as custom_icons;
import '../core/status_badge.dart';

/// MeatTrace Pro - Animal Card Component
/// Display animal information with species, health status, and key metrics

class AnimalCard extends StatelessWidget {
  final String animalId;
  final String? tagNumber;
  final String species; // 'cattle', 'pig', 'chicken', 'sheep', 'goat'
  final String? breed;
  final String
  healthStatus; // 'healthy', 'sick', 'quarantine', 'treatment', 'deceased'
  final double? weight;
  final String? weightUnit;
  final int? age;
  final String? ageUnit;
  final String? gender;
  final DateTime? registrationDate;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isSelected;
  final Widget? trailing;

  const AnimalCard({
    super.key,
    required this.animalId,
    this.tagNumber,
    required this.species,
    this.breed,
    required this.healthStatus,
    this.weight,
    this.weightUnit = 'kg',
    this.age,
    this.ageUnit = 'months',
    this.gender,
    this.registrationDate,
    this.imageUrl,
    this.onTap,
    this.isSelected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animal Image or Icon
              _buildAnimalImage(isDark),
              const SizedBox(width: AppTheme.space16),

              // Animal Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag Number & Species
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tagNumber ?? 'ID: $animalId',
                            style: AppTypography.titleMedium(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Icon(
                          custom_icons.getSpeciesIcon(species),
                          size: AppTheme.iconSmall,
                          color: AppColors.getSpeciesColor(species),
                        ),
                      ],
                    ),

                    if (breed != null) ...[
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        breed!,
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppTheme.space12),

                    // Health Status Badge
                    HealthStatusBadge(
                      status: healthStatus,
                      size: BadgeSize.small,
                    ),

                    const SizedBox(height: AppTheme.space12),

                    // Metrics Row
                    Row(
                      children: [
                        if (weight != null) ...[
                          _buildMetric(
                            Icons.monitor_weight,
                            '${weight!.toStringAsFixed(1)} $weightUnit',
                            isDark,
                          ),
                          const SizedBox(width: AppTheme.space16),
                        ],
                        if (age != null) ...[
                          _buildMetric(Icons.cake, '$age $ageUnit', isDark),
                          const SizedBox(width: AppTheme.space16),
                        ],
                        if (gender != null)
                          _buildMetric(
                            gender?.toLowerCase() == 'male'
                                ? Icons.male
                                : Icons.female,
                            gender!,
                            isDark,
                          ),
                      ],
                    ),

                    if (registrationDate != null) ...[
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        'Registered: ${_formatDate(registrationDate!)}',
                        style: AppTypography.caption(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing Widget
              if (trailing != null) ...[
                const SizedBox(width: AppTheme.space12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalImage(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Icon(
              custom_icons.getSpeciesIcon(species),
              size: 40,
              color: AppColors.getSpeciesColor(species).withValues(alpha: 0.5),
            )
          : null,
    );
  }

  Widget _buildMetric(IconData icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppTheme.space4),
        Text(
          value,
          style: AppTypography.bodySmall(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Compact Animal Card - Smaller version for lists
class CompactAnimalCard extends StatelessWidget {
  final String animalId;
  final String? tagNumber;
  final String species;
  final String healthStatus;
  final VoidCallback? onTap;
  final bool isSelected;

  const CompactAnimalCard({
    super.key,
    required this.animalId,
    this.tagNumber,
    required this.species,
    required this.healthStatus,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : AppColors.divider.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppColors.getSpeciesColor(
                    species,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  custom_icons.getSpeciesIcon(species),
                  size: 24,
                  color: AppColors.getSpeciesColor(species),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tagNumber ?? 'ID: $animalId',
                      style: AppTypography.titleSmall().copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          species.toUpperCase(),
                          style: AppTypography.labelSmall().copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        HealthStatusBadge(
                          status: healthStatus,
                          size: BadgeSize.small,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animal Grid Card - For grid view display
class AnimalGridCard extends StatelessWidget {
  final String animalId;
  final String? tagNumber;
  final String species;
  final String healthStatus;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isSelected;

  const AnimalGridCard({
    super.key,
    required this.animalId,
    this.tagNumber,
    required this.species,
    required this.healthStatus,
    this.imageUrl,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.backgroundGray,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMedium),
                    topRight: Radius.circular(AppTheme.radiusMedium),
                  ),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(
                        child: Icon(
                          custom_icons.getSpeciesIcon(species),
                          size: 48,
                          color: AppColors.getSpeciesColor(
                            species,
                          ).withValues(alpha: 0.5),
                        ),
                      )
                    : null,
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tagNumber ?? 'ID: $animalId',
                    style: AppTypography.bodyMedium(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.space8),
                  HealthStatusBadge(
                    status: healthStatus,
                    size: BadgeSize.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animal Stats Card - Display aggregate animal statistics
class AnimalStatsCard extends StatelessWidget {
  final String species;
  final int totalCount;
  final int healthyCount;
  final int sickCount;
  final int quarantineCount;
  final VoidCallback? onTap;

  const AnimalStatsCard({
    super.key,
    required this.species,
    required this.totalCount,
    required this.healthyCount,
    this.sickCount = 0,
    this.quarantineCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    custom_icons.getSpeciesIcon(species),
                    size: AppTheme.iconLarge,
                    color: AppColors.getSpeciesColor(species),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          species.toUpperCase(),
                          style: AppTypography.labelLarge(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$totalCount Animals',
                          style: AppTypography.headlineSmall(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.space16),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.space16),

              // Status Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusCount(
                    'Healthy',
                    healthyCount,
                    AppColors.getHealthStatusColor('healthy'),
                    isDark,
                  ),
                  if (sickCount > 0)
                    _buildStatusCount(
                      'Sick',
                      sickCount,
                      AppColors.getHealthStatusColor('sick'),
                      isDark,
                    ),
                  if (quarantineCount > 0)
                    _buildStatusCount(
                      'Quarantine',
                      quarantineCount,
                      AppColors.getHealthStatusColor('quarantine'),
                      isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTypography.titleLarge(
            color: color,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          label,
          style: AppTypography.bodySmall(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
