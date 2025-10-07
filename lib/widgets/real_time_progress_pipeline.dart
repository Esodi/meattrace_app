import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/processing_pipeline.dart';
import '../services/api_service.dart';

class RealTimeProgressPipeline extends StatefulWidget {
  final String title;
  final Duration animationDuration;
  final VoidCallback? onRefresh;

  const RealTimeProgressPipeline({
    super.key,
    required this.title,
    this.animationDuration = const Duration(milliseconds: 800),
    this.onRefresh,
  });

  @override
  State<RealTimeProgressPipeline> createState() => _RealTimeProgressPipelineState();
}

class _RealTimeProgressPipelineState extends State<RealTimeProgressPipeline> 
    with TickerProviderStateMixin {
  late ApiService _apiService;
  ProcessingPipeline? _pipeline;
  bool _isLoading = true;
  String? _error;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _controllers = [];
    _animations = [];
    _loadPipelineData();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPipelineData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _apiService.fetchProcessingPipeline();
      final pipeline = ProcessingPipeline.fromJson(data);

      if (mounted) {
        setState(() {
          _pipeline = pipeline;
          _isLoading = false;
        });
        _setupAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _setupAnimations() {
    if (_pipeline == null) return;

    // Dispose existing controllers
    for (final controller in _controllers) {
      controller.dispose();
    }

    _controllers = List.generate(
      _pipeline!.stages.length,
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

  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      String cleanColor = colorString.replaceAll('#', '');
      
      // Add alpha if not present
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }
      
      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      return AppTheme.dividerGray;
    }
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _loadPipelineData();
                    widget.onRefresh?.call();
                  },
                  tooltip: 'Refresh pipeline data',
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error: $_error'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadPipelineData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_pipeline != null) ...[
              // Overall efficiency indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Pipeline Efficiency',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${_pipeline!.overallEfficiency.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Animals: ${_pipeline!.totalAnimalsInPipeline}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Products: ${_pipeline!.totalProductsInPipeline}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Pipeline stages
              ...List.generate(_pipeline!.stages.length, (index) {
                final stage = _pipeline!.stages[index];
                final isLast = index == _pipeline!.stages.length - 1;
                final stageColor = _parseColor(stage.color);

                return RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _animations.isNotEmpty ? _animations[index] : 
                        const AlwaysStoppedAnimation(1.0),
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
                                      : stageColor.withOpacity(0.2),
                                  border: Border.all(
                                    color: stage.progress >= 1.0
                                        ? AppTheme.successGreen
                                        : stageColor,
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
                                            color: stageColor,
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
                                            stage.name.toUpperCase(),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: stage.progress >= 1.0
                                                ? AppTheme.successGreen.withOpacity(0.1)
                                                : stageColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            stage.status,
                                            style: TextStyle(
                                              color: stage.progress >= 1.0
                                                  ? AppTheme.successGreen
                                                  : stageColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (stage.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        stage.description!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: stage.progress * (_animations.isNotEmpty ? 
                                            _animations[index].value : 1.0),
                                        backgroundColor: stageColor.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(stageColor),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '${stage.completedItems}/${stage.totalItems} items',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${(stage.progress * 100).round()}%)',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondary,
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
                                            '${stage.estimatedTime}min',
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
              
              const SizedBox(height: 24),
              
              // Timeline events section
              if (_pipeline!.timelineEvents.isNotEmpty) ...[
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _pipeline!.timelineEvents.length,
                    itemBuilder: (context, index) {
                      final event = _pipeline!.timelineEvents[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Icon(
                            Icons.timeline,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        title: Text(
                          event.action,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${event.productName} at ${event.location}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Text(
                          '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Footer info
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real-time processing pipeline data from your facility',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Updated: ${_pipeline!.lastUpdated.hour.toString().padLeft(2, '0')}:${_pipeline!.lastUpdated.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}