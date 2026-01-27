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
  // processingUnit holds the ProcessingUnit.id (as string or int).
  // Some parts of the app set this as a String (e.g. auth provider),
  // so we accept either and coerce when building the API payload.
  final dynamic processingUnit;
  final String? processingUnitName;
  final int? animal;
  final String? animalAnimalId;
  final String? animalSpecies;
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
  final String? transferredToName;
  final int? receivedBy;
  final DateTime? receivedAt;
  final String? receivedByName;

  // External Source Tracking
  final bool isExternal;
  final int? externalVendorId;
  final String? externalVendorName;
  final double? acquisitionPrice;

  Product({
    this.id,
    required this.processingUnit,
    this.processingUnitName,
    required this.animal,
    this.animalAnimalId,
    this.animalSpecies,
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
    this.transferredToName,
    this.receivedBy,
    this.receivedAt,
    this.receivedByName,
    this.isExternal = false,
    this.externalVendorId,
    this.externalVendorName,
    this.acquisitionPrice,
  });

  factory Product.fromMap(Map<String, dynamic> json) {
    return Product(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      processingUnit: json['processing_unit'].toString(),
      processingUnitName: json['processing_unit_name'],
      animal: json['animal'] != null
          ? (json['animal'] is Map
                ? json['animal']['id']
                : int.parse(json['animal'].toString()))
          : null,
      animalAnimalId: json['animal_animal_id'],
      animalSpecies: json['animal_species'],
      slaughterPartId: json['slaughter_part'] != null
          ? (json['slaughter_part'] is Map
                ? json['slaughter_part']['id']
                : int.parse(json['slaughter_part'].toString()))
          : null,
      slaughterPartName: json['slaughter_part_name'],
      slaughterPartType: json['slaughter_part_type'],
      productType: json['product_type'] ?? 'meat',
      quantity: _safeParseDouble(json['quantity']),
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'] ?? 'Unnamed Product',
      batchNumber: json['batch_number'] ?? 'N/A',
      weight: json['weight'] != null
          ? (json['weight'] is num
                ? (json['weight'] as num).toDouble()
                : double.parse(json['weight'].toString()))
          : null,
      weightUnit: json['weight_unit'] ?? 'kg',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.parse(json['price'].toString()),
      description: json['description'] ?? '',
      manufacturer: json['manufacturer'] ?? 'Unknown',
      category: json['category'] is Map
          ? json['category']['id']
          : (json['category'] != null && json['category'].toString().isNotEmpty
                ? int.parse(json['category'].toString())
                : null),
      qrCode: json['qr_code'],
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map(
                (e) => ProductTimelineEvent.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      transferredTo: json['transferred_to'] != null
          ? int.parse(json['transferred_to'].toString())
          : null,
      transferredAt: json['transferred_at'] != null
          ? DateTime.parse(json['transferred_at'])
          : null,
      transferredToName: json['transferred_to_name'],
      receivedBy: json['received_by_shop'] != null
          ? int.parse(json['received_by_shop'].toString())
          : null,
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'])
          : null,
      receivedByName: json['received_by_shop_name'],
      isExternal:
          json['is_external_source'] == 1 || json['is_external_source'] == true,
      externalVendorId: json['external_vendor_id'] != null
          ? int.tryParse(json['external_vendor_id'].toString())
          : null,
      externalVendorName: json['external_vendor_name'],
      acquisitionPrice: json['acquisition_price'] != null
          ? double.tryParse(json['acquisition_price'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'processing_unit': processingUnit,
      'processing_unit_name': processingUnitName,
      'animal': animal,
      'animal_animal_id': animalAnimalId,
      'animal_species': animalSpecies,
      'slaughter_part': slaughterPartId,
      'slaughter_part_name': slaughterPartName,
      'slaughter_part_type': slaughterPartType,
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
      'transferred_to': transferredTo,
      'transferred_at': transferredAt?.toIso8601String(),
      'transferred_to_name': transferredToName,
      'received_by_shop': receivedBy,
      'received_at': receivedAt?.toIso8601String(),
      'received_by_shop_name': receivedByName,
      'is_external_source': isExternal ? 1 : 0,
      'external_vendor_id': externalVendorId,
      'external_vendor_name': externalVendorName,
      'acquisition_price': acquisitionPrice,
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
    // Ensure processing_unit is sent as an integer id (backend expects FK id)
    int? processingUnitId;
    if (processingUnit is int) {
      processingUnitId = processingUnit as int;
    } else if (processingUnit is String) {
      processingUnitId = int.tryParse(processingUnit as String);
    }

    // Map frontend product types to backend allowed choices (simplified)
    String backendProductType = _mapToBackendProductType(productType);

    return {
      // Align with backend serializer which expects 'processing_unit', 'animal' and 'slaughter_part'
      'processing_unit': processingUnitId,
      'animal': animal,
      'slaughter_part': slaughterPartId,
      'product_type': backendProductType,
      'quantity': quantity,
      'name': name,
      'batch_number': batchNumber,
      'weight': weight,
      'weight_unit': weightUnit,
      'price': price,
      'description': description,
      'manufacturer': manufacturer,
      'category': category,
      'is_external_source': isExternal ? 1 : 0,
      'external_vendor_id': externalVendorId,
      'external_vendor_name': externalVendorName,
      'acquisition_price': acquisitionPrice,
    };
  }

  // Convert UI-level product type labels into backend category choices.
  // Backend Product model uses coarse choices: 'meat', 'milk', 'eggs', 'wool'.
  static String _mapToBackendProductType(String selected) {
    final s = selected.toLowerCase();
    if (s.contains('milk')) return 'milk';
    if (s.contains('egg')) return 'eggs';
    if (s.contains('wool')) return 'wool';
    // Default to 'meat' for all meat related UI labels
    return 'meat';
  }

  Product copyWith({
    int? id,
    dynamic processingUnit,
    String? processingUnitName,
    int? animal,
    String? animalAnimalId,
    String? animalSpecies,
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
    String? transferredToName,
    int? receivedBy,
    DateTime? receivedAt,
    String? receivedByName,
  }) {
    return Product(
      id: id ?? this.id,
      processingUnit: processingUnit ?? this.processingUnit,
      processingUnitName: processingUnitName ?? this.processingUnitName,
      animal: animal ?? this.animal,
      animalAnimalId: animalAnimalId ?? this.animalAnimalId,
      animalSpecies: animalSpecies ?? this.animalSpecies,
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
      transferredToName: transferredToName ?? this.transferredToName,
      receivedBy: receivedBy ?? this.receivedBy,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedByName: receivedByName ?? this.receivedByName,
      isExternal:
          isExternal, // No override for now, assume copy preserves original unless manually handled
      externalVendorId: externalVendorId,
      externalVendorName: externalVendorName,
      acquisitionPrice: acquisitionPrice,
    );
  }
}
