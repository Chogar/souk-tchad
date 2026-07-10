class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.phone,
    required this.plan,
    this.role = 'USER',
    required this.isEmailVerified,
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String plan;
  final String role;
  final bool isEmailVerified;

  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      plan: json['plan'] as String? ?? 'FREE',
      role: json['role'] as String? ?? 'USER',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'plan': plan,
        'role': role,
        'isEmailVerified': isEmailVerified,
      };
}
