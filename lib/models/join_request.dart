class JoinRequest {
  final int? id;
  final int? user;
  final String? username; // User's username
  final String? email; // User's email
  final String requestType; // 'processing_unit' or 'shop'
  final String status; // 'pending', 'approved', 'rejected', 'expired'
  final int? processingUnit;
  final int? shop;
  final String requestedRole;
  final String? message;
  final String? qualifications;
  final int? reviewedBy;
  final String? responseMessage;
  final DateTime? reviewedAt;
  final DateTime? expiresAt;
  final DateTime? requestedAt; // Alias for createdAt
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JoinRequest({
    this.id,
    this.user,
    this.username,
    this.email,
    required this.requestType,
    required this.status,
    this.processingUnit,
    this.shop,
    required this.requestedRole,
    this.message,
    this.qualifications,
    this.reviewedBy,
    this.responseMessage,
    this.reviewedAt,
    this.expiresAt,
    this.requestedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    return JoinRequest(
      id: json['id'],
      user: json['user'],
      username: json['username'],
      email: json['email'],
      requestType: json['request_type'],
      status: json['status'],
      processingUnit: json['processing_unit'],
      shop: json['shop'],
      requestedRole: json['requested_role'],
      message: json['message'],
      qualifications: json['qualifications'],
      reviewedBy: json['reviewed_by'],
      responseMessage: json['response_message'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      requestedAt: createdAt, // Use createdAt as requestedAt
      createdAt: createdAt,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'username': username,
      'email': email,
      'request_type': requestType,
      'status': status,
      'processing_unit': processingUnit,
      'shop': shop,
      'requested_role': requestedRole,
      'message': message,
      'qualifications': qualifications,
      'reviewed_by': reviewedBy,
      'response_message': responseMessage,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'request_type': requestType,
      'processing_unit': processingUnit,
      'shop': shop,
      'requested_role': requestedRole,
      'message': message,
      'qualifications': qualifications,
    };
  }
}