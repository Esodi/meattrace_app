class ProductCategory {
  final int? id;
  final String name;
  final String description;
  final int? processingUnitId;
  final String? processingUnitName;

  ProductCategory({
    this.id,
    required this.name,
    required this.description,
    this.processingUnitId,
    this.processingUnitName,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      processingUnitId: json['processing_unit'],
      processingUnitName: json['processing_unit_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'processing_unit': processingUnitId,
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'name': name,
      'description': description,
      // processing_unit is auto-set by backend
    };
  }
}
