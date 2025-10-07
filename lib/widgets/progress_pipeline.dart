import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/processing_pipeline.dart';

class ProcessingStage {
  final String name;
  final double progress; // 0.0 to 1.0
  final Color color;
  final String? status;
  final Duration? estimatedTime;

  const ProcessingStage({
    required this.name,
    required this.progress,
    required this.color,
    this.status,
    this.estimatedTime,
  });
}

class ProgressPipeline extends StatefulWidget {
  final List<ProcessingStage> stages;
  final String title;
  final Duration animationDuration;

  const ProgressPipeline({
    super.key,
    required this.stages,
    required this.title,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<ProgressPipeline> createState() => _ProgressPipelineState();
}

class _ProgressPipelineState extends State<ProgressPipeline> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.stages.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(widget.stages.length, (index) {
              final stage = widget.stages[index];
              final isLast = index == widget.stages.length - 1;

              return RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animations[index],
                  builder: (context, child) {
                    return Column(
                    children: [
                      Row(
                        children: [
                          // Stage indicator
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: stage.progress >= 1.0
                                  ? AppTheme.successGreen
                                  : stage.color.withOpacity(0.2),
                              border: Border.all(
                                color: stage.progress >= 1.0
                                    ? AppTheme.successGreen
                                    : stage.color,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: stage.progress >= 1.0
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : Text(
                                      '${(stage.progress * 100).round()}',
                                      style: TextStyle(
                                        color: stage.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Stage content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stage.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (stage.status != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: stage.progress >= 1.0
                                              ? AppTheme.successGreen.withOpacity(0.1)
                                              : stage.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          stage.status!,
                                          style: TextStyle(
                                            color: stage.progress >= 1.0
                                                ? AppTheme.successGreen
                                                : stage.color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: stage.progress * _animations[index].value,
                                    backgroundColor: stage.color.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(stage.color),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${(stage.progress * 100 * _animations[index].value).round()}% Complete',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (stage.estimatedTime != null) ...[
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(stage.estimatedTime!),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 16),
                        // Connector line
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 20,
                              alignment: Alignment.center,
                              child: Container(
                                width: 2,
                                height: 20,
                                color: AppTheme.dividerGray,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppTheme.dividerGray.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Processing pipeline stages with real-time progress',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}







