import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';

class ProcessorMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? trend;
  final String? trendLabel;
  final VoidCallback? onTap;
  final bool isHovered;

  const ProcessorMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
    this.trendLabel,
    this.onTap,
    this.isHovered = false,
  });

  @override
  State<ProcessorMetricCard> createState() => _ProcessorMetricCardState();
}

class _ProcessorMetricCardState extends State<ProcessorMetricCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _backgroundAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppTheme.forestGreen.withOpacity(0.05),
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    if (widget.isHovered) {
      _hoverController.forward();
    }
  }

  @override
  void didUpdateWidget(ProcessorMetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered != oldWidget.isHovered) {
      if (widget.isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color _getTrendColor(double trend) {
    if (trend > 0) return AppTheme.successGreen;
    if (trend < 0) return AppTheme.errorRed;
    return AppTheme.textSecondary;
  }

  IconData _getTrendIcon(double trend) {
    if (trend > 0) return Icons.trending_up;
    if (trend < 0) return Icons.trending_down;
    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscapeMobile = Responsive.isMobile(context) &&
        MediaQuery.of(context).orientation == Orientation.landscape;
    final cardWidth = isLandscapeMobile ? MediaQuery.of(context).size.width * 0.45 : null;

    return SizedBox(
      width: cardWidth,
      child: AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Card(
          elevation: _elevationAnimation.value,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF4E4BC), // Warm sand light
                    const Color(0xFFE6D4A3), // Warm sand medium
                    const Color(0xFFD4C08C), // Warm sand dark
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _backgroundAnimation.value,
                ),
                padding: Responsive.getCardPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.icon,
                          size: Responsive.getIconSize(context, 24),
                          color: widget.iconColor ?? AppTheme.forestGreen,
                        ),
                        const Spacer(),
                        if (widget.trend != null) ...[
                          Icon(
                            _getTrendIcon(widget.trend!),
                            size: Responsive.getIconSize(context, 20),
                            color: _getTrendColor(widget.trend!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.trend! > 0 ? '+' : ''}${widget.trend!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, 12),
                              fontWeight: FontWeight.w500,
                              color: _getTrendColor(widget.trend!),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (widget.trendLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.trendLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
}







