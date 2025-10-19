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
  final int? slaughterPartId; // Reference to the specific slaughter part
  final String? slaughterPartName; // Display name of the slaughter part
  final String? slaughterPartType; // Type code of the slaughter part
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
    this.slaughterPartId,
    this.slaughterPartName,
    this.slaughterPartType,
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
      slaughterPartId: json['slaughter_part'] != null ? (json['slaughter_part'] is Map ? json['slaughter_part']['id'] : int.parse(json['slaughter_part'].toString())) : null,
      slaughterPartName: json['slaughter_part_name'],
      slaughterPartType: json['slaughter_part_type'],
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
      'slaughter_part': slaughterPartId,
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
      'slaughter_part_id': slaughterPartId,
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

  Product copyWith({
    int? id,
    String? processingUnit,
    int? animal,
    int? slaughterPartId,
    String? slaughterPartName,
    String? slaughterPartType,
    String? productType,
    double? quantity,
    DateTime? createdAt,
    String? name,
    String? batchNumber,
    double? weight,
    String? weightUnit,
    double? price,
    String? description,
    String? manufacturer,
    int? category,
    String? qrCode,
    List<ProductTimelineEvent>? timeline,
    int? transferredTo,
    DateTime? transferredAt,
    String? transferredToUsername,
    int? receivedBy,
    DateTime? receivedAt,
    String? receivedByUsername,
  }) {
    return Product(
      id: id ?? this.id,
      processingUnit: processingUnit ?? this.processingUnit,
      animal: animal ?? this.animal,
      slaughterPartId: slaughterPartId ?? this.slaughterPartId,
      slaughterPartName: slaughterPartName ?? this.slaughterPartName,
      slaughterPartType: slaughterPartType ?? this.slaughterPartType,
      productType: productType ?? this.productType,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      batchNumber: batchNumber ?? this.batchNumber,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      price: price ?? this.price,
      description: description ?? this.description,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      qrCode: qrCode ?? this.qrCode,
      timeline: timeline ?? this.timeline,
      transferredTo: transferredTo ?? this.transferredTo,
      transferredAt: transferredAt ?? this.transferredAt,
      transferredToUsername: transferredToUsername ?? this.transferredToUsername,
      receivedBy: receivedBy ?? this.receivedBy,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedByUsername: receivedByUsername ?? this.receivedByUsername,
    );
  }
}








