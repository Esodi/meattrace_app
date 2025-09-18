class MeatTrace {
  final int? id;
  final String name;
  final String origin;
  final String batchNumber;
  final DateTime timestamp;
  final String status;

  MeatTrace({
    this.id,
    required this.name,
    required this.origin,
    required this.batchNumber,
    required this.timestamp,
    required this.status,
  });

  factory MeatTrace.fromJson(Map<String, dynamic> json) {
    return MeatTrace(
      id: json['id'],
      name: json['name'],
      origin: json['origin'],
      batchNumber: json['batch_number'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'origin': origin,
      'batch_number': batchNumber,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}
