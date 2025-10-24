class ProductCategory {
  final int? id;
  final String name;
  final String description;

  ProductCategory({this.id, required this.name, required this.description});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'name': name,
      'description': description,
    };
  }
}
