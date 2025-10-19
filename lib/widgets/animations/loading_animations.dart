import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Loading overlay widget with customizable message
/// Shows a modal loading indicator over the screen
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showProgress;

  const LoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
    this.progressColor,
    this.showProgress = true,
  });

  /// Show loading overlay
  static void show(
    BuildContext context, {
    String? message,
    Color? progressColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => LoadingOverlay(
        message: message,
        progressColor: progressColor,
      ),
    );
  }

  /// Hide loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space24),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor ?? AppColors.info,
                  ),
                ),
              if (message != null) ...[
                const SizedBox(height: AppTheme.space16),
                Text(
                  message!,
                  style: AppTypography.bodyLarge(),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Success animation widget
class SuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final Color color;
  final double size;

  const SuccessAnimation({
    super.key,
    this.onComplete,
    this.color = AppColors.success,
    this.size = 100,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Checkmark painter for success animation
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Start point
    final startX = centerX - size.width * 0.2;
    final startY = centerY;

    // Middle point
    final midX = centerX - size.width * 0.05;
    final midY = centerY + size.height * 0.15;

    // End point
    final endX = centerX + size.width * 0.25;
    final endY = centerY - size.height * 0.2;

    path.moveTo(startX, startY);

    if (progress < 0.5) {
      final currentProgress = progress * 2;
      path.lineTo(
        startX + (midX - startX) * currentProgress,
        startY + (midY - startY) * currentProgress,
      );
    } else {
      path.lineTo(midX, midY);
      final currentProgress = (progress - 0.5) * 2;
      path.lineTo(
        midX + (endX - midX) * currentProgress,
        midY + (endY - midY) * currentProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Error animation widget
class ErrorAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final Color color;
  final double size;

  const ErrorAnimation({
    super.key,
    this.onComplete,
    this.color = AppColors.error,
    this.size = 100,
  });

  @override
  State<ErrorAnimation> createState() => _ErrorAnimationState();
}

class _ErrorAnimationState extends State<ErrorAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ripple effect animation
class RippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final Duration duration;

  const RippleEffect({
    super.key,
    required this.child,
    this.rippleColor = AppColors.info,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple circles
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final delay = index * 0.33;
              final progress = (_animation.value - delay).clamp(0.0, 1.0);
              
              return Opacity(
                opacity: 1.0 - progress,
                child: Container(
                  width: 100 + (progress * 100),
                  height: 100 + (progress * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.rippleColor,
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Center widget
        widget.child,
      ],
    );
  }
}

/// Progress indicator with percentage
class ProgressIndicatorWithPercentage extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;

  const ProgressIndicatorWithPercentage({
    super.key,
    required this.progress,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.bodyLarge(),
          ),
          const SizedBox(height: AppTheme.space8),
        ],
        
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: AppColors.backgroundLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.info,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: AppTypography.headlineMedium().copyWith(
                color: color ?? AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bouncing dots loader
class BouncingDotsLoader extends StatefulWidget {
  final Color color;
  final double size;

  const BouncingDotsLoader({
    super.key,
    this.color = AppColors.info,
    this.size = 12,
  });

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay).clamp(0.0, 1.0);
            final offset = -10 * (1 - (progress * 2 - 1).abs());

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size / 4),
              transform: Matrix4.translationValues(0, offset, 0),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
