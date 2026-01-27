class Order {
  final int? id;
  final int customer;
  final int shop;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? deliveryAddress;
  final String? notes;
  final String? qrCode;
  final List<OrderItem> items;

  Order({
    this.id,
    required this.customer,
    required this.shop,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryAddress,
    this.notes,
    this.qrCode,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      customer: int.parse(json['customer'].toString()),
      shop: int.parse(json['shop'].toString()),
      status: json['status'],
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      qrCode: json['qr_code'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer,
      'shop': shop,
      'status': status,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'delivery_address': deliveryAddress,
      'notes': notes,
      'qr_code': qrCode,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Order copyWith({
    int? id,
    int? customer,
    int? shop,
    String? status,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deliveryAddress,
    String? notes,
    String? qrCode,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      shop: shop ?? this.shop,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      qrCode: qrCode ?? this.qrCode,
      items: items ?? this.items,
    );
  }
}

class OrderItem {
  final int? id;
  final int order;
  final int product;
  final double quantity;
  final double weight;
  final String weightUnit;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    this.id,
    required this.order,
    required this.product,
    required this.quantity,
    required this.weight,
    required this.weightUnit,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      order: int.parse(json['order'].toString()),
      product: json['product'] is Map
          ? json['product']['id']
          : int.parse(json['product'].toString()),
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toDouble()
          : double.parse(json['quantity'].toString()),
      weight: json['weight'] is num
          ? (json['weight'] as num).toDouble()
          : double.tryParse(json['weight']?.toString() ?? '0.0') ?? 0.0,
      weightUnit: json['weight_unit'] ?? 'kg',
      unitPrice: json['unit_price'] is num
          ? (json['unit_price'] as num).toDouble()
          : double.parse(json['unit_price'].toString()),
      subtotal: json['subtotal'] is num
          ? (json['subtotal'] as num).toDouble()
          : double.parse(json['subtotal'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'product': product,
      'quantity': quantity,
      'weight': weight,
      'weight_unit': weightUnit,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'product_id': product,
      'quantity': quantity,
      'weight': weight,
      'weight_unit': weightUnit,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  OrderItem copyWith({
    int? id,
    int? order,
    int? product,
    double? quantity,
    double? weight,
    String? weightUnit,
    double? unitPrice,
    double? subtotal,
  }) {
    return OrderItem(
      id: id ?? this.id,
      order: order ?? this.order,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
