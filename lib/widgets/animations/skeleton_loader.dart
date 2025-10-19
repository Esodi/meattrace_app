import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

/// Skeleton loading widget for content placeholders
/// Shows animated placeholder while data is loading
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  /// Skeleton for text line
  factory SkeletonLoader.text({
    double? width,
    double height = 16,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
    );
  }

  /// Skeleton for circular avatar
  factory SkeletonLoader.circular({
    required double size,
  }) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }

  /// Skeleton for rectangular card
  factory SkeletonLoader.card({
    double? width,
    double height = 100,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerContainer(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusSmall),
      baseColor: baseColor ?? AppColors.backgroundLight,
      highlightColor: highlightColor ?? Colors.white,
    );
  }
}

/// Shimmer container with gradient animation
class _ShimmerContainer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerContainer({
    this.width,
    this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Loading skeleton for animal cards
class AnimalCardSkeleton extends StatelessWidget {
  const AnimalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          SkeletonLoader.circular(size: 56),
          const SizedBox(width: AppTheme.space12),
          
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader.text(width: 120, height: 20),
                const SizedBox(height: AppTheme.space8),
                SkeletonLoader.text(width: 80, height: 14),
                const SizedBox(height: AppTheme.space4),
                SkeletonLoader.text(width: 100, height: 14),
              ],
            ),
          ),
          
          // Badge skeleton
          SkeletonLoader(
            width: 70,
            height: 24,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton for product cards
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader.card(
            width: double.infinity,
            height: 150,
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                SkeletonLoader.text(width: 150, height: 18),
                const SizedBox(height: AppTheme.space8),
                
                // Batch skeleton
                SkeletonLoader.text(width: 100, height: 14),
                const SizedBox(height: AppTheme.space12),
                
                // Details row skeleton
                Row(
                  children: [
                    Expanded(
                      child: SkeletonLoader.text(height: 14),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: SkeletonLoader.text(height: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton for stats cards
class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader.circular(size: 40),
              const Spacer(),
              SkeletonLoader(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          SkeletonLoader.text(width: 80, height: 32),
          const SizedBox(height: AppTheme.space8),
          SkeletonLoader.text(width: 100, height: 14),
        ],
      ),
    );
  }
}

/// Loading skeleton for list items
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      child: Row(
        children: [
          SkeletonLoader.circular(size: 48),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppTheme.space8),
                SkeletonLoader.text(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen skeleton loader with multiple items
class FullScreenSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function()? itemBuilder;

  const FullScreenSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder?.call() ?? const ListItemSkeleton();
      },
    );
  }
}

/// Grid skeleton loader
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final Widget Function()? itemBuilder;

  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.space16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppTheme.space16,
        mainAxisSpacing: AppTheme.space16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder?.call() ?? SkeletonLoader.card();
      },
    );
  }
}
