import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_icons.dart' as custom_icons;
import '../core/status_badge.dart';

/// MeatTrace Pro - Product Card Component
/// Display meat product information with quality, pricing, and batch details

class ProductCard extends StatelessWidget {
  final String productId;
  final String batchNumber;
  final String productType; // 'beef', 'pork', 'chicken', 'mutton', 'processed'
  final String? productName;
  final String? cutType;
  final String
  qualityGrade; // 'premium', 'standard', 'economy', 'organic', 'certified'
  final double? weight;
  final String? weightUnit;
  final double? price;
  final String? currency;
  final DateTime? productionDate;
  final DateTime? expiryDate;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isExternal;
  final Widget? trailing;

  const ProductCard({
    super.key,
    required this.productId,
    required this.batchNumber,
    required this.productType,
    this.productName,
    this.cutType,
    required this.qualityGrade,
    this.weight,
    this.weightUnit = 'kg',
    this.price,
    this.currency = '\$',
    this.productionDate,
    this.expiryDate,
    this.imageUrl,
    this.onTap,
    this.isSelected = false,
    this.isExternal = false,
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
              // Product Image
              _buildProductImage(isDark),
              const SizedBox(width: AppTheme.space16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name & Type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productName ?? productType.toUpperCase(),
                            style: AppTypography.titleMedium(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Icon(
                          _getProductIcon(productType),
                          size: AppTheme.iconSmall,
                          color: AppColors.getQualityColor(qualityGrade),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space4),

                    // Batch Number
                    Text(
                      'Batch: $batchNumber',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    if (cutType != null) ...[
                      Text(
                        cutType!,
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTheme.space12),

                    // Quality Badge
                    QualityBadge(grade: qualityGrade, size: BadgeSize.small),

                    if (isExternal) ...[
                      const SizedBox(height: AppTheme.space8),
                      StatusBadge(
                        label: 'External Source',
                        color: AppColors.secondaryBlue,
                        variant: BadgeVariant.soft,
                        size: BadgeSize.small,
                      ),
                    ],

                    const SizedBox(height: AppTheme.space12),

                    // Metrics Row
                    Row(
                      children: [
                        if (weight != null) ...[
                          _buildMetric(
                            Icons.scale,
                            '${weight!.toStringAsFixed(2)} $weightUnit',
                            isDark,
                          ),
                          const SizedBox(width: AppTheme.space16),
                        ],
                        if (price != null)
                          _buildMetric(
                            Icons.attach_money,
                            '$currency${price!.toStringAsFixed(2)}',
                            isDark,
                          ),
                      ],
                    ),

                    if (expiryDate != null) ...[
                      const SizedBox(height: AppTheme.space8),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 12,
                            color: _isExpiringSoon(expiryDate!)
                                ? AppColors.warning
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppTheme.space4),
                          Text(
                            'Expires: ${_formatDate(expiryDate!)}',
                            style: AppTypography.caption(
                              color: _isExpiringSoon(expiryDate!)
                                  ? AppColors.warning
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
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

  Widget _buildProductImage(bool isDark) {
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
              _getProductIcon(productType),
              size: 40,
              color: AppColors.getQualityColor(
                qualityGrade,
              ).withValues(alpha: 0.5),
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

  IconData _getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'beef':
        return custom_icons.CustomIcons.beef;
      case 'pork':
        return custom_icons.CustomIcons.pork;
      case 'chicken':
      case 'poultry':
        return custom_icons.CustomIcons.chicken;
      case 'mutton':
      case 'lamb':
        return custom_icons.CustomIcons.mutton;
      case 'processed':
        return custom_icons.CustomIcons.processedMeat;
      default:
        return Icons.inventory_2;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isExpiringSoon(DateTime expiryDate) {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }
}

/// Compact Product Card - Smaller version for lists
class CompactProductCard extends StatelessWidget {
  final String productId;
  final String batchNumber;
  final String productType;
  final String? productName;
  final String qualityGrade;
  final VoidCallback? onTap;
  final bool isSelected;

  const CompactProductCard({
    super.key,
    required this.productId,
    required this.batchNumber,
    required this.productType,
    this.productName,
    required this.qualityGrade,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space12),
          child: Row(
            children: [
              Icon(
                _getProductIcon(productType),
                size: AppTheme.iconMedium,
                color: AppColors.getQualityColor(qualityGrade),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName ?? productType.toUpperCase(),
                      style: AppTypography.bodyMedium(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Batch: $batchNumber',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              QualityBadge(grade: qualityGrade, size: BadgeSize.small),
              const SizedBox(width: AppTheme.space8),
              Icon(
                Icons.chevron_right,
                size: AppTheme.iconSmall,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'beef':
        return custom_icons.CustomIcons.beef;
      case 'pork':
        return custom_icons.CustomIcons.pork;
      case 'chicken':
      case 'poultry':
        return custom_icons.CustomIcons.chicken;
      case 'mutton':
      case 'lamb':
        return custom_icons.CustomIcons.mutton;
      case 'processed':
        return custom_icons.CustomIcons.processedMeat;
      default:
        return Icons.inventory_2;
    }
  }
}

/// Product Grid Card - For grid view display
class ProductGridCard extends StatelessWidget {
  final String productId;
  final String batchNumber;
  final String productType;
  final String? productName;
  final String qualityGrade;
  final double? price;
  final String? currency;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isSelected;

  const ProductGridCard({
    super.key,
    required this.productId,
    required this.batchNumber,
    required this.productType,
    this.productName,
    required this.qualityGrade,
    this.price,
    this.currency = '\$',
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
              child: Stack(
                children: [
                  Container(
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
                              _getProductIcon(productType),
                              size: 48,
                              color: AppColors.getQualityColor(
                                qualityGrade,
                              ).withValues(alpha: 0.5),
                            ),
                          )
                        : null,
                  ),
                  // Quality Badge Overlay
                  Positioned(
                    top: AppTheme.space8,
                    right: AppTheme.space8,
                    child: QualityBadge(
                      grade: qualityGrade,
                      size: BadgeSize.small,
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName ?? productType.toUpperCase(),
                    style: AppTypography.bodyMedium(
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Batch: $batchNumber',
                    style: AppTypography.caption(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      '$currency${price!.toStringAsFixed(2)}',
                      style: AppTypography.titleMedium(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'beef':
        return custom_icons.CustomIcons.beef;
      case 'pork':
        return custom_icons.CustomIcons.pork;
      case 'chicken':
      case 'poultry':
        return custom_icons.CustomIcons.chicken;
      case 'mutton':
      case 'lamb':
        return custom_icons.CustomIcons.mutton;
      case 'processed':
        return custom_icons.CustomIcons.processedMeat;
      default:
        return Icons.inventory_2;
    }
  }
}

/// Product Inventory Card - Display stock levels and inventory info
class ProductInventoryCard extends StatelessWidget {
  final String productType;
  final int totalStock;
  final int lowStockThreshold;
  final double? totalWeight;
  final String? weightUnit;
  final VoidCallback? onTap;

  const ProductInventoryCard({
    super.key,
    required this.productType,
    required this.totalStock,
    this.lowStockThreshold = 10,
    this.totalWeight,
    this.weightUnit = 'kg',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLowStock = totalStock <= lowStockThreshold;

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
                    _getProductIcon(productType),
                    size: AppTheme.iconLarge,
                    color: isLowStock
                        ? AppColors.warning
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productType.toUpperCase(),
                          style: AppTypography.labelLarge(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$totalStock Units',
                          style: AppTypography.headlineSmall(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLowStock)
                    StatusBadge(
                      label: 'Low Stock',
                      color: AppColors.warning,
                      variant: BadgeVariant.soft,
                      size: BadgeSize.small,
                    ),
                ],
              ),

              if (totalWeight != null) ...[
                const SizedBox(height: AppTheme.space16),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.space16),

                Row(
                  children: [
                    Icon(
                      Icons.scale,
                      size: AppTheme.iconSmall,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      'Total Weight: ${totalWeight!.toStringAsFixed(2)} $weightUnit',
                      style: AppTypography.bodyMedium(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'beef':
        return custom_icons.CustomIcons.beef;
      case 'pork':
        return custom_icons.CustomIcons.pork;
      case 'chicken':
      case 'poultry':
        return custom_icons.CustomIcons.chicken;
      case 'mutton':
      case 'lamb':
        return custom_icons.CustomIcons.mutton;
      case 'processed':
        return custom_icons.CustomIcons.processedMeat;
      default:
        return Icons.inventory_2;
    }
  }
}
