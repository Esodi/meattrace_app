/// Model for aggregated sales summary by product name/category
class CategorySalesSummary {
  final String productName;
  final String? categoryName;
  final double totalInitialQuantity;
  final double totalInitialWeight;
  final double totalSoldQuantity;
  final double totalSoldWeight;
  final double remainingQuantity;
  final double remainingWeight;
  final double totalRevenue;
  final DateTime? firstReceivedAt;
  final List<StockAddition> stockAdditions;
  final List<SaleTransaction> transactions;
  final int transactionCount;

  CategorySalesSummary({
    required this.productName,
    this.categoryName,
    required this.totalInitialQuantity,
    required this.totalInitialWeight,
    required this.totalSoldQuantity,
    required this.totalSoldWeight,
    required this.remainingQuantity,
    required this.remainingWeight,
    required this.totalRevenue,
    this.firstReceivedAt,
    required this.stockAdditions,
    required this.transactions,
    required this.transactionCount,
  });

  factory CategorySalesSummary.fromJson(Map<String, dynamic> json) {
    return CategorySalesSummary(
      productName: json['product_name'] ?? '',
      categoryName: json['category_name'],
      totalInitialQuantity: (json['total_initial_quantity'] ?? 0).toDouble(),
      totalInitialWeight: (json['total_initial_weight'] ?? 0).toDouble(),
      totalSoldQuantity: (json['total_sold_quantity'] ?? 0).toDouble(),
      totalSoldWeight: (json['total_sold_weight'] ?? 0).toDouble(),
      remainingQuantity: (json['remaining_quantity'] ?? 0).toDouble(),
      remainingWeight: (json['remaining_weight'] ?? 0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      firstReceivedAt: json['first_received_at'] != null
          ? DateTime.parse(json['first_received_at'])
          : null,
      stockAdditions:
          (json['stock_additions'] as List<dynamic>?)
              ?.map((e) => StockAddition.fromJson(e))
              .toList() ??
          [],
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map((e) => SaleTransaction.fromJson(e))
              .toList() ??
          [],
      transactionCount: json['transaction_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'category_name': categoryName,
      'total_initial_quantity': totalInitialQuantity,
      'total_initial_weight': totalInitialWeight,
      'total_sold_quantity': totalSoldQuantity,
      'total_sold_weight': totalSoldWeight,
      'remaining_quantity': remainingQuantity,
      'remaining_weight': remainingWeight,
      'total_revenue': totalRevenue,
      'first_received_at': firstReceivedAt?.toIso8601String(),
      'stock_additions': stockAdditions.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'transaction_count': transactionCount,
    };
  }

  /// Get percentage of stock sold
  double get soldPercentage {
    if (totalInitialQuantity == 0) return 0;
    return (totalSoldQuantity / totalInitialQuantity) * 100;
  }

  /// Get percentage of stock remaining
  double get remainingPercentage {
    if (totalInitialQuantity == 0) return 0;
    return (remainingQuantity / totalInitialQuantity) * 100;
  }
}

/// Model for stock addition events
class StockAddition {
  final String batchNumber;
  final double quantity;
  final double weight;
  final String weightUnit;
  final DateTime? receivedAt;
  final String? processingUnit;

  StockAddition({
    required this.batchNumber,
    required this.quantity,
    required this.weight,
    required this.weightUnit,
    this.receivedAt,
    this.processingUnit,
  });

  factory StockAddition.fromJson(Map<String, dynamic> json) {
    return StockAddition(
      batchNumber: json['batch_number'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      weightUnit: json['weight_unit'] ?? 'kg',
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'])
          : null,
      processingUnit: json['processing_unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_number': batchNumber,
      'quantity': quantity,
      'weight': weight,
      'weight_unit': weightUnit,
      'received_at': receivedAt?.toIso8601String(),
      'processing_unit': processingUnit,
    };
  }
}

/// Model for individual sale transactions
class SaleTransaction {
  final int saleId;
  final DateTime createdAt;
  final String? customerName;
  final double totalAmount;
  final String paymentMethod;
  final double quantitySold;
  final double weightSold;
  final double subtotal;

  SaleTransaction({
    required this.saleId,
    required this.createdAt,
    this.customerName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.quantitySold,
    required this.weightSold,
    required this.subtotal,
  });

  factory SaleTransaction.fromJson(Map<String, dynamic> json) {
    return SaleTransaction(
      saleId: json['sale_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['customer_name'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'cash',
      quantitySold: (json['quantity_sold'] ?? 0).toDouble(),
      weightSold: (json['weight_sold'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'created_at': createdAt.toIso8601String(),
      'customer_name': customerName,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'quantity_sold': quantitySold,
      'weight_sold': weightSold,
      'subtotal': subtotal,
    };
  }
}
