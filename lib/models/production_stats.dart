class ProductionStats {
  final int totalProductsCreated;
  final int productsCreatedToday;
  final int productsCreatedThisWeek;
  final int totalAnimalsReceived;
  final int animalsReceivedToday;
  final int animalsReceivedThisWeek;
  final double processingThroughputPerDay;
  final double equipmentUptimePercentage;
  final int pendingAnimalsToProcess;
  final String operationalStatus;
  final int totalProductsTransferred;
  final int productsTransferredToday;
  final double transferSuccessRate;
  final String lastUpdated;

  ProductionStats({
    required this.totalProductsCreated,
    required this.productsCreatedToday,
    required this.productsCreatedThisWeek,
    required this.totalAnimalsReceived,
    required this.animalsReceivedToday,
    required this.animalsReceivedThisWeek,
    required this.processingThroughputPerDay,
    required this.equipmentUptimePercentage,
    required this.pendingAnimalsToProcess,
    required this.operationalStatus,
    required this.totalProductsTransferred,
    required this.productsTransferredToday,
    required this.transferSuccessRate,
    required this.lastUpdated,
  });

  factory ProductionStats.fromJson(Map<String, dynamic> json) {
    return ProductionStats(
      totalProductsCreated: json['total_products_created'] ?? 0,
      productsCreatedToday: json['products_created_today'] ?? 0,
      productsCreatedThisWeek: json['products_created_this_week'] ?? 0,
      totalAnimalsReceived: json['total_animals_received'] ?? 0,
      animalsReceivedToday: json['animals_received_today'] ?? 0,
      animalsReceivedThisWeek: json['animals_received_this_week'] ?? 0,
      processingThroughputPerDay: (json['processing_throughput_per_day'] ?? 0.0).toDouble(),
      equipmentUptimePercentage: (json['equipment_uptime_percentage'] ?? 0.0).toDouble(),
      pendingAnimalsToProcess: json['pending_animals_to_process'] ?? 0,
      operationalStatus: json['operational_status'] ?? 'unknown',
      totalProductsTransferred: json['total_products_transferred'] ?? 0,
      productsTransferredToday: json['products_transferred_today'] ?? 0,
      transferSuccessRate: (json['transfer_success_rate'] ?? 0.0).toDouble(),
      lastUpdated: json['last_updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products_created': totalProductsCreated,
      'products_created_today': productsCreatedToday,
      'products_created_this_week': productsCreatedThisWeek,
      'total_animals_received': totalAnimalsReceived,
      'animals_received_today': animalsReceivedToday,
      'animals_received_this_week': animalsReceivedThisWeek,
      'processing_throughput_per_day': processingThroughputPerDay,
      'equipment_uptime_percentage': equipmentUptimePercentage,
      'pending_animals_to_process': pendingAnimalsToProcess,
      'operational_status': operationalStatus,
      'total_products_transferred': totalProductsTransferred,
      'products_transferred_today': productsTransferredToday,
      'transfer_success_rate': transferSuccessRate,
      'last_updated': lastUpdated,
    };
  }
}