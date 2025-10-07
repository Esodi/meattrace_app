import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'breadcrumb_navigation.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';
import '../utils/accessibility.dart';
import 'search_filter_panel.dart';
import '../models/processing_stage.dart';
import '../models/product_category.dart';
import 'dart:async';

class ResponsiveHeader extends StatefulWidget {
  final bool showSidebarToggle;
  final VoidCallback? onSidebarToggle;
  final List<String> breadcrumbs;
  final bool showSearchFilter;
  final SearchFilter? initialFilter;
  final Function(SearchFilter)? onFilterChanged;
  final List<ProcessingStage>? processingStages;
  final List<ProductCategory>? productCategories;

  const ResponsiveHeader({
    super.key,
    this.showSidebarToggle = true,
    this.onSidebarToggle,
    this.breadcrumbs = const ['Dashboard', 'Processing'],
    this.showSearchFilter = false,
    this.initialFilter,
    this.onFilterChanged,
    this.processingStages,
    this.productCategories,
  });

  @override
  State<ResponsiveHeader> createState() => _ResponsiveHeaderState();
}

class _ResponsiveHeaderState extends State<ResponsiveHeader> {
  late Timer _clockTimer;
  late String _currentTime;
  bool _searchFilterCollapsed = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = _formatTime(DateTime.now());
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? AppTheme.oceanBlue : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerGray.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main header row
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Sidebar Toggle
                if (widget.showSidebarToggle)
                  AccessibleIconButton(
                    icon: Icons.menu,
                    semanticLabel: 'Toggle sidebar visibility',
                    tooltip: 'Toggle sidebar',
                    onPressed: widget.onSidebarToggle,
                  ),

                // Breadcrumb Navigation
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: BreadcrumbNavigation(
                      breadcrumbs: widget.breadcrumbs,
                    ),
                  ),
                ),

                // Real-time Clock
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.forestGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentTime,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.forestGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // High Contrast Toggle
                AccessibleIconButton(
                  icon: themeProvider.isHighContrastEnabled ? Icons.visibility_off : Icons.visibility,
                  semanticLabel: themeProvider.isHighContrastEnabled ? 'Disable high contrast mode' : 'Enable high contrast mode',
                  tooltip: themeProvider.isHighContrastEnabled ? 'Disable High Contrast' : 'Enable High Contrast',
                  onPressed: () => themeProvider.toggleHighContrast(),
                ),

                const SizedBox(width: 8),

                // Dark Mode Toggle
                AccessibleIconButton(
                  icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  semanticLabel: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
                  tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ],
            ),
          ),

          // Search/Filter Panel (if enabled)
          if (widget.showSearchFilter &&
              widget.initialFilter != null &&
              widget.onFilterChanged != null &&
              widget.processingStages != null &&
              widget.productCategories != null)
            SearchFilterPanel(
              initialFilter: widget.initialFilter!,
              onFilterChanged: widget.onFilterChanged!,
              processingStages: widget.processingStages!,
              productCategories: widget.productCategories!,
              isCollapsed: _searchFilterCollapsed,
              onToggleCollapsed: (collapsed) => setState(() => _searchFilterCollapsed = collapsed),
            ),
        ],
      ),
    );
  }
}







