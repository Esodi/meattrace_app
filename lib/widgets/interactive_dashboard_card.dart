import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

class InteractiveDashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? trailing;
  final bool showProgress;
  final double? progressValue;
  final Duration animationDelay;

  const InteractiveDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
    this.trailing,
    this.showProgress = false,
    this.progressValue,
    this.animationDelay = Duration.zero,
  });

  @override
  State<InteractiveDashboardCard> createState() => _InteractiveDashboardCardState();
}

class _InteractiveDashboardCardState extends State<InteractiveDashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _isHovered ? 8 : 2,
      shadowColor: widget.color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovered) {
          setState(() => _isHovered = hovered);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: Responsive.getCardPadding(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) SizedBox(
                    width: 40,
                    child: widget.trailing!,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Value display
              Text(
                widget.value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),

              // Progress bar if enabled
              if (widget.showProgress && widget.progressValue != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.progressValue,
                    backgroundColor: widget.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(widget.progressValue! * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Duration animationDelay;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.onTap,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveDashboardCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      onTap: onTap,
      animationDelay: animationDelay,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              change,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}







