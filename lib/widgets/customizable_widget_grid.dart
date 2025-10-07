import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/theme.dart';

enum WidgetSize { small, medium, large }

class DashboardWidget {
  final String id;
  final String title;
  final Widget content;
  final WidgetSize size;
  final bool isVisible;
  final int order;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.content,
    this.size = WidgetSize.medium,
    this.isVisible = true,
    required this.order,
  });

  DashboardWidget copyWith({
    String? id,
    String? title,
    Widget? content,
    WidgetSize? size,
    bool? isVisible,
    int? order,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      size: size ?? this.size,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'size': size.toString(),
      'isVisible': isVisible,
      'order': order,
    };
  }

  factory DashboardWidget.fromJson(Map<String, dynamic> json, Widget content) {
    return DashboardWidget(
      id: json['id'],
      title: json['title'],
      content: content,
      size: WidgetSize.values.firstWhere(
        (e) => e.toString() == json['size'],
        orElse: () => WidgetSize.medium,
      ),
      isVisible: json['isVisible'] ?? true,
      order: json['order'] ?? 0,
    );
  }
}

class CustomizableWidgetGrid extends StatefulWidget {
  final List<DashboardWidget> widgets;
  final bool isEditMode;
  final Function(bool)? onEditModeChanged;
  final String preferencesKey;

  const CustomizableWidgetGrid({
    super.key,
    required this.widgets,
    this.isEditMode = false,
    this.onEditModeChanged,
    this.preferencesKey = 'dashboard_widgets_config',
  });

  @override
  State<CustomizableWidgetGrid> createState() => _CustomizableWidgetGridState();
}

class _CustomizableWidgetGridState extends State<CustomizableWidgetGrid> {
  late List<DashboardWidget> _widgets;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _widgets = List.from(widget.widgets);
    _loadWidgetConfiguration();
  }

  @override
  void didUpdateWidget(CustomizableWidgetGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widgets != widget.widgets) {
      _widgets = List.from(widget.widgets);
      _loadWidgetConfiguration();
    }
  }

  Future<void> _loadWidgetConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(widget.preferencesKey);

      if (configJson != null) {
        final config = jsonDecode(configJson) as Map<String, dynamic>;
        final configuredWidgets = <DashboardWidget>[];

        for (final widget in _widgets) {
          final widgetConfig = config[widget.id];
          if (widgetConfig != null) {
            configuredWidgets.add(DashboardWidget.fromJson(widgetConfig, widget.content));
          } else {
            configuredWidgets.add(widget);
          }
        }

        // Sort by order
        configuredWidgets.sort((a, b) => a.order.compareTo(b.order));

        setState(() {
          _widgets = configuredWidgets;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWidgetConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final config = <String, dynamic>{};

      for (final widget in _widgets) {
        config[widget.id] = widget.toJson();
      }

      await prefs.setString(widget.preferencesKey, jsonEncode(config));
    } catch (e) {
      // Handle error silently
    }
  }

  void _toggleWidgetVisibility(String widgetId) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == widgetId);
      if (index != -1) {
        _widgets[index] = _widgets[index].copyWith(isVisible: !_widgets[index].isVisible);
        _saveWidgetConfiguration();
      }
    });
  }

  void _changeWidgetSize(String widgetId, WidgetSize newSize) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == widgetId);
      if (index != -1) {
        _widgets[index] = _widgets[index].copyWith(size: newSize);
        _saveWidgetConfiguration();
      }
    });
  }

  void _reorderWidgets(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final widget = _widgets.removeAt(oldIndex);
      _widgets.insert(newIndex, widget);

      // Update order values
      for (int i = 0; i < _widgets.length; i++) {
        _widgets[i] = _widgets[i].copyWith(order: i);
      }

      _saveWidgetConfiguration();
    });
  }

  int _getCrossAxisCount(WidgetSize size) {
    switch (size) {
      case WidgetSize.small:
        return 1;
      case WidgetSize.medium:
        return 2;
      case WidgetSize.large:
        return 4;
    }
  }

  double _getChildAspectRatio(WidgetSize size) {
    switch (size) {
      case WidgetSize.small:
        return 1.0;
      case WidgetSize.medium:
        return 1.5;
      case WidgetSize.large:
        return 2.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleWidgets = _widgets.where((w) => w.isVisible).toList();

    return Column(
      children: [
        // Edit mode toggle
        if (widget.onEditModeChanged != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.isEditMode ? 'Exit Edit Mode' : 'Edit Dashboard',
                  style: TextStyle(
                    color: AppTheme.forestGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: widget.isEditMode,
                  onChanged: widget.onEditModeChanged,
                  activeColor: AppTheme.forestGreen,
                ),
              ],
            ),
          ),

        // Widget grid
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleWidgets.length,
            onReorder: widget.isEditMode ? _reorderWidgets : (oldIndex, newIndex) {},
            itemBuilder: (context, index) {
              final dashboardWidget = visibleWidgets[index];
              return _buildWidgetCard(dashboardWidget, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetCard(DashboardWidget dashboardWidget, int index) {
    return Card(
      key: ValueKey(dashboardWidget.id),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget header (only in edit mode)
          if (widget.isEditMode)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.forestGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    color: AppTheme.forestGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dashboardWidget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Size selector
                  DropdownButton<WidgetSize>(
                    value: dashboardWidget.size,
                    items: WidgetSize.values.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(_getSizeLabel(size)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _changeWidgetSize(dashboardWidget.id, value);
                      }
                    },
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.aspect_ratio,
                      size: 16,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Visibility toggle
                  IconButton(
                    icon: Icon(
                      dashboardWidget.isVisible ? Icons.visibility : Icons.visibility_off,
                      color: dashboardWidget.isVisible ? AppTheme.forestGreen : AppTheme.textSecondary,
                    ),
                    onPressed: () => _toggleWidgetVisibility(dashboardWidget.id),
                    tooltip: dashboardWidget.isVisible ? 'Hide widget' : 'Show widget',
                  ),
                ],
              ),
            ),

          // Widget content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      dashboardWidget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                dashboardWidget.content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSizeLabel(WidgetSize size) {
    switch (size) {
      case WidgetSize.small:
        return 'Small';
      case WidgetSize.medium:
        return 'Medium';
      case WidgetSize.large:
        return 'Large';
    }
  }
}







