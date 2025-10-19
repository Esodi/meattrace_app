class ProcessingStage {
  final int? id;
  final String name;
  final String? description;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Predefined stage choices matching backend
  static const String received = 'received';
  static const String inspected = 'inspected';
  static const String processed = 'processed';
  static const String packaged = 'packaged';
  static const String stored = 'stored';
  static const String shipped = 'shipped';

  static const List<String> stageChoices = [
    received,
    inspected,
    processed,
    packaged,
    stored,
    shipped,
  ];

  ProcessingStage({
    this.id,
    required this.name,
    this.description,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory ProcessingStage.fromJson(Map<String, dynamic> json) {
    return ProcessingStage(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      order: json['order'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Legacy methods for backward compatibility
  factory ProcessingStage.fromMap(Map<String, dynamic> json) {
    return ProcessingStage.fromJson(json);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  // Computed properties
  bool get isReceived => name == received;
  bool get isInspected => name == inspected;
  bool get isProcessed => name == processed;
  bool get isPackaged => name == packaged;
  bool get isStored => name == stored;
  bool get isShipped => name == shipped;

  String get displayName => name[0].toUpperCase() + name.substring(1);

  bool get isValidStage => stageChoices.contains(name);

  // Helper method to get next stage
  ProcessingStage? getNextStage(List<ProcessingStage> allStages) {
    final sortedStages = allStages..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = sortedStages.indexWhere((stage) => stage.id == id);
    if (currentIndex >= 0 && currentIndex < sortedStages.length - 1) {
      return sortedStages[currentIndex + 1];
    }
    return null;
  }

  // Helper method to get previous stage
  ProcessingStage? getPreviousStage(List<ProcessingStage> allStages) {
    final sortedStages = allStages..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = sortedStages.indexWhere((stage) => stage.id == id);
    if (currentIndex > 0) {
      return sortedStages[currentIndex - 1];
    }
    return null;
  }
}







