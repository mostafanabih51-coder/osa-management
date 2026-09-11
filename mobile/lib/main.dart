import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await ApiService.restoreSession();
  runApp(OSAApp(initialLoggedIn: loggedIn));
}

class OSAApp extends StatelessWidget {
  final bool initialLoggedIn;

  const OSAApp({super.key, this.initialLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OSA Management',
      theme: AppTheme.light(),
      home: initialLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
