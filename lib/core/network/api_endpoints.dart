class ApiEndpoints {
  static const login = '/login';
  static const me = '/user';
  static const logout = '/logout';
  static const dashboard = '/dashboard';
  static const students = '/students';
  static String student(int id) => '/students/$id';
  static const teachers = '/teachers';
  static const courses = '/courses';
  static const groups = '/groups';
  static const subscriptions = '/subscriptions';
  static const attendance = '/attendance';
  static const notifications = '/notifications';
  static const reports = '/reports';
}
