import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../providers/animal_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

/// Processor Analytics Screen - Performance metrics and insights
class ProcessorAnalyticsScreen extends StatefulWidget {
  const ProcessorAnalyticsScreen({super.key});

  @override
  State<ProcessorAnalyticsScreen> createState() => _ProcessorAnalyticsScreenState();
}

class _ProcessorAnalyticsScreenState extends State<ProcessorAnalyticsScreen> {
  String _selectedPeriod = 'Week';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      
      await Future.wait([
        productProvider.fetchProducts(),
        animalProvider.fetchAnimals(slaughtered: null),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Analytics',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => ['Week', 'Month', 'Year'].map((period) {
              return PopupMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: Row(
                children: [
                  Text(
                    _selectedPeriod,
                    style: AppTypography.labelLarge().copyWith(
                      color: AppColors.processorPrimary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.processorPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.processorPrimary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.processorPrimary,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space16),
                children: [
                  // Key Metrics
                  _buildMetricsGrid(),
                  const SizedBox(height: AppTheme.space24),

                  // Production Chart
                  _buildSectionHeader('Production Trends'),
                  const SizedBox(height: AppTheme.space12),
                  _buildProductionChart(),
                  const SizedBox(height: AppTheme.space24),

                  // Product Distribution
                  _buildSectionHeader('Product Distribution'),
                  const SizedBox(height: AppTheme.space12),
                  _buildProductDistribution(),
                  const SizedBox(height: AppTheme.space24),

                  // Quality Metrics
                  _buildSectionHeader('Quality Grades'),
                  const SizedBox(height: AppTheme.space12),
                  _buildQualityMetrics(),
                  const SizedBox(height: AppTheme.space24),

                  // Recent Activity
                  _buildSectionHeader('Recent Activity'),
                  const SizedBox(height: AppTheme.space12),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headlineSmall().copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Consumer2<ProductProvider, AnimalProvider>(
      builder: (context, productProvider, animalProvider, child) {
        final totalProducts = productProvider.products.length;
        final totalAnimals = animalProvider.animals.length;
        final totalRevenue = productProvider.products.fold<double>(
          0,
          (sum, product) => sum + (product.price * product.quantity),
        );
        final avgProductionTime = 2.5; // Mock data

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.space12,
          mainAxisSpacing: AppTheme.space12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Products',
              totalProducts.toString(),
              Icons.inventory_2,
              AppColors.processorPrimary,
              '+12% vs last $_selectedPeriod',
            ),
            _buildMetricCard(
              'Animals Processed',
              totalAnimals.toString(),
              Icons.pets,
              AppColors.info,
              '+8% vs last $_selectedPeriod',
            ),
            _buildMetricCard(
              'Revenue',
              '\$${totalRevenue.toStringAsFixed(0)}',
              Icons.attach_money,
              AppColors.success,
              '+15% vs last $_selectedPeriod',
            ),
            _buildMetricCard(
              'Avg. Time',
              '${avgProductionTime}d',
              Icons.schedule,
              AppColors.warning,
              '-5% vs last $_selectedPeriod',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.headlineLarge().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                trend,
                style: AppTypography.caption().copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.textSecondary.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTypography.caption(),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Text(
                      labels[value.toInt()],
                      style: AppTypography.caption(),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 30),
                const FlSpot(1, 45),
                const FlSpot(2, 40),
                const FlSpot(3, 60),
                const FlSpot(4, 55),
                const FlSpot(5, 70),
                const FlSpot(6, 65),
              ],
              isCurved: true,
              color: AppColors.processorPrimary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.processorPrimary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDistribution() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDistributionItem('Fresh Meat', 45, AppColors.processorPrimary),
          const SizedBox(height: AppTheme.space12),
          _buildDistributionItem('Ground Beef', 25, AppColors.info),
          const SizedBox(height: AppTheme.space12),
          _buildDistributionItem('Steak', 20, AppColors.success),
          const SizedBox(height: AppTheme.space12),
          _buildDistributionItem('Other', 10, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMedium()),
            Text(
              '$percentage%',
              style: AppTypography.labelLarge().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildQualityMetrics() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQualityBadge('Premium', 45, 5),
          _buildQualityBadge('Choice', 30, 4),
          _buildQualityBadge('Select', 20, 3),
          _buildQualityBadge('Standard', 5, 2),
        ],
      ),
    );
  }

  Widget _buildQualityBadge(String grade, int count, int stars) {
    return Column(
      children: [
        Text(
          grade,
          style: AppTypography.labelLarge().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < stars ? Icons.star : Icons.star_border,
              color: AppColors.warning,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          count.toString(),
          style: AppTypography.headlineMedium().copyWith(
            color: AppColors.processorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActivityItem(
            'New product created',
            'Premium Beef Steak - BTH-2024-045',
            '2 hours ago',
            Icons.add_circle,
            AppColors.success,
          ),
          const Divider(height: AppTheme.space24),
          _buildActivityItem(
            'Animals received',
            '5 animals transferred from Abbatoir A',
            '5 hours ago',
            Icons.download_done,
            AppColors.info,
          ),
          const Divider(height: AppTheme.space24),
          _buildActivityItem(
            'Product transferred',
            'Ground Beef sent to Shop B',
            '1 day ago',
            Icons.local_shipping,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge().copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                subtitle,
                style: AppTypography.bodyMedium().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: AppTypography.caption().copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
