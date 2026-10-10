import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:osa_management/core/theme/app_theme.dart';
import 'package:osa_management/main.dart';
import 'package:osa_management/screens/auth/login_screen.dart';

void main() {
  test('OSA brand palette stays exact', () {
    expect(AppColors.blueGray, const Color(0xFF384660));
    expect(AppColors.navy, const Color(0xFF384660));
    expect(AppColors.magenta, const Color(0xFFB43A6C));
    expect(AppColors.yellow, const Color(0xFFFFC822));
    expect(AppColors.background, const Color(0xFF384660));
    expect(AppColors.surface, const Color(0xFFB43A6C));
    expect(AppColors.surfaceDeep, const Color(0xFF384660));
  });

  testWidgets('app opens on login when there is no session', (tester) async {
    await tester.pumpWidget(const OSAApp(initialLoggedIn: false));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });
}
