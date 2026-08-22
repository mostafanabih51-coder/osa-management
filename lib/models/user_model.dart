class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String? role;

  const UserModel({this.id, required this.name, required this.email, this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: (json['name'] ?? json['username'] ?? 'مستخدم').toString(),
      email: (json['email'] ?? '').toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}
