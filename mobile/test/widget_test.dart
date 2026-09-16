import 'package:flutter_test/flutter_test.dart';
import 'package:osa_management/main.dart';
import 'package:osa_management/screens/auth/login_screen.dart';

void main() {
  testWidgets('app opens on login when there is no session', (tester) async {
    await tester.pumpWidget(const OSAApp(initialLoggedIn: false));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });
}
