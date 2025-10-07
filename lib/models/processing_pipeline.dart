class ProcessingPipelineStage {
  final int id;
  final String name;
  final String? description;
  final int order;
  final double progress;
  final String status;
  final String color;
  final int? estimatedTime;
  final int currentItems;
  final int completedItems;
  final int totalItems;

  ProcessingPipelineStage({
    required this.id,
    required this.name,
    this.description,
    required this.order,
    required this.progress,
    required this.status,
    required this.color,
    this.estimatedTime,
    required this.currentItems,
    required this.completedItems,
    required this.totalItems,
  });

  factory ProcessingPipelineStage.fromJson(Map<String, dynamic> json) {
    return ProcessingPipelineStage(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      order: json['order'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Queued',
      color: json['color'] ?? '#9CA3AF',
      estimatedTime: json['estimated_time'],
      currentItems: json['current_items'] ?? 0,
      completedItems: json['completed_items'] ?? 0,
      totalItems: json['total_items'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'progress': progress,
      'status': status,
      'color': color,
      'estimated_time': estimatedTime,
      'current_items': currentItems,
      'completed_items': completedItems,
      'total_items': totalItems,
    };
  }
}

class ProcessingTimelineEvent {
  final int id;
  final int productId;
  final String productName;
  final String action;
  final String location;
  final String? stage;
  final DateTime timestamp;

  ProcessingTimelineEvent({
    required this.id,
    required this.productId,
    required this.productName,
    required this.action,
    required this.location,
    this.stage,
    required this.timestamp,
  });

  factory ProcessingTimelineEvent.fromJson(Map<String, dynamic> json) {
    return ProcessingTimelineEvent(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      action: json['action'] ?? '',
      location: json['location'] ?? '',
      stage: json['stage'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'action': action,
      'location': location,
      'stage': stage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ProcessingPipeline {
  final List<ProcessingPipelineStage> stages;
  final double overallEfficiency;
  final int totalAnimalsInPipeline;
  final int totalProductsInPipeline;
  final List<ProcessingTimelineEvent> timelineEvents;
  final DateTime lastUpdated;

  ProcessingPipeline({
    required this.stages,
    required this.overallEfficiency,
    required this.totalAnimalsInPipeline,
    required this.totalProductsInPipeline,
    required this.timelineEvents,
    required this.lastUpdated,
  });

  factory ProcessingPipeline.fromJson(Map<String, dynamic> json) {
    return ProcessingPipeline(
      stages: (json['stages'] as List<dynamic>?)
          ?.map((stage) => ProcessingPipelineStage.fromJson(stage))
          .toList() ?? [],
      overallEfficiency: (json['overall_efficiency'] ?? 0.0).toDouble(),
      totalAnimalsInPipeline: json['total_animals_in_pipeline'] ?? 0,
      totalProductsInPipeline: json['total_products_in_pipeline'] ?? 0,
      timelineEvents: (json['timeline_events'] as List<dynamic>?)
          ?.map((event) => ProcessingTimelineEvent.fromJson(event))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stages': stages.map((stage) => stage.toJson()).toList(),
      'overall_efficiency': overallEfficiency,
      'total_animals_in_pipeline': totalAnimalsInPipeline,
      'total_products_in_pipeline': totalProductsInPipeline,
      'timeline_events': timelineEvents.map((event) => event.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}