class YieldTrendData {
  final String period;
  final String role;
  final YieldMetric primaryMetric;
  final List<YieldMetric> secondaryMetrics;
  final List<String> labels;
  final DateTime lastUpdated;

  YieldTrendData({
    required this.period,
    required this.role,
    required this.primaryMetric,
    required this.secondaryMetrics,
    required this.labels,
    required this.lastUpdated,
  });

  factory YieldTrendData.fromMap(Map<String, dynamic> map) {
    return YieldTrendData(
      period: map['period'] ?? '7d',
      role: map['role'] ?? '',
      primaryMetric: YieldMetric.fromMap(map['primary_metric'] ?? {}),
      secondaryMetrics: (map['secondary_metrics'] as List<dynamic>?)
          ?.map((metric) => YieldMetric.fromMap(metric))
          .toList() ?? [],
      labels: List<String>.from(map['labels'] ?? []),
      lastUpdated: DateTime.tryParse(map['last_updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'role': role,
      'primary_metric': primaryMetric.toMap(),
      'secondary_metrics': secondaryMetrics.map((metric) => metric.toMap()).toList(),
      'labels': labels,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  YieldTrendData copyWith({
    String? period,
    String? role,
    YieldMetric? primaryMetric,
    List<YieldMetric>? secondaryMetrics,
    List<String>? labels,
    DateTime? lastUpdated,
  }) {
    return YieldTrendData(
      period: period ?? this.period,
      role: role ?? this.role,
      primaryMetric: primaryMetric ?? this.primaryMetric,
      secondaryMetrics: secondaryMetrics ?? this.secondaryMetrics,
      labels: labels ?? this.labels,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class YieldMetric {
  final String name;
  final List<double> values;
  final String unit;
  final double trend; // Percentage change
  final bool isPositive;

  YieldMetric({
    required this.name,
    required this.values,
    required this.unit,
    required this.trend,
    required this.isPositive,
  });

  factory YieldMetric.fromMap(Map<String, dynamic> map) {
    return YieldMetric(
      name: map['name'] ?? '',
      values: List<double>.from(map['values']?.map((x) => x.toDouble()) ?? []),
      unit: map['unit'] ?? '',
      trend: map['trend']?.toDouble() ?? 0.0,
      isPositive: map['is_positive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'values': values,
      'unit': unit,
      'trend': trend,
      'is_positive': isPositive,
    };
  }

  YieldMetric copyWith({
    String? name,
    List<double>? values,
    String? unit,
    double? trend,
    bool? isPositive,
  }) {
    return YieldMetric(
      name: name ?? this.name,
      values: values ?? this.values,
      unit: unit ?? this.unit,
      trend: trend ?? this.trend,
      isPositive: isPositive ?? this.isPositive,
    );
  }

  double get currentValue => values.isNotEmpty ? values.last : 0.0;
  double get previousValue => values.length > 1 ? values[values.length - 2] : 0.0;
  double get averageValue => values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
  double get maxValue => values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;
  double get minValue => values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;

  String get formattedTrend {
    final sign = trend >= 0 ? '+' : '';
    return '$sign${trend.toStringAsFixed(1)}%';
  }

  String get formattedCurrentValue {
    if (unit == '%') {
      return '${currentValue.toStringAsFixed(1)}%';
    } else if (unit == '/5') {
      return '${currentValue.toStringAsFixed(1)}/5';
    } else if (unit.contains('/')) {
      return '${currentValue.toStringAsFixed(1)} $unit';
    } else {
      return '${currentValue.toStringAsFixed(0)} $unit';
    }
  }
}