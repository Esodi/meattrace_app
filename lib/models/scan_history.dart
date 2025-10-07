class ScanHistoryItem {
  final String productId;
  final DateTime scannedAt;
  final String? productName;
  final String? status; // 'success', 'error', etc.

  ScanHistoryItem({
    required this.productId,
    required this.scannedAt,
    this.productName,
    this.status = 'success',
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      productId: json['productId'],
      scannedAt: DateTime.parse(json['scannedAt']),
      productName: json['productName'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'scannedAt': scannedAt.toIso8601String(),
      'productName': productName,
      'status': status,
    };
  }
}








