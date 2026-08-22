class SubscriptionModel {
  final int id;
  final int studentId;
  final String studentName;
  final int courseId;
  final String courseName;
  final String status;
  final num amount;
  final num paid;
  final num remaining;
  final String startDate;
  final String endDate;
  final String paymentStatus;
  final String notes;

  const SubscriptionModel({
    required this.id,
    this.studentId = 0,
    this.studentName = '',
    this.courseId = 0,
    this.courseName = '',
    this.status = 'active',
    this.amount = 0,
    this.paid = 0,
    this.remaining = 0,
    this.startDate = '',
    this.endDate = '',
    this.paymentStatus = '',
    this.notes = '',
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) {
    int id(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;
    num money(dynamic v) => num.tryParse('${v ?? 0}') ?? 0;
    final student = j['student'] is Map ? Map<String, dynamic>.from(j['student']) : <String, dynamic>{};
    final course = j['course'] is Map ? Map<String, dynamic>.from(j['course']) : <String, dynamic>{};
    final amount = money(j['amount'] ?? j['price'] ?? j['total_amount']);
    final paid = money(j['paid'] ?? j['paid_amount'] ?? j['amount_paid']);
    final remaining = j['remaining'] != null || j['remaining_amount'] != null
        ? money(j['remaining'] ?? j['remaining_amount'])
        : amount - paid;
    return SubscriptionModel(
      id: id(j['id']),
      studentId: id(j['student_id'] ?? student['id']),
      studentName: '${j['student_name'] ?? student['name'] ?? student['full_name'] ?? ''}',
      courseId: id(j['course_id'] ?? course['id']),
      courseName: '${j['course_name'] ?? course['name'] ?? course['title'] ?? ''}',
      status: '${j['status'] ?? 'active'}',
      amount: amount,
      paid: paid,
      remaining: remaining < 0 ? 0 : remaining,
      startDate: '${j['start_date'] ?? j['starts_at'] ?? ''}',
      endDate: '${j['end_date'] ?? j['expires_at'] ?? ''}',
      paymentStatus: '${j['payment_status'] ?? ''}',
      notes: '${j['notes'] ?? ''}',
    );
  }
}
