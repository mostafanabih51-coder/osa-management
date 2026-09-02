class AttendanceRecord {
  final int studentId;
  final String studentName;
  final String status;
  final String? note;
  final int? attendanceId;

  const AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.status,
    this.note,
    this.attendanceId,
  });

  AttendanceRecord copyWith({String? status, String? note}) => AttendanceRecord(
        studentId: studentId,
        studentName: studentName,
        status: status ?? this.status,
        note: note ?? this.note,
        attendanceId: attendanceId,
      );

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map ? Map<String, dynamic>.from(json['student']) : null;
    final id = int.tryParse('${json['student_id'] ?? json['studentId'] ?? student?['id'] ?? 0}') ?? 0;
    final name = '${json['student_name'] ?? json['studentName'] ?? student?['name'] ?? student?['full_name'] ?? ''}';
    final rawStatus = '${json['status'] ?? json['attendance_status'] ?? 'absent'}'.toLowerCase();
    return AttendanceRecord(
      studentId: id,
      studentName: name,
      status: rawStatus,
      note: json['note']?.toString(),
      attendanceId: int.tryParse('${json['id'] ?? ''}'),
    );
  }
}
