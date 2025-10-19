enum SlaughterPartType {
  wholeCarcass,
  leftSide,
  rightSide,
  head,
  feet,
  internalOrgans,
  other,
}

extension SlaughterPartTypeExtension on SlaughterPartType {
  String get value {
    switch (this) {
      case SlaughterPartType.wholeCarcass:
        return 'whole_carcass';
      case SlaughterPartType.leftSide:
        return 'left_side';
      case SlaughterPartType.rightSide:
        return 'right_side';
      case SlaughterPartType.head:
        return 'head';
      case SlaughterPartType.feet:
        return 'feet';
      case SlaughterPartType.internalOrgans:
        return 'internal_organs';
      case SlaughterPartType.other:
        return 'other';
    }
  }

  static SlaughterPartType fromString(String value) {
    switch (value) {
      case 'whole_carcass':
        return SlaughterPartType.wholeCarcass;
      case 'left_side':
        return SlaughterPartType.leftSide;
      case 'right_side':
        return SlaughterPartType.rightSide;
      case 'head':
        return SlaughterPartType.head;
      case 'feet':
        return SlaughterPartType.feet;
      case 'internal_organs':
        return SlaughterPartType.internalOrgans;
      case 'other':
        return SlaughterPartType.other;
      default:
        return SlaughterPartType.other;
    }
  }

  String get displayName {
    switch (this) {
      case SlaughterPartType.wholeCarcass:
        return 'Whole Carcass';
      case SlaughterPartType.leftSide:
        return 'Left Side';
      case SlaughterPartType.rightSide:
        return 'Right Side';
      case SlaughterPartType.head:
        return 'Head';
      case SlaughterPartType.feet:
        return 'Feet';
      case SlaughterPartType.internalOrgans:
        return 'Internal Organs';
      case SlaughterPartType.other:
        return 'Other';
    }
  }
}

class SlaughterPart {
  final int? id;
  final int animalId;
  final SlaughterPartType partType;
  final double weight;
  final String weightUnit;
  final String? description;
  final DateTime createdAt;

  // Transfer fields
  final int? transferredTo;
  final String? transferredToName;
  final DateTime? transferredAt;

  // Receive fields
  final int? receivedBy;
  final DateTime? receivedAt;
  final String? receivedByUsername;
  
  // Selection and usage tracking
  final bool usedInProduct;
  final bool isSelectedForTransfer;

  SlaughterPart({
    this.id,
    required this.animalId,
    required this.partType,
    required this.weight,
    required this.weightUnit,
    this.description,
    required this.createdAt,
    this.transferredTo,
    this.transferredToName,
    this.transferredAt,
    this.receivedBy,
    this.receivedAt,
    this.receivedByUsername,
    this.usedInProduct = false,
    this.isSelectedForTransfer = false,
  });

  factory SlaughterPart.fromMap(Map<String, dynamic> json) {
    return SlaughterPart(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      animalId: int.parse(json['animal'].toString()),
      partType: SlaughterPartTypeExtension.fromString(json['part_type']),
      weight: json['weight'] is num ? (json['weight'] as num).toDouble() : double.parse(json['weight'].toString()),
      weightUnit: json['weight_unit'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      transferredTo: json['transferred_to'] != null ? int.parse(json['transferred_to'].toString()) : null,
      transferredToName: json['transferred_to_name'],
      transferredAt: json['transferred_at'] != null ? DateTime.parse(json['transferred_at']) : null,
      receivedBy: json['received_by'] != null ? int.parse(json['received_by'].toString()) : null,
      receivedAt: json['received_at'] != null ? DateTime.parse(json['received_at']) : null,
      receivedByUsername: json['received_by_username'],
      usedInProduct: json['used_in_product'] ?? false,
      isSelectedForTransfer: json['is_selected_for_transfer'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal': animalId,
      'part_type': partType.value,
      'weight': weight,
      'weight_unit': weightUnit,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'transferred_to': transferredTo,
      'transferred_to_name': transferredToName,
      'transferred_at': transferredAt?.toIso8601String(),
      'received_by': receivedBy,
      'received_at': receivedAt?.toIso8601String(),
      'received_by_username': receivedByUsername,
      'used_in_product': usedInProduct,
      'is_selected_for_transfer': isSelectedForTransfer,
    };
  }

  // For creating new slaughter part
  Map<String, dynamic> toMapForCreate() {
    return {
      'animal': animalId,
      'part_type': partType.value,
      'weight': weight,
      'weight_unit': weightUnit,
      'description': description,
    };
  }

  String get displayName => '${partType.displayName} (${weight.toStringAsFixed(2)} ${weightUnit})';
  
  bool get isTransferred => transferredTo != null;
  bool get isReceived => receivedBy != null;
}

enum CarcassType {
  whole,
  split,
}

extension CarcassTypeExtension on CarcassType {
  String get value {
    switch (this) {
      case CarcassType.whole:
        return 'whole';
      case CarcassType.split:
        return 'split';
    }
  }

  String get displayName {
    switch (this) {
      case CarcassType.whole:
        return 'Whole Carcass';
      case CarcassType.split:
        return 'Split Carcass';
    }
  }

  static CarcassType fromString(String value) {
    switch (value) {
      case 'whole':
        return CarcassType.whole;
      case 'split':
        return CarcassType.split;
      default:
        return CarcassType.whole;
    }
  }
}

class CarcassMeasurement {
  final int? id;
  final int animalId;
  final CarcassType carcassType;
  final Map<String, Map<String, dynamic>> measurements; // {'head_weight': {'value': 5.2, 'unit': 'kg'}}
  final DateTime createdAt;
  final DateTime updatedAt;

  CarcassMeasurement({
    this.id,
    required this.animalId,
    required this.carcassType,
    required this.measurements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarcassMeasurement.fromMap(Map<String, dynamic> json) {
    print('🔧 CarcassMeasurement.fromMap - START');
    print('   Raw measurements: ${json['measurements']}');
    
    // Properly convert nested measurements map
    Map<String, Map<String, dynamic>> measurementsMap = {};
    if (json['measurements'] != null) {
      final rawMeasurements = json['measurements'] as Map<String, dynamic>;
      rawMeasurements.forEach((key, value) {
        if (value is Map) {
          // Convert nested map properly
          measurementsMap[key] = Map<String, dynamic>.from(value as Map);
        } else {
          print('⚠️  Skipping non-map measurement: $key = $value');
        }
      });
    }
    print('   Converted measurements: $measurementsMap');
    
    return CarcassMeasurement(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      animalId: int.parse(json['animal'].toString()),
      carcassType: CarcassTypeExtension.fromString(json['carcass_type'] ?? 'whole'),
      measurements: measurementsMap,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'carcass_type': carcassType.value,
      'measurements': measurements,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating new carcass measurement
  Map<String, dynamic> toMapForCreate() {
    return {
      'animal': animalId,
      'carcass_type': carcassType.value,
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
  final double age;
  final double? liveWeight;
  final DateTime createdAt;
  final bool slaughtered;
  final DateTime? slaughteredAt;
  final String animalId; // Auto-generated unique identifier
  final String? animalName; // Optional user-friendly name/tag
  final String? breed;
  final String abbatoirName;
  final String? healthStatus;
  final bool processed;
  final bool synced;
  // Transfer fields
  final int? transferredTo;
  final String? transferredToName;
  final DateTime? transferredAt;
  // Receive fields
  final int? receivedBy;
  final DateTime? receivedAt;
  // Carcass measurement
  final CarcassMeasurement? carcassMeasurement;
  // Slaughter parts
  final List<SlaughterPart> slaughterParts;
  // Photo field
  final String? photo;

  Animal({
    this.id,
    required this.farmer,
    this.farmerUsername,
    required this.species,
    required this.age,
    required this.liveWeight,
    required this.createdAt,
    required this.slaughtered,
    this.slaughteredAt,
    required this.animalId,
    this.animalName,
    this.breed,
    required this.abbatoirName,
    this.healthStatus,
    this.processed = false,
    this.synced = true,
    this.transferredTo,
    this.transferredToName,
    this.transferredAt,
    this.receivedBy,
    this.receivedAt,
    this.carcassMeasurement,
    this.slaughterParts = const [],
    this.photo,
  });

  factory Animal.fromMap(Map<String, dynamic> json) {
    try {
      final animalId = json['animal_id'] ?? 'UNKNOWN';
      print('🟢 Animal.fromMap - Parsing animal: $animalId');
      print('🟢   - Species: ${json['species']}, Age: ${json['age']}, Slaughtered: ${json['slaughtered']}');
      
      // Safely parse carcass_measurement
      CarcassMeasurement? carcassMeasurement;
      if (json['carcass_measurement'] != null) {
        if (json['carcass_measurement'] is Map) {
          print('🟢   - Has carcass_measurement (Map)');
          carcassMeasurement = CarcassMeasurement.fromMap(json['carcass_measurement'] as Map<String, dynamic>);
        } else {
          print('⚠️   - carcass_measurement is ${json['carcass_measurement'].runtimeType}, expected Map');
        }
      }

      // Safely parse slaughter_parts
      List<SlaughterPart> slaughterParts = [];
      if (json['slaughter_parts'] != null) {
        if (json['slaughter_parts'] is List) {
          print('🟢   - Has ${(json['slaughter_parts'] as List).length} slaughter_parts');
          for (var part in json['slaughter_parts'] as List) {
            if (part is Map) {
              try {
                slaughterParts.add(SlaughterPart.fromMap(part as Map<String, dynamic>));
              } catch (e) {
                print('⚠️   - Failed to parse slaughter part: $e');
              }
            }
          }
        } else {
          print('⚠️   - slaughter_parts is ${json['slaughter_parts'].runtimeType}, expected List');
        }
      }

      print('✅ Animal.fromMap - Successfully parsed: $animalId');
      return Animal(
        id: json['id'] != null ? int.parse(json['id'].toString()) : null,
        farmer: int.parse(json['farmer'].toString()),
        farmerUsername: json['farmer_username'],
        species: json['species'],
        age: json['age'] is num ? (json['age'] as num).toDouble() : double.parse(json['age'].toString()),
        liveWeight: json['live_weight'] != null ? (json['live_weight'] is num ? (json['live_weight'] as num).toDouble() : double.parse(json['live_weight'].toString())) : null,
        createdAt: DateTime.parse(json['created_at']),
        slaughtered: json['slaughtered'],
        slaughteredAt: json['slaughtered_at'] != null
            ? DateTime.parse(json['slaughtered_at'])
            : null,
        animalId: json['animal_id'],
        animalName: json['animal_name'],
        breed: json['breed'],
        abbatoirName: json['abbatoir_name'] ?? '',
        healthStatus: json['health_status'],
        processed: json['processed'] ?? false,
        synced: json['synced'] ?? true,
        transferredTo: json['transferred_to'] != null ? int.parse(json['transferred_to'].toString()) : null,
        transferredToName: json['transferred_to_name'],
        transferredAt: json['transferred_at'] != null
            ? DateTime.parse(json['transferred_at'])
            : null,
        receivedBy: json['received_by'] != null ? int.parse(json['received_by'].toString()) : null,
        receivedAt: json['received_at'] != null
            ? DateTime.parse(json['received_at'])
            : null,
        carcassMeasurement: carcassMeasurement,
        slaughterParts: slaughterParts,
        photo: json['photo'],
      );
    } catch (e, stackTrace) {
      print('❌ Error in Animal.fromMap: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmer': farmer,
      'farmer_username': farmerUsername,
      'species': species,
      'age': age,
      'live_weight': liveWeight,
      'created_at': createdAt.toIso8601String(),
      'slaughtered': slaughtered,
      'slaughtered_at': slaughteredAt?.toIso8601String(),
      'animal_id': animalId,
      'animal_name': animalName,
      'breed': breed,
      'abbatoir_name': abbatoirName,
      'health_status': healthStatus,
      'processed': processed,
      'synced': synced,
      'transferred_to': transferredTo,
      'transferred_to_name': transferredToName,
      'transferred_at': transferredAt?.toIso8601String(),
      'received_by': receivedBy,
      'received_at': receivedAt?.toIso8601String(),
      'carcass_measurement': carcassMeasurement?.toMap(),
      'slaughter_parts': slaughterParts.map((part) => part.toMap()).toList(),
      'photo': photo,
    };
  }

  // For creating new animal (exclude id and auto-generated fields)
  Map<String, dynamic> toMapForCreate() {
    return {
      'species': species.toLowerCase(), // Convert to lowercase to match backend choices
      'age': age,
      'live_weight': liveWeight,
      'animal_name': animalName, // Optional user-friendly name
      'breed': breed,
      'abbatoir_name': abbatoirName,
      'health_status': healthStatus,
      // Note: animal_id is auto-generated by backend, farmer is set automatically from authenticated user
    };
  }
  
  // Helper properties
  bool get isSplitCarcass => carcassMeasurement?.carcassType == CarcassType.split;
  bool get hasSlaughterParts => slaughterParts.isNotEmpty;
}








