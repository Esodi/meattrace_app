import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Custom pie chart widget for displaying distribution data
/// Features: Animated segments, percentage labels, legend, touch interactions
class CustomPieChart extends StatefulWidget {
  final List<PieChartData> data;
  final String? title;
  final double size;
  final bool showLegend;
  final bool showPercentages;
  final bool animate;
  final Duration animationDuration;

  const CustomPieChart({
    super.key,
    required this.data,
    this.title,
    this.size = 200,
    this.showLegend = true,
    this.showPercentages = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _selectedIndex;

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

    final total = widget.data.fold<double>(0, (sum, item) => sum + item.value);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie chart
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return GestureDetector(
                    onTapDown: (details) {
                      _handleTap(details.localPosition);
                    },
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _PieChartPainter(
                        data: widget.data,
                        total: total,
                        showPercentages: widget.showPercentages,
                        animationProgress: _animation.value,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                  );
                },
              ),
              if (widget.showLegend) ...[
                const SizedBox(width: AppTheme.space24),
                Expanded(
                  child: _buildLegend(total),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final percentage = (item.value / total * 100).toStringAsFixed(1);
        final isSelected = _selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.space8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = isSelected ? null : index;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: AppColors.textPrimary, width: 2)
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTypography.bodyMedium().copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: AppTypography.labelMedium().copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.size,
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
              Icons.pie_chart,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'No distribution data',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance > widget.size / 2) {
      setState(() {
        _selectedIndex = null;
      });
      return;
    }

    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    final total = widget.data.fold<double>(0, (sum, item) => sum + item.value);
    var currentAngle = -math.pi / 2;

    for (int i = 0; i < widget.data.length; i++) {
      final sweepAngle = (widget.data[i].value / total) * 2 * math.pi;
      final endAngle = currentAngle + sweepAngle;

      var normalizedAngle = angle;
      var normalizedCurrentAngle = currentAngle;
      var normalizedEndAngle = endAngle;

      if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;
      if (normalizedCurrentAngle < 0) normalizedCurrentAngle += 2 * math.pi;
      if (normalizedEndAngle < 0) normalizedEndAngle += 2 * math.pi;

      if (normalizedCurrentAngle <= normalizedEndAngle) {
        if (normalizedAngle >= normalizedCurrentAngle && normalizedAngle <= normalizedEndAngle) {
          setState(() {
            _selectedIndex = i;
          });
          return;
        }
      } else {
        if (normalizedAngle >= normalizedCurrentAngle || normalizedAngle <= normalizedEndAngle) {
          setState(() {
            _selectedIndex = i;
          });
          return;
        }
      }

      currentAngle = endAngle;
    }
  }
}

/// Custom painter for pie chart
class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;
  final bool showPercentages;
  final double animationProgress;
  final int? selectedIndex;

  _PieChartPainter({
    required this.data,
    required this.total,
    required this.showPercentages,
    required this.animationProgress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    var startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final sweepAngle = (item.value / total) * 2 * math.pi * animationProgress;
      final isSelected = selectedIndex == i;

      // Calculate offset for selected segment
      final segmentRadius = isSelected ? radius + 8 : radius;
      final segmentCenter = isSelected
          ? Offset(
              center.dx + math.cos(startAngle + sweepAngle / 2) * 8,
              center.dy + math.sin(startAngle + sweepAngle / 2) * 8,
            )
          : center;

      // Draw segment
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(segmentCenter.dx, segmentCenter.dy);
      path.arcTo(
        Rect.fromCircle(center: segmentCenter, radius: segmentRadius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, borderPaint);

      // Draw percentage label
      if (showPercentages && animationProgress > 0.7) {
        final percentage = (item.value / total * 100).toStringAsFixed(0);
        final labelAngle = startAngle + sweepAngle / 2;
        final labelRadius = segmentRadius * 0.65;
        final labelX = segmentCenter.dx + math.cos(labelAngle) * labelRadius;
        final labelY = segmentCenter.dy + math.sin(labelAngle) * labelRadius;

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: AppTypography.labelMedium().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

/// Data model for pie chart
class PieChartData {
  final String label;
  final double value;
  final Color color;

  const PieChartData({
    required this.label,
    required this.value,
    required this.color,
  });
}
