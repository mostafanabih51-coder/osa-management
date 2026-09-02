import '../../models/user_model.dart';

/// Centralized feature permissions for the mobile client.
/// Backend authorization remains authoritative; these checks only control UI visibility.
class AppPermissions {
  final UserModel? user;
  const AppPermissions(this.user);

  String get role {
    final raw = (user?.role ?? '').trim().toLowerCase();
    return raw.replaceAll(' ', '_').replaceAll('-', '_');
  }

  bool get unrestricted => const {
        'admin',
        'administrator',
        'super_admin',
        'superadmin',
        'manager',
        'owner',
      }.contains(role);

  bool can(String feature) {
    if (unrestricted) return true;

    const matrix = <String, Set<String>>{
      'students': {'teacher', 'staff', 'accountant'},
      'teachers': {'manager', 'staff'},
      'courses': {'teacher', 'staff'},
      'groups': {'teacher', 'staff'},
      'attendance': {'teacher', 'staff'},
      'subscriptions': {'accountant', 'staff'},
      'reports': {'manager', 'accountant', 'staff'},
      'notifications': {'teacher', 'accountant', 'staff'},
      'settings': {'staff'},
    };

    // Missing/unknown roles are intentionally denied for management features.
    return matrix[feature]?.contains(role) ?? false;
  }
}
