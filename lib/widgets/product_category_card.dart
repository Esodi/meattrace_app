import 'package:flutter/material.dart';
import '../models/product_category.dart';

class ProductCategoryCard extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCategoryCard({Key? key, required this.category, this.onTap, this.onEdit, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.14),
              theme.colorScheme.secondary.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Circular image placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.18),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  (category.name.isNotEmpty ? category.name[0].toUpperCase() : '?'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions menu
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18), SizedBox(width: 8), Text('Delete')])),
              ],
              child: Icon(Icons.more_vert, color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
