class ProcessingStage {
  final int? id;
  final String name;
  final String? description;
  final int order;

  ProcessingStage({
    this.id,
    required this.name,
    this.description,
    required this.order,
  });

  factory ProcessingStage.fromMap(Map<String, dynamic> json) {
    return ProcessingStage(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  factory ProcessingStage.fromJson(Map<String, dynamic> json) {
    return ProcessingStage.fromMap(json);
  }
}







