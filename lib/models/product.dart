class ProductTimelineEvent {
  final DateTime timestamp;
  final String location;
  final String action;
  final int? stage;

  ProductTimelineEvent({
    required this.timestamp,
    required this.location,
    required this.action,
    this.stage,
  });

  factory ProductTimelineEvent.fromMap(Map<String, dynamic> json) {
    return ProductTimelineEvent(
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      action: json['action'],
      stage: json['stage'] != null ? json['stage'] as int : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'action': action,
      'stage': stage,
    };
  }
}

class Product {
  final int? id;
  final int processingUnit;
  final int animal;
  final String productType;
  final double quantity;
  final DateTime createdAt;
  final String name;
  final String batchNumber;
  final double weight;
  final String weightUnit;
  final double price;
  final String description;
  final String manufacturer;
  final int? category;
  final String? qrCode;
  final List<ProductTimelineEvent> timeline;

  Product({
    this.id,
    required this.processingUnit,
    required this.animal,
    required this.productType,
    required this.quantity,
    required this.createdAt,
    required this.name,
    required this.batchNumber,
    required this.weight,
    required this.weightUnit,
    required this.price,
    required this.description,
    required this.manufacturer,
    this.category,
    this.qrCode,
    required this.timeline,
  });

  factory Product.fromMap(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      processingUnit: json['processing_unit'],
      animal: json['animal'],
      productType: json['product_type'],
      quantity: (json['quantity'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      batchNumber: json['batch_number'],
      weight: (json['weight'] as num).toDouble(),
      weightUnit: json['weight_unit'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      manufacturer: json['manufacturer'],
      category: json['category'] != null ? json['category'] as int : null,
      qrCode: json['qr_code'],
      timeline: (json['timeline'] as List<dynamic>?)
          ?.map((e) => ProductTimelineEvent.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'processing_unit': processingUnit,
      'animal': animal,
      'product_type': productType,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'batch_number': batchNumber,
      'weight': weight,
      'weight_unit': weightUnit,
      'price': price,
      'description': description,
      'manufacturer': manufacturer,
      'category': category,
      'qr_code': qrCode,
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }

  // For creating new product (exclude id and server-generated fields)
  Map<String, dynamic> toMapForCreate() {
    return {
      'animal': animal,
      'product_type': productType,
      'quantity': quantity,
      'name': name,
      'batch_number': batchNumber,
      'weight': weight,
      'weight_unit': weightUnit,
      'price': price,
      'description': description,
      'manufacturer': manufacturer,
      'category': category,
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }
}
