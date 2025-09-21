class ProductCategory {
  final int? id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  ProductCategory({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      name: json['name'],
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  // For creating new category (exclude id and server-generated fields)
  Map<String, dynamic> toMapForCreate() {
    final map = <String, dynamic>{
      'name': name,
    };
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    return map;
  }
}
