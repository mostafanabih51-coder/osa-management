import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/courses/courses_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/subscriptions/subscriptions_screen.dart';
import 'screens/reports/reports_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OsaManagementApp());
}

class OsaManagementApp extends StatelessWidget {
  const OsaManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => TokenStorage()),
        Provider(create: (_) => ApiClient()),
        ChangeNotifierProxyProvider2<ApiClient, TokenStorage, AuthProvider>(
          create: (context) => AuthProvider(
            api: context.read<ApiClient>(),
            storage: context.read<TokenStorage>(),
          ),
          update: (_, api, storage, previous) =>
              previous ?? AuthProvider(api: api, storage: storage),
        ),
      ],
      child: MaterialApp(
        title: 'OSA Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const AppGate(),
      ),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AuthProvider>().restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.initial || auth.status == AuthStatus.loading) {
          return const SplashScreen();
        }
        if (auth.isAuthenticated) return const DashboardScreen();
        return const LoginScreen();
      },
    );
  }
}
