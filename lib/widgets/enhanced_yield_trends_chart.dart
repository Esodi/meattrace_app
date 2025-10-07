import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/yield_trend_data.dart';
import '../providers/yield_trends_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

class EnhancedYieldTrendsChart extends StatefulWidget {
  final String? title;
  final Duration animationDelay;
  final bool showPeriodSelector;
  final bool showMetricSelector;
  final String? fixedRole; // If null, uses current user role
  final VoidCallback? onRefresh;

  const EnhancedYieldTrendsChart({
    super.key,
    this.title,
    this.animationDelay = Duration.zero,
    this.showPeriodSelector = true,
    this.showMetricSelector = true,
    this.fixedRole,
    this.onRefresh,
  });

  @override
  State<EnhancedYieldTrendsChart> createState() => _EnhancedYieldTrendsChartState();
}

class _EnhancedYieldTrendsChartState extends State<EnhancedYieldTrendsChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedMetric = 'primary';
  bool _showSecondaryMetrics = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after delay
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadYieldTrends();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadYieldTrends() {
    final authProvider = context.read<AuthProvider>();
    final yieldTrendsProvider = context.read<YieldTrendsProvider>();
    
    final userRole = widget.fixedRole ?? authProvider.user?.role ?? 'Farmer';
    
    switch (userRole.toLowerCase()) {
      case 'farmer':
        yieldTrendsProvider.fetchFarmerTrends();
        break;
      case 'processingunit':
      case 'processor':
        yieldTrendsProvider.fetchProcessorTrends();
        break;
      case 'shop':
        yieldTrendsProvider.fetchShopTrends();
        break;
    }
  }

  void _refreshData() {
    final authProvider = context.read<AuthProvider>();
    final yieldTrendsProvider = context.read<YieldTrendsProvider>();
    
    final userRole = widget.fixedRole ?? authProvider.user?.role ?? 'Farmer';
    yieldTrendsProvider.refreshTrendsForRole(userRole);
    
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildChart(),
          ),
        );
      },
    );
  }

  Widget _buildChart() {
    return Consumer2<YieldTrendsProvider, AuthProvider>(
      builder: (context, yieldTrendsProvider, authProvider, child) {
        final userRole = widget.fixedRole ?? authProvider.user?.role ?? 'Farmer';
        final trendData = yieldTrendsProvider.getTrendsForRole(userRole);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: Responsive.getCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(yieldTrendsProvider, userRole, trendData),
                const SizedBox(height: 16),
                if (widget.showPeriodSelector)
                  _buildPeriodSelector(yieldTrendsProvider, userRole),
                if (widget.showMetricSelector && trendData != null)
                  _buildMetricSelector(trendData),
                const SizedBox(height: 20),
                _buildChartContent(yieldTrendsProvider, trendData),
                if (trendData != null && _showSecondaryMetrics)
                  _buildSecondaryMetrics(trendData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(YieldTrendsProvider provider, String userRole, YieldTrendData? data) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'Yield Trends',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (data != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${_formatLastUpdated(data.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (provider.isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh data',
          ),
      ],
    );
  }

  Widget _buildPeriodSelector(YieldTrendsProvider provider, String userRole) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: provider.availablePeriods.map((period) {
            final isSelected = provider.currentPeriod == period;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(provider.getPeriodDisplayName(period)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    provider.changePeriod(period, userRole);
                  }
                },
                selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryGreen,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMetricSelector(YieldTrendData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMetric,
                  decoration: const InputDecoration(
                    labelText: 'Metric',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'primary',
                      child: Text(data.primaryMetric.name),
                    ),
                    ...data.secondaryMetrics.asMap().entries.map((entry) {
                      return DropdownMenuItem(
                        value: 'secondary_${entry.key}',
                        child: Text(entry.value.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMetric = value ?? 'primary';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  _showSecondaryMetrics ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _showSecondaryMetrics = !_showSecondaryMetrics;
                  });
                },
                tooltip: _showSecondaryMetrics ? 'Hide metrics' : 'Show all metrics',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(YieldTrendsProvider provider, YieldTrendData? data) {
    if (provider.isLoading) {
      return SizedBox(
        height: Responsive.getChartHeight(context),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.error != null) {
      return SizedBox(
        height: Responsive.getChartHeight(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load yield trends',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (data == null) {
      return SizedBox(
        height: Responsive.getChartHeight(context),
        child: const Center(
          child: Text('No data available'),
        ),
      );
    }

    return _buildLineChart(data);
  }

  Widget _buildLineChart(YieldTrendData data) {
    final selectedMetricData = _getSelectedMetricData(data);
    
    if (selectedMetricData.values.isEmpty) {
      return SizedBox(
        height: Responsive.getChartHeight(context),
        child: const Center(
          child: Text('No data points available'),
        ),
      );
    }

    final maxY = selectedMetricData.maxValue * 1.1;
    final minY = selectedMetricData.minValue * 0.9;

    return SizedBox(
      height: Responsive.getChartHeight(context),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.dividerGray,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.labels.length) {
                    return Text(
                      data.labels[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatYAxisValue(value, selectedMetricData.unit),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppTheme.dividerGray),
          ),
          minX: 0,
          maxX: (selectedMetricData.values.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: selectedMetricData.values.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              color: _getMetricColor(selectedMetricData),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _getMetricColor(selectedMetricData),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _getMetricColor(selectedMetricData).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryMetrics(YieldTrendData data) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricSummaryCard(data.primaryMetric, isPrimary: true),
              ...data.secondaryMetrics.map((metric) => _buildMetricSummaryCard(metric)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSummaryCard(YieldMetric metric, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary 
            ? AppTheme.primaryGreen.withOpacity(0.1)
            : AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(8),
        border: isPrimary 
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metric.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.formattedCurrentValue,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppTheme.primaryGreen : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metric.isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: metric.isPositive ? AppTheme.successGreen : AppTheme.errorRed,
              ),
              const SizedBox(width: 4),
              Text(
                metric.formattedTrend,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: metric.isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  YieldMetric _getSelectedMetricData(YieldTrendData data) {
    if (_selectedMetric == 'primary') {
      return data.primaryMetric;
    } else if (_selectedMetric.startsWith('secondary_')) {
      final index = int.tryParse(_selectedMetric.split('_')[1]) ?? 0;
      if (index < data.secondaryMetrics.length) {
        return data.secondaryMetrics[index];
      }
    }
    return data.primaryMetric;
  }

  Color _getMetricColor(YieldMetric metric) {
    // Color based on metric type or trend
    if (metric.name.toLowerCase().contains('yield') || 
        metric.name.toLowerCase().contains('count')) {
      return AppTheme.primaryGreen;
    } else if (metric.name.toLowerCase().contains('quality') || 
               metric.name.toLowerCase().contains('score')) {
      return AppTheme.secondaryBlue;
    } else if (metric.name.toLowerCase().contains('sales') || 
               metric.name.toLowerCase().contains('revenue')) {
      return AppTheme.accentOrange;
    } else if (metric.name.toLowerCase().contains('rate') || 
               metric.name.toLowerCase().contains('throughput')) {
      return AppTheme.secondaryBurgundy;
    }
    return AppTheme.primaryGreen;
  }

  String _formatYAxisValue(double value, String unit) {
    if (unit == '%') {
      return '${value.toInt()}%';
    } else if (unit == '/5') {
      return value.toStringAsFixed(1);
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}