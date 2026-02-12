class ShopReceipt {
  final int? id;
  final String? receiptNumber;
  final int shop;
  final String? shopName;
  final int product;
  final String? productName;
  final double receivedQuantity;
  final double receivedWeight;
  final String weightUnit;
  final DateTime receivedAt;
  final int? recordedBy;
  final String? recordedByName;
  final String? notes;
  final DateTime? createdAt;

  ShopReceipt({
    this.id,
    this.receiptNumber,
    required this.shop,
    this.shopName,
    required this.product,
    this.productName,
    required this.receivedQuantity,
    this.receivedWeight = 0.0,
    this.weightUnit = 'kg',
    required this.receivedAt,
    this.recordedBy,
    this.recordedByName,
    this.notes,
    this.createdAt,
  });

  factory ShopReceipt.fromJson(Map<String, dynamic> json) {
    return ShopReceipt(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      receiptNumber: json['receipt_number'],
      shop: int.parse(json['shop'].toString()),
      shopName: json['shop_name'],
      product: int.parse(json['product'].toString()),
      productName: json['product_name'],
      receivedQuantity: json['received_quantity'] is num 
          ? (json['received_quantity'] as num).toDouble() 
          : double.parse(json['received_quantity'].toString()),
      receivedWeight: json['received_weight'] != null
          ? (json['received_weight'] is num
              ? (json['received_weight'] as num).toDouble()
              : double.parse(json['received_weight'].toString()))
          : 0.0,
      weightUnit: json['weight_unit'] ?? 'kg',
      receivedAt: DateTime.parse(json['received_at']),
      recordedBy: json['recorded_by'] != null ? int.parse(json['recorded_by'].toString()) : null,
      recordedByName: json['recorded_by_name'],
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'shop': shop,
      'product': product,
      'received_quantity': receivedQuantity,
      'received_weight': receivedWeight,
      'weight_unit': weightUnit,
      'received_at': receivedAt.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}









