class Animal {
  final int? id;
  final int farmer;
  final String species;
  final int age;
  final double weight;
  final DateTime createdAt;
  final bool slaughtered;
  final DateTime? slaughteredAt;
  final String animalId;
  final String? breed;
  final String farmName;
  final String? healthStatus;
  final bool synced;

  Animal({
    this.id,
    required this.farmer,
    required this.species,
    required this.age,
    required this.weight,
    required this.createdAt,
    required this.slaughtered,
    this.slaughteredAt,
    required this.animalId,
    this.breed,
    required this.farmName,
    this.healthStatus,
    this.synced = true,
  });

  factory Animal.fromMap(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      farmer: json['farmer'],
      species: json['species'],
      age: json['age'],
      weight: (json['weight'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      slaughtered: json['slaughtered'],
      slaughteredAt: json['slaughtered_at'] != null
          ? DateTime.parse(json['slaughtered_at'])
          : null,
      animalId: json['animal_id'],
      breed: json['breed'],
      farmName: json['farm_name'],
      healthStatus: json['health_status'],
      synced: json['synced'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmer': farmer,
      'species': species,
      'age': age,
      'weight': weight,
      'created_at': createdAt.toIso8601String(),
      'slaughtered': slaughtered,
      'slaughtered_at': slaughteredAt?.toIso8601String(),
      'animal_id': animalId,
      'breed': breed,
      'farm_name': farmName,
      'health_status': healthStatus,
      'synced': synced,
    };
  }

  // For creating new animal (exclude id and server-generated fields)
  Map<String, dynamic> toMapForCreate() {
    return {
      'species': species.toLowerCase(), // Convert to lowercase to match backend choices
      'age': age,
      'weight': weight,
      'animal_id': animalId, // Now supported by backend
      'breed': breed,
      'farm_name': farmName,
      'health_status': healthStatus,
      // Note: farmer is set automatically by backend from authenticated user
    };
  }
}
