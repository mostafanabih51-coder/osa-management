class DashboardModel {
  final int students;
  final int activeStudents;
  final int teachers;
  final int todayClasses;
  final int todayAttendance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final int expiring7Days;

  const DashboardModel({
    required this.students,
    required this.activeStudents,
    required this.teachers,
    required this.todayClasses,
    required this.todayAttendance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.expiring7Days,
  });

  double get monthlyNet =>
      monthlyIncome - monthlyExpenses;

  factory DashboardModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;

    int number(dynamic value) {
      return int.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    double money(dynamic value) {
      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          0;
    }

    return DashboardModel(
      students: number(data['students']),
      activeStudents: number(
        data['active_students'],
      ),
      teachers: number(data['teachers']),
      todayClasses: number(
        data['today_classes'],
      ),
      todayAttendance: number(
        data['today_attendance'],
      ),
      monthlyIncome: money(
        data['monthly_income'],
      ),
      monthlyExpenses: money(
        data['monthly_expenses'],
      ),
      expiring7Days: number(
        data['expiring_7_days'],
      ),
    );
  }

  factory DashboardModel.empty() {
    return const DashboardModel(
      students: 0,
      activeStudents: 0,
      teachers: 0,
      todayClasses: 0,
      todayAttendance: 0,
      monthlyIncome: 0,
      monthlyExpenses: 0,
      expiring7Days: 0,
    );
  }
}
