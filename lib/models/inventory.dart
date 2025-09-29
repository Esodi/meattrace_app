// Import Product model for the relationship
import 'product.dart' as product_model;

// Import Product model for the relationship

class InventoryProduct {
  final int? id;
  final String name;
  final String batchNumber;
  final double weight;
  final String weightUnit;
  final double price;
  final String productType;
  final String? description;
  final String? manufacturer;
  final int? category;
  final String? qrCode;
  final int? processingUnit;
  final int? animal;
  final DateTime createdAt;
  final int? transferredTo;
  final DateTime? transferredAt;
  final int? receivedBy;
  final DateTime? receivedAt;

  InventoryProduct({
    this.id,
    required this.name,
    required this.batchNumber,
    required this.weight,
    required this.weightUnit,
    required this.price,
    required this.productType,
    this.description,
    this.manufacturer,
    this.category,
    this.qrCode,
    this.processingUnit,
    this.animal,
    required this.createdAt,
    this.transferredTo,
    this.transferredAt,
    this.receivedBy,
    this.receivedAt,
  });

  factory InventoryProduct.fromMap(Map<String, dynamic> map) {
    return InventoryProduct(
      id: map['id'],
      name: map['name'] ?? 'Unnamed Product',
      batchNumber: map['batch_number'] ?? 'BATCH001',
      weight: double.tryParse(map['weight']?.toString() ?? '0.0') ?? 0.0,
      weightUnit: map['weight_unit'] ?? 'kg',
      price: double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,
      productType: map['product_type'] ?? 'meat',
      description: map['description'],
      manufacturer: map['manufacturer'],
      category: map['category_id'] != null ? int.tryParse(map['category_id'].toString()) : (map['category'] != null ? int.tryParse(map['category'].toString()) : null),
      qrCode: map['qr_code'],
      processingUnit: map['processing_unit_id'] != null ? int.tryParse(map['processing_unit_id'].toString()) : (map['processing_unit'] != null ? int.tryParse(map['processing_unit'].toString()) : null),
      animal: map['animal_id'] != null ? int.tryParse(map['animal_id'].toString()) : (map['animal'] != null ? int.tryParse(map['animal'].toString()) : null),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      transferredTo: map['transferred_to'],
      transferredAt: map['transferred_at'] != null
          ? DateTime.parse(map['transferred_at'])
          : null,
      receivedBy: map['received_by'],
      receivedAt: map['received_at'] != null
          ? DateTime.parse(map['received_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'batch_number': batchNumber,
      'weight': weight,
      'weight_unit': weightUnit,
      'price': price,
      'product_type': productType,
      'description': description,
      'manufacturer': manufacturer,
      'category': category,
      'qr_code': qrCode,
      'processing_unit': processingUnit,
      'animal': animal,
      'created_at': createdAt.toIso8601String(),
      'transferred_to': transferredTo,
      'transferred_at': transferredAt?.toIso8601String(),
      'received_by': receivedBy,
      'received_at': receivedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'name': name,
      'batch_number': batchNumber,
      'weight': weight,
      'weight_unit': weightUnit,
      'price': price,
      'product_type': productType,
      'description': description,
      'manufacturer': manufacturer,
      'category_id': category,
      'animal_id': animal,
    };
  }
}

class Inventory {
  final int? id;
  final int shop;
  final int product;
  final double quantity;
  final double minStockLevel;
  final DateTime lastUpdated;
  final InventoryProduct? productDetails;
  final String? shopUsername;
  final bool isLowStock;

  Inventory({
    this.id,
    required this.shop,
    required this.product,
    required this.quantity,
    required this.minStockLevel,
    required this.lastUpdated,
    this.productDetails,
    this.shopUsername,
    bool? isLowStock,
  }) : isLowStock = isLowStock ?? (quantity <= minStockLevel);

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      id: map['id'],
      shop: int.tryParse((map['shop_id'] ?? map['shop'])?.toString() ?? '0') ?? 0,
      product: map['product'] is Map ? map['product']['id'] : int.tryParse((map['product_id'] ?? map['product'])?.toString() ?? '0') ?? 0,
      quantity: double.tryParse(map['quantity']?.toString() ?? '0.0') ?? 0.0,
      minStockLevel: double.tryParse(map['min_stock_level']?.toString() ?? '0.0') ?? 0.0,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : DateTime.now(),
      productDetails: map['product'] != null ? InventoryProduct.fromMap(map['product']) : null,
      shopUsername: map['shop']?.toString(),
      isLowStock: map['is_low_stock'] == true || map['is_low_stock'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop': shop,
      'product': product,
      'quantity': quantity,
      'min_stock_level': minStockLevel,
      'last_updated': lastUpdated.toIso8601String(),
      'is_low_stock': isLowStock,
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'product_id': product,
      'quantity': quantity,
      'min_stock_level': minStockLevel,
    };
  }

  Inventory copyWith({
    int? id,
    int? shop,
    int? product,
    double? quantity,
    double? minStockLevel,
    DateTime? lastUpdated,
    InventoryProduct? productDetails,
    String? shopUsername,
    bool? isLowStock,
  }) {
    return Inventory(
      id: id ?? this.id,
      shop: shop ?? this.shop,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      productDetails: productDetails ?? this.productDetails,
      shopUsername: shopUsername ?? this.shopUsername,
      isLowStock: isLowStock ?? this.isLowStock,
    );
  }

  @override
  String toString() {
    return 'Inventory(id: $id, shop: $shop, product: $product, quantity: $quantity, minStockLevel: $minStockLevel, lastUpdated: $lastUpdated, isLowStock: $isLowStock)';
  }
}