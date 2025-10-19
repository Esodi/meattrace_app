class ProcessingUnit {
  final int? id;
  final String name;
  final String? description;
  final String? location;
  final String? contactEmail;
  final String? contactPhone;
  final String? licenseNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProcessingUnit({
    this.id,
    required this.name,
    this.description,
    this.location,
    this.contactEmail,
    this.contactPhone,
    this.licenseNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory ProcessingUnit.fromJson(Map<String, dynamic> json) {
    return ProcessingUnit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      licenseNumber: json['license_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'license_number': licenseNumber,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'license_number': licenseNumber,
    };
  }
}