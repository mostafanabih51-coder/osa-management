import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
    ApiService.onUnauthorized = () {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    };

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Online School Academy',
      theme: AppTheme.light(),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF384660),
                    Color(0xFF49384F),
                    Color(0xFF303D55),
                    Color(0xFF263248),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -110,
              right: -95,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 46, sigmaY: 46),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB43A6C).withValues(alpha: 0.34),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -135,
              left: -105,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 54, sigmaY: 54),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFC822).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
            child ?? const SizedBox.shrink(),
          ],
        ),
      ),
      home: initialLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
