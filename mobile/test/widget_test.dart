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
    expect(AppColors.surface, const Color(0xFF2D3850));
    expect(AppColors.surfaceDeep, const Color(0xFF222C43));
    expect(AppColors.surfaceRaised, const Color(0xFF35415A));
    expect(AppTheme.light().cardTheme.color, AppColors.surface);
    expect(AppTheme.light().cardTheme.surfaceTintColor, Colors.transparent);
    expect(AppTheme.light().iconTheme.color, AppColors.yellow);
    expect(AppTheme.light().floatingActionButtonTheme.backgroundColor, AppColors.magenta);
    expect(AppTheme.light().filledButtonTheme.style?.backgroundColor?.resolve({}), AppColors.magenta);
    expect(AppTheme.light().filledButtonTheme.style?.iconColor?.resolve({}), AppColors.yellow);
    expect(AppTheme.light().elevatedButtonTheme.style?.iconColor?.resolve({}), AppColors.yellow);
    expect(AppTheme.light().textButtonTheme.style?.iconColor?.resolve({}), AppColors.yellow);
    expect(AppTheme.light().outlinedButtonTheme.style?.iconColor?.resolve({}), AppColors.yellow);
    expect(const GlassSurface(child: SizedBox()).tint, AppColors.surface);
    expect(const GlassSurface(child: SizedBox()).borderColor, AppColors.border);
  });

  testWidgets('app opens on login when there is no session', (tester) async {
    await tester.pumpWidget(const OSAApp(initialLoggedIn: false));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });
}
