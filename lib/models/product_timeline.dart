class ProductTimelineItem {
  final String stage;
  final String description;
  final DateTime timestamp;
  final String? location;

  ProductTimelineItem({
    required this.stage,
    required this.description,
    required this.timestamp,
    this.location,
  });

  factory ProductTimelineItem.fromJson(Map<String, dynamic> json) {
    return ProductTimelineItem(
      stage: json['stage'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
    };
  }
}








