class CourseModel {
  final int id;
  final String name;
  final String description;
  final String subject;
  final String level;
  final String status;
  final num price;
  final int studentsCount;

  const CourseModel({required this.id, required this.name, this.description = '', this.subject = '', this.level = '', this.status = '', this.price = 0, this.studentsCount = 0});

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
    id: int.tryParse('${j['id'] ?? 0}') ?? 0,
    name: '${j['name'] ?? j['title'] ?? j['course_name'] ?? ''}',
    description: '${j['description'] ?? ''}',
    subject: '${j['subject'] ?? j['subject_name'] ?? ''}',
    level: '${j['level'] ?? j['grade'] ?? j['stage'] ?? ''}',
    status: '${j['status'] ?? ''}',
    price: num.tryParse('${j['price'] ?? j['monthly_price'] ?? 0}') ?? 0,
    studentsCount: int.tryParse('${j['students_count'] ?? j['studentsCount'] ?? 0}') ?? 0,
  );
}
