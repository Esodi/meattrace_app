import 'package:flutter/material.dart';
import 'dart:async';
import '../models/processing_stage.dart';
import '../models/product_category.dart';
import '../utils/theme.dart';

enum QualityStatus { all, passed, failed, pending }

class SearchFilter {
  final String query;
  final DateTime? startDate;
  final DateTime? endDate;
  final ProcessingStage? processingStage;
  final QualityStatus qualityStatus;
  final ProductCategory? productCategory;

  SearchFilter({
    this.query = '',
    this.startDate,
    this.endDate,
    this.processingStage,
    this.qualityStatus = QualityStatus.all,
    this.productCategory,
  });

  SearchFilter copyWith({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    ProcessingStage? processingStage,
    QualityStatus? qualityStatus,
    ProductCategory? productCategory,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      processingStage: processingStage ?? this.processingStage,
      qualityStatus: qualityStatus ?? this.qualityStatus,
      productCategory: productCategory ?? this.productCategory,
    );
  }

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      startDate != null ||
      endDate != null ||
      processingStage != null ||
      qualityStatus != QualityStatus.all ||
      productCategory != null;
}

class SearchFilterPanel extends StatefulWidget {
  final SearchFilter initialFilter;
  final Function(SearchFilter) onFilterChanged;
  final List<ProcessingStage> processingStages;
  final List<ProductCategory> productCategories;
  final bool isCollapsed;
  final Function(bool) onToggleCollapsed;

  const SearchFilterPanel({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
    required this.processingStages,
    required this.productCategories,
    this.isCollapsed = true,
    required this.onToggleCollapsed,
  });

  @override
  State<SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<SearchFilterPanel> {
  late SearchFilter _currentFilter;
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _searchController.text = _currentFilter.query;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateFilter(_currentFilter.copyWith(query: _searchController.text));
    });
  }

  void _updateFilter(SearchFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    widget.onFilterChanged(newFilter);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _currentFilter.startDate != null && _currentFilter.endDate != null
          ? DateTimeRange(start: _currentFilter.startDate!, end: _currentFilter.endDate!)
          : null,
    );

    if (picked != null) {
      _updateFilter(_currentFilter.copyWith(
        startDate: picked.start,
        endDate: picked.end,
      ));
    }
  }

  void _clearFilters() {
    _searchController.text = '';
    _updateFilter(SearchFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with toggle and search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.isCollapsed ? Icons.expand_more : Icons.expand_less,
                  color: AppTheme.forestGreen,
                ),
                onPressed: () => widget.onToggleCollapsed(!widget.isCollapsed),
                tooltip: widget.isCollapsed ? 'Show filters' : 'Hide filters',
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products, animals, batches...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppTheme.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppTheme.textSecondary,
                    ),
                    suffixIcon: _currentFilter.hasActiveFilters
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearFilters,
                            tooltip: 'Clear all filters',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.dividerGray.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.dividerGray.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.forestGreen,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.oceanBlue.withOpacity(0.3)
                        : AppTheme.backgroundGray,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (_currentFilter.hasActiveFilters)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Filtered',
                    style: TextStyle(
                      color: AppTheme.forestGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Expanded filters
        if (!widget.isCollapsed)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.oceanBlue.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.dividerGray.withOpacity(0.3),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Date Range
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.dividerGray),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.date_range, size: 16, color: AppTheme.forestGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentFilter.startDate != null && _currentFilter.endDate != null
                                      ? '${_currentFilter.startDate!.toLocal().toString().split(' ')[0]} - ${_currentFilter.endDate!.toLocal().toString().split(' ')[0]}'
                                      : 'Select date range',
                                  style: TextStyle(
                                    color: _currentFilter.startDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Processing Stage
                    Expanded(
                      child: DropdownButtonFormField<ProcessingStage?>(
                        value: _currentFilter.processingStage,
                        decoration: InputDecoration(
                          labelText: 'Processing Stage',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<ProcessingStage?>(
                            value: null,
                            child: Text('All Stages'),
                          ),
                          ...widget.processingStages.map((stage) => DropdownMenuItem(
                                value: stage,
                                child: Text(stage.name),
                              )),
                        ],
                        onChanged: (value) => _updateFilter(_currentFilter.copyWith(processingStage: value)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Quality Status
                    Expanded(
                      child: DropdownButtonFormField<QualityStatus>(
                        value: _currentFilter.qualityStatus,
                        decoration: InputDecoration(
                          labelText: 'Quality Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: QualityStatus.values.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getQualityStatusLabel(status)),
                            )).toList(),
                        onChanged: (value) => _updateFilter(_currentFilter.copyWith(qualityStatus: value)),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Product Category
                    Expanded(
                      child: DropdownButtonFormField<ProductCategory?>(
                        value: _currentFilter.productCategory,
                        decoration: InputDecoration(
                          labelText: 'Product Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<ProductCategory?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...widget.productCategories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.name),
                              )),
                        ],
                        onChanged: (value) => _updateFilter(_currentFilter.copyWith(productCategory: value)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getQualityStatusLabel(QualityStatus status) {
    switch (status) {
      case QualityStatus.all:
        return 'All Statuses';
      case QualityStatus.passed:
        return 'Passed';
      case QualityStatus.failed:
        return 'Failed';
      case QualityStatus.pending:
        return 'Pending';
    }
  }
}







