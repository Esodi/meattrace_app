class Shop {
  final int? id;
  final String name;
  final String? description;
  final String? location;
  final String? contactEmail;
  final String? contactPhone;
  final String? businessLicense;
  final String? taxId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isActive;

  Shop({
    this.id,
    required this.name,
    this.description,
    this.location,
    this.contactEmail,
    this.contactPhone,
    this.businessLicense,
    this.taxId,
    this.createdAt,
    this.updatedAt,
    this.isActive,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      businessLicense: json['business_license'],
      taxId: json['tax_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isActive: json['is_active'],
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
      'business_license': businessLicense,
      'tax_id': taxId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'business_license': businessLicense,
      'tax_id': taxId,
    };
  }
}








