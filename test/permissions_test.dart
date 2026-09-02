import 'package:flutter_test/flutter_test.dart';
import 'package:osa_management/core/auth/permissions.dart';
import 'package:osa_management/models/user_model.dart';

void main() {
  group('AppPermissions', () {
    test('admin has unrestricted access', () {
      final permissions = AppPermissions(
        const UserModel(name: 'Admin', email: 'admin@test.local', role: 'Administrator'),
      );
      expect(permissions.can('students'), isTrue);
      expect(permissions.can('reports'), isTrue);
      expect(permissions.can('settings'), isTrue);
    });

    test('teacher receives teaching features only', () {
      final permissions = AppPermissions(
        const UserModel(name: 'Teacher', email: 'teacher@test.local', role: 'teacher'),
      );
      expect(permissions.can('students'), isTrue);
      expect(permissions.can('courses'), isTrue);
      expect(permissions.can('attendance'), isTrue);
      expect(permissions.can('subscriptions'), isFalse);
      expect(permissions.can('settings'), isFalse);
    });

    test('unknown role is denied by default', () {
      final permissions = AppPermissions(
        const UserModel(name: 'Unknown', email: 'unknown@test.local', role: 'something_new'),
      );
      expect(permissions.can('students'), isFalse);
      expect(permissions.can('reports'), isFalse);
      expect(permissions.can('settings'), isFalse);
    });
  });
}
