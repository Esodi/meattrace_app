import 'package:intl/intl.dart';

class TraceabilityEntry {
  final String type; // 'animal' or 'slaughter_part'
  final int id;
  final String itemId;
  final String name;
  final String species;
  final DateTime? receivedAt;
  final double initialWeight;
  final double remainingWeight;
  final double processedWeight;
  final double utilizationRate;
  final List<UtilizationHistory> utilizationHistory;
  final String origin;

  TraceabilityEntry({
    required this.type,
    required this.id,
    required this.itemId,
    required this.name,
    required this.species,
    this.receivedAt,
    required this.initialWeight,
    required this.remainingWeight,
    required this.processedWeight,
    required this.utilizationRate,
    required this.utilizationHistory,
    required this.origin,
  });

  factory TraceabilityEntry.fromJson(Map<String, dynamic> json) {
    return TraceabilityEntry(
      type: json['type'] ?? '',
      id: json['id'] ?? 0,
      itemId: json['item_id'] ?? '',
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'])
          : null,
      initialWeight: (json['initial_weight'] ?? 0).toDouble(),
      remainingWeight: (json['remaining_weight'] ?? 0).toDouble(),
      processedWeight: (json['processed_weight'] ?? 0).toDouble(),
      utilizationRate: (json['utilization_rate'] ?? 0).toDouble(),
      utilizationHistory: (json['utilization_history'] as List? ?? [])
          .map((e) => UtilizationHistory.fromJson(e))
          .toList(),
      origin: json['origin'] ?? 'Unknown',
    );
  }

  String get formattedReceivedDate {
    if (receivedAt == null) return 'Unknown Date';
    return DateFormat('MMM dd, yyyy HH:mm').format(receivedAt!);
  }
}

class UtilizationHistory {
  final int id;
  final String name;
  final String batchNumber;
  final double weight;
  final String weightUnit;
  final double quantity;
  final DateTime? createdAt;
  final String? transferredTo;
  final DateTime? transferredAt;
  final String? qrCode;

  UtilizationHistory({
    required this.id,
    required this.name,
    required this.batchNumber,
    required this.weight,
    required this.weightUnit,
    required this.quantity,
    this.createdAt,
    this.transferredTo,
    this.transferredAt,
    this.qrCode,
  });

  factory UtilizationHistory.fromJson(Map<String, dynamic> json) {
    return UtilizationHistory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      batchNumber: json['batch_number'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      weightUnit: json['weight_unit'] ?? 'kg',
      quantity: (json['quantity'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      transferredTo: json['transferred_to'],
      transferredAt: json['transferred_at'] != null
          ? DateTime.parse(json['transferred_at'])
          : null,
      qrCode: json['qr_code'],
    );
  }

  String get formattedDate {
    if (createdAt == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(createdAt!);
  }
}
