import 'package:flutter_test/flutter_test.dart';
import 'package:osa_management/models/user_model.dart';

void main() {
  test('UserModel reads supported API fields', () {
    final user = UserModel.fromJson({
      'id': 42,
      'username': 'Ahmed',
      'email': 'ahmed@example.com',
      'role': 'teacher',
    });

    expect(user.id, 42);
    expect(user.name, 'Ahmed');
    expect(user.email, 'ahmed@example.com');
    expect(user.role, 'teacher');
  });

  test('UserModel round trips through JSON', () {
    const original = UserModel(
      id: 7,
      name: 'Test User',
      email: 'test@example.com',
      role: 'staff',
    );

    final restored = UserModel.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.email, original.email);
    expect(restored.role, original.role);
  });
}
