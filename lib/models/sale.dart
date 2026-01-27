class Sale {
  final int? id;
  final int shop;
  final int soldBy;
  final String? customerName;
  final String? customerPhone;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final String? qrCode;
  final List<SaleItem> items;

  Sale({
    this.id,
    required this.shop,
    required this.soldBy,
    this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    this.qrCode,
    this.items = const [],
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      shop: int.parse(json['shop'].toString()),
      soldBy: int.parse(json['sold_by'].toString()),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.parse(json['total_amount'].toString()),
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      qrCode: json['qr_code'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => SaleItem.fromJson(item))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop': shop,
      'sold_by': soldBy,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'qr_code': qrCode,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Sale copyWith({
    int? id,
    int? shop,
    int? soldBy,
    String? customerName,
    String? customerPhone,
    double? totalAmount,
    String? paymentMethod,
    DateTime? createdAt,
    String? qrCode,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      shop: shop ?? this.shop,
      soldBy: soldBy ?? this.soldBy,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      qrCode: qrCode ?? this.qrCode,
      items: items ?? this.items,
    );
  }
}

class SaleItem {
  final int? id;
  final int sale;
  final int product;
  final String? productName;
  final String? batchNumber;
  final double quantity;
  final double weight;
  final String weightUnit;
  final double unitPrice;
  final double subtotal;

  SaleItem({
    this.id,
    required this.sale,
    required this.product,
    this.productName,
    this.batchNumber,
    required this.quantity,
    required this.weight,
    required this.weightUnit,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      sale: int.parse(json['sale'].toString()),
      product: json['product'] is Map
          ? json['product']['id']
          : int.parse(json['product'].toString()),
      productName:
          json['product_name'] ??
          (json['product'] is Map ? json['product']['name'] : null),
      batchNumber:
          json['batch_number'] ??
          (json['product'] is Map ? json['product']['batch_number'] : null),
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
      'sale': sale,
      'product': product,
      'product_name': productName,
      'batch_number': batchNumber,
      'quantity': quantity,
      'weight': weight,
      'weight_unit': weightUnit,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}
