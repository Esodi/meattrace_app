import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Advanced search widget with filters and sorting
/// Provides comprehensive search and filtering capabilities
class AdvancedSearch extends StatefulWidget {
  final String? initialQuery;
  final List<SearchFilter> filters;
  final List<SortOption> sortOptions;
  final SortOption? selectedSort;
  final Function(String query, Map<String, dynamic> filters, SortOption? sort)
      onSearch;
  final VoidCallback? onClear;

  const AdvancedSearch({
    super.key,
    this.initialQuery,
    required this.filters,
    required this.sortOptions,
    this.selectedSort,
    required this.onSearch,
    this.onClear,
  });

  @override
  State<AdvancedSearch> createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch> {
  late TextEditingController _searchController;
  final Map<String, dynamic> _selectedFilters = {};
  SortOption? _selectedSort;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _selectedSort = widget.selectedSort;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: AppTypography.bodyMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space12,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                
                // Filter toggle
                Container(
                  decoration: BoxDecoration(
                    color: _showFilters || _selectedFilters.isNotEmpty
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: _showFilters || _selectedFilters.isNotEmpty
                        ? Border.all(color: theme.colorScheme.primary)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showFilters ? Icons.filter_list_off : Icons.filter_list,
                          color: _showFilters || _selectedFilters.isNotEmpty
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                      if (_selectedFilters.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_selectedFilters.length}',
                              style: AppTypography.labelSmall().copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters panel
          if (_showFilters) _buildFiltersPanel(),

          // Active filters
          if (_selectedFilters.isNotEmpty && !_showFilters)
            _buildActiveFilters(),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: AppTypography.headlineSmall(),
              ),
              const Spacer(),
              if (_selectedFilters.isNotEmpty)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear All',
                    style: AppTypography.button().copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),

          // Filter options
          ...widget.filters.map((filter) => _buildFilterOption(filter)),

          const SizedBox(height: AppTheme.space16),

          // Sort options
          if (widget.sortOptions.isNotEmpty) ...[
            Text(
              'Sort By',
              style: AppTypography.headlineSmall(),
            ),
            const SizedBox(height: AppTheme.space8),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: widget.sortOptions.map((sort) {
                final isSelected = _selectedSort?.id == sort.id;
                return ChoiceChip(
                  label: Text(sort.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSort = selected ? sort : null;
                    });
                    _performSearch();
                  },
                  selectedColor: AppColors.info.withValues(alpha: 0.2),
                  labelStyle: AppTypography.bodyMedium().copyWith(
                    color: isSelected ? AppColors.info : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppTheme.space16),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.search),
              label: const Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(SearchFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filter.label,
            style: AppTypography.bodyLarge().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          
          if (filter.type == FilterType.multiSelect)
            _buildMultiSelectFilter(filter)
          else if (filter.type == FilterType.range)
            _buildRangeFilter(filter)
          else if (filter.type == FilterType.dateRange)
            _buildDateRangeFilter(filter)
          else
            _buildSingleSelectFilter(filter),
        ],
      ),
    );
  }

  Widget _buildMultiSelectFilter(SearchFilter filter) {
    final List<String> selected =
        _selectedFilters[filter.id]?.cast<String>() ?? [];

    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space8,
      children: filter.options!.map((option) {
        final isSelected = selected.contains(option.value);
        return FilterChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (bool value) {
            setState(() {
              if (value) {
                selected.add(option.value);
                _selectedFilters[filter.id] = selected;
              } else {
                selected.remove(option.value);
                if (selected.isEmpty) {
                  _selectedFilters.remove(filter.id);
                }
              }
            });
          },
          selectedColor: AppColors.info.withValues(alpha: 0.2),
          checkmarkColor: AppColors.info,
          labelStyle: AppTypography.bodyMedium().copyWith(
            color: isSelected ? AppColors.info : AppColors.textPrimary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleSelectFilter(SearchFilter filter) {
    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space8,
      children: filter.options!.map((option) {
        final isSelected = _selectedFilters[filter.id] == option.value;
        return ChoiceChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _selectedFilters[filter.id] = option.value;
              } else {
                _selectedFilters.remove(filter.id);
              }
            });
          },
          selectedColor: AppColors.info.withValues(alpha: 0.2),
          labelStyle: AppTypography.bodyMedium().copyWith(
            color: isSelected ? AppColors.info : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRangeFilter(SearchFilter filter) {
    final RangeValues currentRange = _selectedFilters[filter.id] ??
        RangeValues(filter.min ?? 0, filter.max ?? 100);

    return Column(
      children: [
        RangeSlider(
          values: currentRange,
          min: filter.min ?? 0,
          max: filter.max ?? 100,
          divisions: ((filter.max ?? 100) - (filter.min ?? 0)).toInt(),
          activeColor: AppColors.info,
          labels: RangeLabels(
            currentRange.start.round().toString(),
            currentRange.end.round().toString(),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _selectedFilters[filter.id] = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${currentRange.start.round()}',
              style: AppTypography.bodyMedium(),
            ),
            Text(
              '${currentRange.end.round()}',
              style: AppTypography.bodyMedium(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(SearchFilter filter) {
    final DateTimeRange? dateRange = _selectedFilters[filter.id];

    return OutlinedButton.icon(
      onPressed: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: dateRange,
        );

        if (picked != null) {
          setState(() {
            _selectedFilters[filter.id] = picked;
          });
        }
      },
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        dateRange != null
            ? '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}'
            : 'Select Date Range',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: dateRange != null ? AppColors.info : AppColors.textPrimary,
        side: BorderSide(
          color: dateRange != null ? AppColors.info : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
      ),
      child: Wrap(
        spacing: AppTheme.space8,
        runSpacing: AppTheme.space8,
        children: [
          ..._selectedFilters.entries.map((entry) {
            final filter = widget.filters.firstWhere((f) => f.id == entry.key);
            return Chip(
              label: Text(_getFilterLabel(filter, entry.value)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedFilters.remove(entry.key);
                });
                _performSearch();
              },
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              labelStyle: AppTypography.bodyMedium().copyWith(
                color: AppColors.info,
              ),
            );
          }),
          if (_selectedSort != null)
            Chip(
              label: Text('Sort: ${_selectedSort!.label}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedSort = null;
                });
                _performSearch();
              },
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              labelStyle: AppTypography.bodyMedium().copyWith(
                color: AppColors.info,
              ),
            ),
        ],
      ),
    );
  }

  String _getFilterLabel(SearchFilter filter, dynamic value) {
    if (value is List) {
      return '${filter.label}: ${value.length} selected';
    } else if (value is RangeValues) {
      return '${filter.label}: ${value.start.round()}-${value.end.round()}';
    } else if (value is DateTimeRange) {
      return '${filter.label}: ${_formatDate(value.start)} - ${_formatDate(value.end)}';
    } else {
      final option = filter.options?.firstWhere((o) => o.value == value);
      return '${filter.label}: ${option?.label ?? value}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _performSearch() {
    widget.onSearch(
      _searchController.text,
      _selectedFilters,
      _selectedSort,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _selectedSort = null;
    });
    _performSearch();
    widget.onClear?.call();
  }
}

/// Search filter model
class SearchFilter {
  final String id;
  final String label;
  final FilterType type;
  final List<FilterOption>? options;
  final double? min;
  final double? max;

  const SearchFilter({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.min,
    this.max,
  });
}

/// Filter option for select filters
class FilterOption {
  final String label;
  final String value;

  const FilterOption({
    required this.label,
    required this.value,
  });
}

/// Filter type enum
enum FilterType {
  singleSelect,
  multiSelect,
  range,
  dateRange,
}

/// Sort option model
class SortOption {
  final String id;
  final String label;
  final bool ascending;

  const SortOption({
    required this.id,
    required this.label,
    this.ascending = true,
  });
}
