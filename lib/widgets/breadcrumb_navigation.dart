import 'package:flutter/material.dart';
import '../utils/theme.dart';

class BreadcrumbNavigation extends StatelessWidget {
  final List<String> breadcrumbs;
  final Function(int)? onBreadcrumbTap;

  const BreadcrumbNavigation({
    super.key,
    required this.breadcrumbs,
    this.onBreadcrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(breadcrumbs.length * 2 - 1, (index) {
        if (index.isEven) {
          final breadcrumbIndex = index ~/ 2;
          final isLast = breadcrumbIndex == breadcrumbs.length - 1;

          return InkWell(
            onTap: isLast ? null : () => onBreadcrumbTap?.call(breadcrumbIndex),
            child: Text(
              breadcrumbs[breadcrumbIndex],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isLast
                    ? AppTheme.forestGreen
                    : AppTheme.textSecondary,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          );
        }
      }),
    );
  }
}







