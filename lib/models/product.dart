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
    print('ProductTimelineEvent.fromMap: stage value: ${json['stage']}, type: ${json['stage']?.runtimeType}');
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
  final String processingUnit;
  final int animal;
  final String productType;
  final double quantity;
  final DateTime createdAt;
  final String name;
  final String batchNumber;
  final double? weight;
  final String weightUnit;
  final double price;
  final String description;
  final String manufacturer;
  final int? category;
  final String? qrCode;
  final List<ProductTimelineEvent> timeline;

  // Transfer fields
  final int? transferredTo;
  final DateTime? transferredAt;
  final String? transferredToUsername;
  final int? receivedBy;
  final DateTime? receivedAt;
  final String? receivedByUsername;

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
    this.transferredTo,
    this.transferredAt,
    this.transferredToUsername,
    this.receivedBy,
    this.receivedAt,
    this.receivedByUsername,
  });

  factory Product.fromMap(Map<String, dynamic> json) {
    return Product(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      processingUnit: json['processing_unit'].toString(),
      animal: json['animal'] is Map ? json['animal']['id'] : int.parse(json['animal'].toString()),
      productType: json['product_type'],
      quantity: _safeParseDouble(json['quantity']),
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      batchNumber: json['batch_number'],
      weight: json['weight'] != null ? (json['weight'] is num ? (json['weight'] as num).toDouble() : double.parse(json['weight'].toString())) : null,
      weightUnit: json['weight_unit'],
      price: json['price'] is num ? (json['price'] as num).toDouble() : double.parse(json['price'].toString()),
      description: json['description'],
      manufacturer: json['manufacturer'],
      category: json['category'] is Map ? json['category']['id'] : (json['category'] != null && json['category'].toString().isNotEmpty ? int.parse(json['category'].toString()) : null),
      qrCode: json['qr_code'],
      timeline: (json['timeline'] as List<dynamic>?)
          ?.map((e) => ProductTimelineEvent.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      transferredTo: json['transferred_to'] != null ? int.parse(json['transferred_to'].toString()) : null,
      transferredAt: json['transferred_at'] != null ? DateTime.parse(json['transferred_at']) : null,
      transferredToUsername: json['transferred_to_username'],
      receivedBy: json['received_by'] != null ? int.parse(json['received_by'].toString()) : null,
      receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at']) : null,
      receivedByUsername: json['received_by_username'],
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
  static double _safeParseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    try {
      return double.parse(value.toString());
    } catch (e) {
      // If parsing fails, return a default value
      return 1.0;
    }
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'animal_id': animal,
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
    };
  }
}
