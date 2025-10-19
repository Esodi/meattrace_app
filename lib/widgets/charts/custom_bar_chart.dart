import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Custom bar chart widget for displaying data comparisons
/// Features: Animated bars, labels, value display, role-based colors
class CustomBarChart extends StatefulWidget {
  final List<BarChartData> data;
  final String? title;
  final double height;
  final Color? primaryColor;
  final bool showValues;
  final bool showLabels;
  final bool animate;
  final Duration animationDuration;

  const CustomBarChart({
    super.key,
    required this.data,
    this.title,
    this.height = 250,
    this.primaryColor,
    this.showValues = true,
    this.showLabels = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<CustomBarChart> createState() => _CustomBarChartState();
}

class _CustomBarChartState extends State<CustomBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    final maxValue = widget.data.map((d) => d.value).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
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
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space16),
          ],
          SizedBox(
            height: widget.height,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _BarChartPainter(
                    data: widget.data,
                    maxValue: maxValue,
                    primaryColor: widget.primaryColor ?? AppColors.farmerPrimary,
                    showValues: widget.showValues,
                    showLabels: widget.showLabels,
                    animationProgress: _animation.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'No data available',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for bar chart
class _BarChartPainter extends CustomPainter {
  final List<BarChartData> data;
  final double maxValue;
  final Color primaryColor;
  final bool showValues;
  final bool showLabels;
  final double animationProgress;

  _BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.primaryColor,
    required this.showValues,
    required this.showLabels,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;

    final barWidth = (size.width / data.length) * 0.6;
    final barSpacing = (size.width / data.length) * 0.4;
    final chartHeight = showLabels ? size.height - 40 : size.height;

    for (int i = 0; i < data.length; i++) {
      final barData = data[i];
      final x = (i * (barWidth + barSpacing)) + (barSpacing / 2);
      final barHeight = (barData.value / maxValue) * chartHeight * animationProgress;
      final y = chartHeight - barHeight;

      // Draw bar
      final barPaint = Paint()
        ..color = barData.color ?? primaryColor
        ..style = PaintingStyle.fill;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(barRect, barPaint);

      // Draw value on top of bar
      if (showValues && animationProgress > 0.5) {
        final valuePainter = TextPainter(
          text: TextSpan(
            text: barData.value.toStringAsFixed(0),
            style: AppTypography.labelMedium().copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valuePainter.layout();
        valuePainter.paint(
          canvas,
          Offset(
            x + (barWidth - valuePainter.width) / 2,
            y - valuePainter.height - 4,
          ),
        );
      }

      // Draw label below chart
      if (showLabels) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: barData.label,
            style: AppTypography.labelSmall().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        labelPainter.layout(maxWidth: barWidth + barSpacing);
        labelPainter.paint(
          canvas,
          Offset(
            x + (barWidth - labelPainter.width) / 2,
            chartHeight + 8,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.data != data;
  }
}

/// Data model for bar chart
class BarChartData {
  final String label;
  final double value;
  final Color? color;

  const BarChartData({
    required this.label,
    required this.value,
    this.color,
  });
}
