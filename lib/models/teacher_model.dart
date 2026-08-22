class TeacherModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String status;
  final String? avatar;

  const TeacherModel({required this.id, required this.name, this.email = '', this.phone = '', this.specialization = '', this.status = '', this.avatar});

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : <String, dynamic>{};
    return TeacherModel(
      id: int.tryParse((json['id'] ?? user['id']).toString()) ?? 0,
      name: (json['name'] ?? user['name'] ?? json['full_name'] ?? '').toString(),
      email: (json['email'] ?? user['email'] ?? '').toString(),
      phone: (json['phone'] ?? user['phone'] ?? json['mobile'] ?? '').toString(),
      specialization: (json['specialization'] ?? json['subject'] ?? json['specialty'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      avatar: (json['avatar'] ?? user['avatar'])?.toString(),
    );
  }
}
