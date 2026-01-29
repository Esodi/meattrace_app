enum ExternalVendorCategory { farmer, abbatoir, processor, distributor, other }

extension ExternalVendorCategoryExtension on ExternalVendorCategory {
  String get value {
    switch (this) {
      case ExternalVendorCategory.farmer:
        return 'farmer';
      case ExternalVendorCategory.abbatoir:
        return 'abbatoir';
      case ExternalVendorCategory.processor:
        return 'processor';
      case ExternalVendorCategory.distributor:
        return 'distributor';
      case ExternalVendorCategory.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ExternalVendorCategory.farmer:
        return 'Farmer';
      case ExternalVendorCategory.abbatoir:
        return 'Abattoir';
      case ExternalVendorCategory.processor:
        return 'Processing Unit';
      case ExternalVendorCategory.distributor:
        return 'Distributor';
      case ExternalVendorCategory.other:
        return 'Other';
    }
  }

  static ExternalVendorCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'farmer':
        return ExternalVendorCategory.farmer;
      case 'abbatoir':
        return ExternalVendorCategory.abbatoir;
      case 'processor':
        return ExternalVendorCategory.processor;
      case 'distributor':
        return ExternalVendorCategory.distributor;
      default:
        return ExternalVendorCategory.other;
    }
  }
}

class ExternalVendor {
  final int? id;
  final String name;
  final String? contactInfo;
  final String? location;
  final ExternalVendorCategory category;
  final DateTime createdAt;

  ExternalVendor({
    this.id,
    required this.name,
    this.contactInfo,
    this.location,
    this.category = ExternalVendorCategory.other,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExternalVendor.fromMap(Map<String, dynamic> json) {
    return ExternalVendor(
      id: json['id'] as int?,
      name: json['name'] as String,
      contactInfo: json['contact_info'] as String?,
      location: json['location'] as String?,
      category: ExternalVendorCategoryExtension.fromString(
        json['category'] ?? 'other',
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_info': contactInfo,
      'location': location,
      'category': category.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExternalVendor copyWith({
    int? id,
    String? name,
    String? contactInfo,
    String? location,
    ExternalVendorCategory? category,
    DateTime? createdAt,
  }) {
    return ExternalVendor(
      id: id ?? this.id,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      location: location ?? this.location,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
