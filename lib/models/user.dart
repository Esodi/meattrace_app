class User {
  final int id;
  final String username;
  final String email;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse((json['user_id'] ?? json['id']).toString()),
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'Farmer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}