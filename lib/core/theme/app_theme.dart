import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFFC8102E);
  static const dark = Color(0xFF111111);
  static const background = Color(0xFFF7F7F8);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Arial',
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light).copyWith(primary: primary, surface: Colors.white),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: dark, elevation: 0, centerTitle: false, titleTextStyle: TextStyle(color: dark, fontSize: 20, fontWeight: FontWeight.w800)),
    cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18)), side: BorderSide(color: Color(0xFFEDEDED))),),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E5E5))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E5E5))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
    navigationBarTheme: const NavigationBarThemeData(indicatorColor: Color(0xFFFFE1E5), labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700))),
  );
}
