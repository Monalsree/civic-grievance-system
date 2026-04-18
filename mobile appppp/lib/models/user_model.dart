class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profileImageUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '0',
      username: json['username'] ?? json['email'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'citizen',
      profileImageUrl: json['profile_image_url'],
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
