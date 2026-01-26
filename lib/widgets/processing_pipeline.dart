import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// Represents the state of a pipeline stage
enum PipelineState { pending, processing, completed, error, cancelled }

/// Configuration for pipeline appearance and behavior
class PipelineConfig {
  final Color pendingColor;
  final Color processingColor;
  final Color completedColor;
  final Color errorColor;
  final Color cancelledColor;
  final Duration animationDuration;
  final double stageHeight;
  final double progressBarHeight;
  final bool showProgressPercentage;
  final bool showStageLabels;
  final bool animateTransitions;
  final bool enableHapticFeedback;
  final bool usePlatformAdaptiveStyling;

  const PipelineConfig({
    this.pendingColor = Colors.grey,
    this.processingColor = Colors.blue,
    this.completedColor = Colors.green,
    this.errorColor = Colors.red,
    this.cancelledColor = Colors.orange,
    this.animationDuration = const Duration(milliseconds: 500),
    this.stageHeight = 60.0,
    this.progressBarHeight = 4.0,
    this.showProgressPercentage = true,
    this.showStageLabels = true,
    this.animateTransitions = true,
    this.enableHapticFeedback = true,
    this.usePlatformAdaptiveStyling = true,
  });

  /// Create platform-adaptive configuration
  factory PipelineConfig.adaptive() {
    return PipelineConfig(
      // Use platform-specific colors and styling
      pendingColor: Platform.isIOS ? const Color(0xFF8E8E93) : Colors.grey,
      processingColor: Platform.isIOS ? const Color(0xFF007AFF) : Colors.blue,
      completedColor: Platform.isIOS ? const Color(0xFF34C759) : Colors.green,
      errorColor: Platform.isIOS ? const Color(0xFFFF3B30) : Colors.red,
      cancelledColor: Platform.isIOS ? const Color(0xFFFF9500) : Colors.orange,
      enableHapticFeedback: Platform.isIOS || Platform.isAndroid,
      usePlatformAdaptiveStyling: true,
    );
  }

  /// Create a copy with modified properties
  PipelineConfig copyWith({
    Color? pendingColor,
    Color? processingColor,
    Color? completedColor,
    Color? errorColor,
    Color? cancelledColor,
    Duration? animationDuration,
    double? stageHeight,
    double? progressBarHeight,
    bool? showProgressPercentage,
    bool? showStageLabels,
    bool? animateTransitions,
    bool? enableHapticFeedback,
    bool? usePlatformAdaptiveStyling,
  }) {
    return PipelineConfig(
      pendingColor: pendingColor ?? this.pendingColor,
      processingColor: processingColor ?? this.processingColor,
      completedColor: completedColor ?? this.completedColor,
      errorColor: errorColor ?? this.errorColor,
      cancelledColor: cancelledColor ?? this.cancelledColor,
      animationDuration: animationDuration ?? this.animationDuration,
      stageHeight: stageHeight ?? this.stageHeight,
      progressBarHeight: progressBarHeight ?? this.progressBarHeight,
      showProgressPercentage:
          showProgressPercentage ?? this.showProgressPercentage,
      showStageLabels: showStageLabels ?? this.showStageLabels,
      animateTransitions: animateTransitions ?? this.animateTransitions,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      usePlatformAdaptiveStyling:
          usePlatformAdaptiveStyling ?? this.usePlatformAdaptiveStyling,
    );
  }
}

/// Represents a single stage in the processing pipeline
class PipelineStage {
  final String id;
  final String name;
  final String? description;
  PipelineState state;
  double progress; // 0.0 to 1.0
  String? errorMessage;
  DateTime? startTime;
  DateTime? endTime;

  PipelineStage({
    required this.id,
    required this.name,
    this.description,
    this.state = PipelineState.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.startTime,
    this.endTime,
  });

  /// Update the stage state and progress
  void updateState(
    PipelineState newState, {
    double? progress,
    String? errorMessage,
  }) {
    state = newState;
    if (progress != null) this.progress = progress.clamp(0.0, 1.0);
    if (errorMessage != null) this.errorMessage = errorMessage;

    if (newState == PipelineState.processing && startTime == null) {
      startTime = DateTime.now();
    } else if ((newState == PipelineState.completed ||
            newState == PipelineState.error ||
            newState == PipelineState.cancelled) &&
        endTime == null) {
      endTime = DateTime.now();
    }
  }

  /// Get the color for this stage based on its state
  Color getColor(PipelineConfig config) {
    switch (state) {
      case PipelineState.pending:
        return config.pendingColor;
      case PipelineState.processing:
        return config.processingColor;
      case PipelineState.completed:
        return config.completedColor;
      case PipelineState.error:
        return config.errorColor;
      case PipelineState.cancelled:
        return config.cancelledColor;
    }
  }

  /// Check if the stage is in a final state
  bool get isFinished =>
      state == PipelineState.completed ||
      state == PipelineState.error ||
      state == PipelineState.cancelled;

  /// Get duration of processing if available
  Duration? get duration => startTime != null && endTime != null
      ? endTime!.difference(startTime!)
      : null;
}

/// Main processing pipeline widget
class ProcessingPipeline extends StatefulWidget {
  final List<PipelineStage> stages;
  final PipelineConfig config;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const ProcessingPipeline({
    super.key,
    required this.stages,
    this.config = const PipelineConfig(),
    this.onRetry,
    this.onCancel,
  });

  @override
  State<ProcessingPipeline> createState() => _ProcessingPipelineState();
}

class _ProcessingPipelineState extends State<ProcessingPipeline>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Map<String, AnimationController> _stageControllers;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );

    _stageControllers = {};
    for (final stage in widget.stages) {
      _stageControllers[stage.id] = AnimationController(
        duration: widget.config.animationDuration,
        vsync: this,
      );
    }
  }

  @override
  void didUpdateWidget(ProcessingPipeline oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controllers if stages changed
    if (oldWidget.stages.length != widget.stages.length) {
      _stageControllers.clear();
      for (final stage in widget.stages) {
        _stageControllers[stage.id] = AnimationController(
          duration: widget.config.animationDuration,
          vsync: this,
        );
      }
    }

    // Animate state changes
    if (widget.config.animateTransitions) {
      for (final stage in widget.stages) {
        final oldStage = oldWidget.stages.cast<PipelineStage?>().firstWhere(
          (s) => s?.id == stage.id,
          orElse: () => null,
        );

        if (oldStage != null && oldStage.state != stage.state) {
          _animateStageTransition(stage.id);
        }
      }
    }
  }

  void _animateStageTransition(String stageId) {
    final controller = _stageControllers[stageId];
    if (controller != null && !controller.isAnimating) {
      controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _stageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pipeline visualization
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(_getOverallIcon(), color: _getOverallColor(), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Processing Pipeline',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _buildActionButtons(),
                ],
              ),
              const SizedBox(height: 16),

              // Stages
              ...widget.stages.map((stage) => _buildStageItem(stage)),
            ],
          ),
        ),

        // Error summary if any
        if (_hasErrors()) _buildErrorSummary(),
      ],
    );
  }

  IconData _getOverallIcon() {
    if (widget.stages.any((s) => s.state == PipelineState.error)) {
      return Icons.error_outline;
    } else if (widget.stages.any((s) => s.state == PipelineState.processing)) {
      return Icons.hourglass_top;
    } else if (widget.stages.every((s) => s.state == PipelineState.completed)) {
      return Icons.check_circle_outline;
    } else {
      return Icons.pending;
    }
  }

  Color _getOverallColor() {
    if (widget.stages.any((s) => s.state == PipelineState.error)) {
      return widget.config.errorColor;
    } else if (widget.stages.any((s) => s.state == PipelineState.processing)) {
      return widget.config.processingColor;
    } else if (widget.stages.every((s) => s.state == PipelineState.completed)) {
      return widget.config.completedColor;
    } else {
      return widget.config.pendingColor;
    }
  }

  Widget _buildActionButtons() {
    final hasErrors = _hasErrors();
    final isProcessing = widget.stages.any(
      (s) => s.state == PipelineState.processing,
    );
    final canCancel = !widget.stages.every((s) => s.isFinished);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasErrors && widget.onRetry != null)
          IconButton(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry failed stages',
            iconSize: 20,
          ),
        if (canCancel && widget.onCancel != null)
          IconButton(
            onPressed: isProcessing ? null : widget.onCancel,
            icon: const Icon(Icons.cancel),
            tooltip: 'Cancel processing',
            iconSize: 20,
          ),
      ],
    );
  }

  Widget _buildStageItem(PipelineStage stage) {
    final animation =
        _stageControllers[stage.id]?.view ?? const AlwaysStoppedAnimation(1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stage.getColor(widget.config).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: stage.getColor(widget.config).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stage header
              Row(
                children: [
                  Icon(
                    _getStageIcon(stage.state),
                    color: stage.getColor(widget.config),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stage.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: stage.getColor(widget.config),
                      ),
                    ),
                  ),
                  if (widget.config.showProgressPercentage &&
                      stage.state == PipelineState.processing)
                    Text(
                      '${(stage.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: stage.getColor(widget.config),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              // Description
              if (stage.description != null &&
                  widget.config.showStageLabels) ...[
                const SizedBox(height: 4),
                Text(
                  stage.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],

              // Progress bar
              if (stage.state == PipelineState.processing) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    widget.config.progressBarHeight / 2,
                  ),
                  child: LinearProgressIndicator(
                    value: stage.progress,
                    backgroundColor: stage
                        .getColor(widget.config)
                        .withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stage.getColor(widget.config),
                    ),
                    minHeight: widget.config.progressBarHeight,
                  ),
                ),
              ],

              // Error message
              if (stage.state == PipelineState.error &&
                  stage.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.config.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: widget.config.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stage.errorMessage!,
                          style: TextStyle(
                            color: widget.config.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Duration
              if (stage.duration != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Duration: ${_formatDuration(stage.duration!)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getStageIcon(PipelineState state) {
    switch (state) {
      case PipelineState.pending:
        return Icons.schedule;
      case PipelineState.processing:
        return Icons.hourglass_top;
      case PipelineState.completed:
        return Icons.check_circle;
      case PipelineState.error:
        return Icons.error;
      case PipelineState.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildErrorSummary() {
    final errorStages = widget.stages
        .where((s) => s.state == PipelineState.error)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.config.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.config.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: widget.config.errorColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${errorStages.length} Stage${errorStages.length > 1 ? 's' : ''} Failed',
                style: TextStyle(
                  color: widget.config.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errorStages.map(
            (stage) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${stage.name}: ${stage.errorMessage ?? 'Unknown error'}',
                style: TextStyle(color: widget.config.errorColor, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasErrors() {
    return widget.stages.any((s) => s.state == PipelineState.error);
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}

/// Utility class for managing pipeline operations
class PipelineManager {
  final List<PipelineStage> _stages = [];
  final PipelineConfig config;
  final void Function()? onStateChanged;

  PipelineManager({
    required List<PipelineStage> initialStages,
    this.config = const PipelineConfig(),
    this.onStateChanged,
  }) {
    _stages.addAll(initialStages);
  }

  List<PipelineStage> get stages => List.unmodifiable(_stages);

  /// Update a stage's state
  void updateStage(
    String stageId,
    PipelineState state, {
    double? progress,
    String? errorMessage,
  }) {
    final stage = _stages.firstWhere((s) => s.id == stageId);
    stage.updateState(state, progress: progress, errorMessage: errorMessage);
    onStateChanged?.call();
  }

  /// Start processing a stage
  void startStage(String stageId) {
    updateStage(stageId, PipelineState.processing, progress: 0.0);
  }

  /// Complete a stage
  void completeStage(String stageId) {
    updateStage(stageId, PipelineState.completed, progress: 1.0);
  }

  /// Fail a stage with an error
  void failStage(String stageId, String errorMessage) {
    updateStage(stageId, PipelineState.error, errorMessage: errorMessage);
  }

  /// Cancel a stage
  void cancelStage(String stageId) {
    updateStage(stageId, PipelineState.cancelled);
  }

  /// Update progress of a processing stage
  void updateProgress(String stageId, double progress) {
    final stage = _stages.firstWhere((s) => s.id == stageId);
    if (stage.state == PipelineState.processing) {
      stage.progress = progress.clamp(0.0, 1.0);
      onStateChanged?.call();
    }
  }

  /// Reset all stages to pending
  void reset() {
    for (final stage in _stages) {
      stage.state = PipelineState.pending;
      stage.progress = 0.0;
      stage.errorMessage = null;
      stage.startTime = null;
      stage.endTime = null;
    }
    onStateChanged?.call();
  }

  /// Check if all stages are completed
  bool get isCompleted =>
      _stages.every((s) => s.state == PipelineState.completed);

  /// Check if any stage has errors
  bool get hasErrors => _stages.any((s) => s.state == PipelineState.error);

  /// Check if processing is in progress
  bool get isProcessing =>
      _stages.any((s) => s.state == PipelineState.processing);
}
