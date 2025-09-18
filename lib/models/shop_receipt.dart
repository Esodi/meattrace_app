class ShopReceipt {
  final int? id;
  final int shop;
  final int product;
  final double receivedQuantity;
  final DateTime receivedAt;

  ShopReceipt({
    this.id,
    required this.shop,
    required this.product,
    required this.receivedQuantity,
    required this.receivedAt,
  });

  factory ShopReceipt.fromJson(Map<String, dynamic> json) {
    return ShopReceipt(
      id: json['id'],
      shop: json['shop'],
      product: json['product'],
      receivedQuantity: (json['received_quantity'] as num).toDouble(),
      receivedAt: DateTime.parse(json['received_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop': shop,
      'product': product,
      'received_quantity': receivedQuantity,
      'received_at': receivedAt.toIso8601String(),
    };
  }
}
