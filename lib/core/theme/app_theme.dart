import 'package:flutter/material.dart';

class AppTheme {
  // ── Color Palette ──────────────────────────────────────────────
  static const Color bgColor = Color(0xFFFAFAF9);       // stone-50
  static const Color surfaceColor = Color(0xFFFFFFFF);   // white
  static const Color surface2Color = Color(0xFFF5F5F4);  // stone-100
  static const Color borderColor = Color(0xFFE7E5E4);    // stone-200 border
  static const Color accentColor = Color(0xFFD97706);    // amber-600
  static const Color accent2Color = Color(0xFFB45309);   // amber-700
  static const Color textColor = Color(0xFF1C1917);      // stone-900
  static const Color text2Color = Color(0xFF57534E);     // stone-600
  static const Color text3Color = Color(0xFFA8A29E);     // stone-400
  static const Color successColor = Color(0xFF16A34A);   // green-600
  static const Color errorColor = Color(0xFFDC2626);     // red-600
  static const Color infoColor = Color(0xFF2563EB);      // blue-600

  // ── Spacing ────────────────────────────────────────────────────
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;

  // ── Text Styles ────────────────────────────────────────────────
  static TextStyle get displayLg => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMd => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      );

  static TextStyle get titleLg => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  static TextStyle get titleMd => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      );

  static TextStyle get bodyLg => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textColor,
      );

  static TextStyle get bodyMd => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: text2Color,
      );

  static TextStyle get bodySm => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: text3Color,
      );

  static TextStyle get labelMd => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: text2Color,
        letterSpacing: 0.5,
      );

  // ── Theme Data ──────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: IconThemeData(color: text2Color),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: text2Color, fontSize: 14),
        hintStyle: const TextStyle(color: text3Color, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface2Color,
        contentTextStyle: const TextStyle(color: textColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: text3Color,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
