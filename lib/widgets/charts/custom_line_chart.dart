import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Custom line chart widget for displaying trends over time
/// Features: Animated line drawing, gradient fill, data points, role-based colors
class CustomLineChart extends StatefulWidget {
  final List<LineChartData> data;
  final String? title;
  final double height;
  final Color? lineColor;
  final bool showGradient;
  final bool showPoints;
  final bool showGrid;
  final bool animate;
  final Duration animationDuration;

  const CustomLineChart({
    super.key,
    required this.data,
    this.title,
    this.height = 250,
    this.lineColor,
    this.showGradient = true,
    this.showPoints = true,
    this.showGrid = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<CustomLineChart> createState() => _CustomLineChartState();
}

class _CustomLineChartState extends State<CustomLineChart>
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
        curve: Curves.easeInOutCubic,
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
    final minValue = widget.data.map((d) => d.value).reduce(math.min);

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
                  painter: _LineChartPainter(
                    data: widget.data,
                    maxValue: maxValue,
                    minValue: minValue,
                    lineColor: widget.lineColor ?? AppColors.processorPrimary,
                    showGradient: widget.showGradient,
                    showPoints: widget.showPoints,
                    showGrid: widget.showGrid,
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
              Icons.show_chart,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'No trend data available',
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

/// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final List<LineChartData> data;
  final double maxValue;
  final double minValue;
  final Color lineColor;
  final bool showGradient;
  final bool showPoints;
  final bool showGrid;
  final double animationProgress;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.lineColor,
    required this.showGradient,
    required this.showPoints,
    required this.showGrid,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartHeight = size.height - 40;
    final chartWidth = size.width - 40;
    final padding = 20.0;

    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, size, chartHeight, chartWidth, padding);
    }

    // Calculate points
    final points = <Offset>[];
    final animatedDataLength = (data.length * animationProgress).ceil();

    for (int i = 0; i < animatedDataLength; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final normalizedValue = (data[i].value - minValue) / (maxValue - minValue);
      final y = chartHeight - (normalizedValue * chartHeight) + padding;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Draw gradient fill
    if (showGradient && points.length > 1) {
      _drawGradientFill(canvas, size, points, chartHeight, padding);
    }

    // Draw line
    _drawLine(canvas, points);

    // Draw points
    if (showPoints) {
      _drawPoints(canvas, points);
    }

    // Draw labels
    _drawLabels(canvas, size, chartHeight, padding, animatedDataLength);
  }

  void _drawGrid(Canvas canvas, Size size, double chartHeight, double chartWidth, double padding) {
    final gridPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (i / 4) * chartHeight;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + chartWidth, y),
        gridPaint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      canvas.drawLine(
        Offset(x, padding),
        Offset(x, padding + chartHeight),
        gridPaint,
      );
    }
  }

  void _drawGradientFill(Canvas canvas, Size size, List<Offset> points, double chartHeight, double padding) {
    final gradientPath = Path();
    gradientPath.moveTo(points.first.dx, chartHeight + padding);
    gradientPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      gradientPath.lineTo(points[i].dx, points[i].dy);
    }

    gradientPath.lineTo(points.last.dx, chartHeight + padding);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(gradientPath, gradientPaint);
  }

  void _drawLine(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(linePath, linePaint);
  }

  void _drawPoints(Canvas canvas, List<Offset> points) {
    for (final point in points) {
      // Outer circle
      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 6, outerPaint);

      // Inner circle
      final innerPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, innerPaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, double chartHeight, double padding, int animatedDataLength) {
    for (int i = 0; i < animatedDataLength; i++) {
      final x = padding + (i / (data.length - 1)) * (size.width - 40);

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: AppTypography.labelSmall().copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, chartHeight + padding + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.data != data;
  }
}

/// Data model for line chart
class LineChartData {
  final String label;
  final double value;

  const LineChartData({
    required this.label,
    required this.value,
  });
}
