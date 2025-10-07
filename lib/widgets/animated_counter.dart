import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AnimatedCounter extends StatefulWidget {
  final num value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<num> _animation;
  num _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<num>(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _animation = Tween<num>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(num value) {
    if (widget.decimalPlaces == 0) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(widget.decimalPlaces);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final displayValue = _animation.value;
          final formattedValue = _formatNumber(displayValue);

          return Text(
            '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}',
            style: widget.style ?? const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          );
        },
      ),
    );
  }
}

class RealTimeCounterCard extends StatefulWidget {
  final String title;
  final num initialValue;
  final Stream<num>? valueStream;
  final Duration updateInterval;
  final TextStyle? valueStyle;
  final String? prefix;
  final String? suffix;
  final int decimalPlaces;
  final IconData? icon;
  final Color? iconColor;

  const RealTimeCounterCard({
    super.key,
    required this.title,
    required this.initialValue,
    this.valueStream,
    this.updateInterval = const Duration(seconds: 1),
    this.valueStyle,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.icon,
    this.iconColor,
  });

  @override
  State<RealTimeCounterCard> createState() => _RealTimeCounterCardState();
}

class _RealTimeCounterCardState extends State<RealTimeCounterCard> {
  late num _currentValue;
  Stream<num>? _subscription;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _subscription = widget.valueStream;
  }

  @override
  void didUpdateWidget(RealTimeCounterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueStream != widget.valueStream) {
      _subscription = widget.valueStream;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 24,
                    color: widget.iconColor ?? AppTheme.forestGreen,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<num>(
              stream: _subscription,
              initialData: _currentValue,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _currentValue = snapshot.data!;
                }
                return AnimatedCounter(
                  value: _currentValue,
                  duration: const Duration(milliseconds: 800),
                  style: widget.valueStyle ?? const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  prefix: widget.prefix,
                  suffix: widget.suffix,
                  decimalPlaces: widget.decimalPlaces,
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Updates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}







