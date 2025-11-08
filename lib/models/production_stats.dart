class ProductionStats {
  // Main stats for Production Overview cards
  final int received;       // Total received animals/parts since creation
  final int pending;        // Total animals/parts not yet received or rejected
  final int products;       // Total products created since creation
  final int inStock;        // Products not yet fully transferred to shop
  
  // Detailed stats (optional)
  final int productsCreatedToday;
  final int productsCreatedThisWeek;
  final int animalsReceivedToday;
  final int animalsReceivedThisWeek;
  final double processingThroughputPerDay;
  final double equipmentUptimePercentage;
  final String operationalStatus;
  final int totalProductsTransferred;
  final int productsTransferredToday;
  final double transferSuccessRate;
  final String lastUpdated;

  ProductionStats({
    required this.received,
    required this.pending,
    required this.products,
    required this.inStock,
    this.productsCreatedToday = 0,
    this.productsCreatedThisWeek = 0,
    this.animalsReceivedToday = 0,
    this.animalsReceivedThisWeek = 0,
    this.processingThroughputPerDay = 0.0,
    this.equipmentUptimePercentage = 0.0,
    this.operationalStatus = 'unknown',
    this.totalProductsTransferred = 0,
    this.productsTransferredToday = 0,
    this.transferSuccessRate = 0.0,
    this.lastUpdated = '',
  });

  // Backward compatibility getters
  int get totalProductsCreated => products;
  int get totalAnimalsReceived => received;
  int get pendingAnimalsToProcess => pending;

  factory ProductionStats.fromJson(Map<String, dynamic> json) {
    // Check if response has the new structure with top-level fields
    final details = json['details'] as Map<String, dynamic>? ?? {};
    
    return ProductionStats(
      // Main stats (top-level)
      received: json['received'] ?? 0,
      pending: json['pending'] ?? 0,
      products: json['products'] ?? 0,
      inStock: json['in_stock'] ?? 0,
      
      // Detailed stats (nested in 'details')
      productsCreatedToday: details['products_created_today'] ?? 0,
      productsCreatedThisWeek: details['products_created_this_week'] ?? 0,
      animalsReceivedToday: details['animals_received_today'] ?? 0,
      animalsReceivedThisWeek: details['animals_received_this_week'] ?? 0,
      processingThroughputPerDay: (details['processing_throughput_per_day'] ?? 0.0).toDouble(),
      equipmentUptimePercentage: (details['equipment_uptime_percentage'] ?? 0.0).toDouble(),
      operationalStatus: details['operational_status'] ?? 'unknown',
      totalProductsTransferred: details['total_products_transferred'] ?? 0,
      productsTransferredToday: details['products_transferred_today'] ?? 0,
      transferSuccessRate: (details['transfer_success_rate'] ?? 0.0).toDouble(),
      lastUpdated: details['last_updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'received': received,
      'pending': pending,
      'products': products,
      'in_stock': inStock,
      'details': {
        'products_created_today': productsCreatedToday,
        'products_created_this_week': productsCreatedThisWeek,
        'animals_received_today': animalsReceivedToday,
        'animals_received_this_week': animalsReceivedThisWeek,
        'processing_throughput_per_day': processingThroughputPerDay,
        'equipment_uptime_percentage': equipmentUptimePercentage,
        'operational_status': operationalStatus,
        'total_products_transferred': totalProductsTransferred,
        'products_transferred_today': productsTransferredToday,
        'transfer_success_rate': transferSuccessRate,
        'last_updated': lastUpdated,
      }
    };
  }
}







