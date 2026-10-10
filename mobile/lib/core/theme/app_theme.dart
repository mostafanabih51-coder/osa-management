import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Official Online School Academy palette.
class AppColors {
  static const blueGray = Color(0xFF384660);
  @Deprecated('Use blueGray; this alias is retained for compatibility.')
  static const navy = blueGray;
  static const magenta = Color(0xFFB43A6C);
  static const yellow = Color(0xFFFFC822);
  static const background = blueGray;
  static const surface = magenta;
  static const surfaceDeep = blueGray;
  static const text = Color(0xFFF1F3F8);
  static const muted = Color(0xFFD6DCE7);
  static const border = Color(0x667D8AA0);
  static const glassWhite = Color(0x1FFFFFFF);

  // Compatibility aliases used by existing screens. Avoid the former pink.
  static const red = magenta;
  static const pink = magenta;
  static const black = navy;
  static const white = Colors.white;
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.magenta,
      onPrimary: Colors.white,
      secondary: AppColors.magenta,
      onSecondary: Colors.white,
      tertiary: AppColors.surface,
      onTertiary: Colors.white,
      error: AppColors.magenta,
      onError: AppColors.blueGray,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.yellow),
      canvasColor: Colors.transparent,
      dividerColor: AppColors.border,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppColors.text,
            displayColor: AppColors.text,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.blueGray,
        foregroundColor: AppColors.yellow,
        iconTheme: const IconThemeData(color: AppColors.yellow),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.magenta.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.text.withValues(alpha: 0.18), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDeep.withValues(alpha: 0.82),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.magenta, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.magenta),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.magenta,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.magenta,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.magenta,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.magenta,
        foregroundColor: AppColors.yellow,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: AppColors.text),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceDeep,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDeep,
        selectedColor: AppColors.magenta,
        secondarySelectedColor: AppColors.magenta,
        disabledColor: AppColors.surfaceDeep,
        labelStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.muted,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: AppColors.yellow,
        collapsedIconColor: AppColors.muted,
        textColor: AppColors.text,
        collapsedTextColor: AppColors.text,
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.magenta,
          side: const BorderSide(color: AppColors.magenta),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDeep,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDeep,
        indicatorColor: AppColors.magenta.withValues(alpha: 0.65),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.text),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.magenta,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.magenta : AppColors.surface),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.magenta : AppColors.muted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.magenta : AppColors.surfaceDeep),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.yellow,
        textColor: AppColors.text,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700),
        contentTextStyle: const TextStyle(color: AppColors.muted),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceDeep),
        headingTextStyle: const TextStyle(
          color: AppColors.yellow,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: const TextStyle(color: AppColors.text, fontSize: 14),
        dividerThickness: 0.7,
        horizontalMargin: 18,
        columnSpacing: 22,
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.yellow,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.yellow,
        unselectedLabelColor: AppColors.muted,
        labelStyle: TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.magenta,
        headerForegroundColor: Colors.white,
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.yellow),
        todayBorder: const BorderSide(color: AppColors.yellow),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        yearForegroundColor: const WidgetStatePropertyAll(AppColors.text),
        weekdayStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        dialBackgroundColor: AppColors.surfaceDeep,
        dialHandColor: AppColors.magenta,
        hourMinuteColor: AppColors.surfaceDeep,
        hourMinuteTextColor: AppColors.text,
        dayPeriodColor: AppColors.magenta,
        dayPeriodTextColor: Colors.white,
        entryModeIconColor: AppColors.yellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(color: AppColors.text, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.yellow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.yellow,
        selectionColor: Color(0x66B43A6C),
        selectionHandleColor: AppColors.magenta,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceDeep,
        textStyle: TextStyle(color: AppColors.text),
      ),
    );
  }
}

/// Premium glassmorphism surface using the academy palette with glossy edge highlights.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color tint;
  final Color borderColor;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 16,
    this.tint = AppColors.magenta,
    this.borderColor = const Color(0x35F1F3F8),
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: shape,
            border: Border.all(color: borderColor, width: 1),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x28FFFFFF),
                Color(0x10FFFFFF),
                Color(0x06384660),
                Color(0x0DB43A6C),
                Color(0x06384660),
              ],
              stops: [0.0, 0.18, 0.48, 0.76, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.magenta.withValues(alpha: 0.09),
                blurRadius: 18,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.text.withValues(alpha: 0.72),
                        AppColors.text.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smooth, restrained press animation for interactive surfaces.
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const AnimatedPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: widget.child,
        ),
      ),
    );
  }
}
