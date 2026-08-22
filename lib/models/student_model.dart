class StudentModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String grade;
  final String? avatar;

  const StudentModel({required this.id, required this.name, this.email = '', this.phone = '', this.status = 'active', this.grade = '', this.avatar});

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return StudentModel(
      id: parseId(json['id']),
      name: (json['name'] ?? json['full_name'] ?? json['student_name'] ?? 'بدون اسم').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['mobile'] ?? json['phone_number'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      grade: (json['grade'] ?? json['class_name'] ?? json['level'] ?? '').toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'phone': phone, 'status': status, 'grade': grade};
}
