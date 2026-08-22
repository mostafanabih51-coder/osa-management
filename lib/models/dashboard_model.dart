class DashboardModel {
  final int students;
  final int teachers;
  final int courses;
  final int subscriptions;
  final int attendance;
  final List<DashboardActivity> activities;

  const DashboardModel({
    required this.students,
    required this.teachers,
    required this.courses,
    required this.subscriptions,
    required this.attendance,
    this.activities = const [],
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    int number(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    final activityRaw = data['activities'] ?? data['recent_activities'] ?? [];
    return DashboardModel(
      students: number(data['students'] ?? data['students_count'] ?? data['total_students']),
      teachers: number(data['teachers'] ?? data['teachers_count'] ?? data['total_teachers']),
      courses: number(data['courses'] ?? data['courses_count'] ?? data['total_courses']),
      subscriptions: number(data['subscriptions'] ?? data['subscriptions_count'] ?? data['total_subscriptions']),
      attendance: number(data['attendance'] ?? data['attendance_count'] ?? data['today_attendance']),
      activities: activityRaw is List
          ? activityRaw.whereType<Map>().map((e) => DashboardActivity.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }

  factory DashboardModel.empty() => const DashboardModel(
        students: 0,
        teachers: 0,
        courses: 0,
        subscriptions: 0,
        attendance: 0,
      );
}

class DashboardActivity {
  final String title;
  final String subtitle;
  final String time;

  const DashboardActivity({required this.title, required this.subtitle, required this.time});

  factory DashboardActivity.fromJson(Map<String, dynamic> json) => DashboardActivity(
        title: (json['title'] ?? json['name'] ?? '').toString(),
        subtitle: (json['subtitle'] ?? json['description'] ?? '').toString(),
        time: (json['time'] ?? json['created_at'] ?? '').toString(),
      );
}
