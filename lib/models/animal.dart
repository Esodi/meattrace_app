class CarcassMeasurement {
  final int? id;
  final int animalId;
  final Map<String, Map<String, dynamic>> measurements; // {'head_weight': {'value': 5.2, 'unit': 'kg'}}
  final DateTime createdAt;
  final DateTime updatedAt;

  CarcassMeasurement({
    this.id,
    required this.animalId,
    required this.measurements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarcassMeasurement.fromMap(Map<String, dynamic> json) {
    return CarcassMeasurement(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      animalId: int.parse(json['animal_id'].toString()),
      measurements: Map<String, Map<String, dynamic>>.from(json['measurements'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'measurements': measurements,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating new carcass measurement
  Map<String, dynamic> toMapForCreate() {
    return {
      'animal_id': animalId,
      'measurements': measurements,
    };
  }

  // Get all measurements as a list
  List<Map<String, dynamic>> getAllMeasurements() {
    return measurements.entries.map((entry) => {
      'name': entry.key,
      'value': entry.value['value'],
      'unit': entry.value['unit'],
    }).toList();
  }

  // Get a specific measurement
  Map<String, dynamic>? getMeasurement(String key) {
    return measurements[key];
  }
}

class Animal {
  final int? id;
  final int farmer;
  final String? farmerUsername; // Farmer's username for display
  final String species;
  final int age;
  final double? weight;
  final DateTime createdAt;
  final bool slaughtered;
  final DateTime? slaughteredAt;
  final String animalId; // Auto-generated unique identifier
  final String? animalName; // Optional user-friendly name/tag
  final String? breed;
  final String farmName;
  final String? healthStatus;
  final bool synced;
  // Transfer fields
  final int? transferredTo;
  final DateTime? transferredAt;
  // Receive fields
  final int? receivedBy;
  final DateTime? receivedAt;
  // Carcass measurement
  final CarcassMeasurement? carcassMeasurement;

  Animal({
    this.id,
    required this.farmer,
    this.farmerUsername,
    required this.species,
    required this.age,
    required this.weight,
    required this.createdAt,
    required this.slaughtered,
    this.slaughteredAt,
    required this.animalId,
    this.animalName,
    this.breed,
    required this.farmName,
    this.healthStatus,
    this.synced = true,
    this.transferredTo,
    this.transferredAt,
    this.receivedBy,
    this.receivedAt,
    this.carcassMeasurement,
  });

  factory Animal.fromMap(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      farmer: int.parse(json['farmer'].toString()),
      farmerUsername: json['farmer_username'],
      species: json['species'],
      age: json['age'] is int ? json['age'] : int.parse(json['age'].toString()),
      weight: json['weight'] != null ? (json['weight'] is num ? (json['weight'] as num).toDouble() : double.parse(json['weight'].toString())) : null,
      createdAt: DateTime.parse(json['created_at']),
      slaughtered: json['slaughtered'],
      slaughteredAt: json['slaughtered_at'] != null
          ? DateTime.parse(json['slaughtered_at'])
          : null,
      animalId: json['animal_id'],
      animalName: json['animal_name'],
      breed: json['breed'],
      farmName: json['farm_name'],
      healthStatus: json['health_status'],
      synced: json['synced'] ?? true,
      transferredTo: json['transferred_to'] != null ? int.parse(json['transferred_to'].toString()) : null,
      transferredAt: json['transferred_at'] != null
          ? DateTime.parse(json['transferred_at'])
          : null,
      receivedBy: json['received_by'] != null ? int.parse(json['received_by'].toString()) : null,
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'])
          : null,
      carcassMeasurement: json['carcass_measurement'] != null
          ? CarcassMeasurement.fromMap(json['carcass_measurement'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmer': farmer,
      'farmer_username': farmerUsername,
      'species': species,
      'age': age,
      'weight': weight,
      'created_at': createdAt.toIso8601String(),
      'slaughtered': slaughtered,
      'slaughtered_at': slaughteredAt?.toIso8601String(),
      'animal_id': animalId,
      'animal_name': animalName,
      'breed': breed,
      'farm_name': farmName,
      'health_status': healthStatus,
      'synced': synced,
      'transferred_to': transferredTo,
      'transferred_at': transferredAt?.toIso8601String(),
      'received_by': receivedBy,
      'received_at': receivedAt?.toIso8601String(),
      'carcass_measurement': carcassMeasurement?.toMap(),
    };
  }

  // For creating new animal (exclude id and auto-generated fields)
  Map<String, dynamic> toMapForCreate() {
    return {
      'species': species.toLowerCase(), // Convert to lowercase to match backend choices
      'age': age,
      'weight': weight,
      'animal_name': animalName, // Optional user-friendly name
      'breed': breed,
      'farm_name': farmName,
      'health_status': healthStatus,
      // Note: animal_id is auto-generated by backend, farmer is set automatically from authenticated user
    };
  }
}








