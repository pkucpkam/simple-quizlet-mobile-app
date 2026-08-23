import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Spotify Color Palette ──────────────────────────────────────────
  // Backgrounds (near-black darkness — UI recedes, content glows)
  static const Color bgColor = Color(0xFF121212);       // Deepest background
  static const Color surfaceColor = Color(0xFF181818);   // Cards, containers
  static const Color surface2Color = Color(0xFF1F1F1F);  // Interactive surfaces, inputs
  static const Color surface3Color = Color(0xFF252525);  // Elevated cards
  static const Color surface4Color = Color(0xFF2A2A2A);  // Hover/pressed state

  // Accent — Spotify Green (functional only, never decorative)
  static const Color accentColor = Color(0xFF1ED760);    // Primary CTA, active states
  static const Color accentDark = Color(0xFF1DB954);     // Pressed state, borders

  // Text
  static const Color textColor = Color(0xFFFFFFFF);      // Primary — pure white
  static const Color text2Color = Color(0xFFB3B3B3);     // Secondary — silver
  static const Color text3Color = Color(0xFF6A6A6A);     // Muted
  static const Color text4Color = Color(0xFF404040);     // Disabled/placeholder

  // Borders
  static const Color borderColor = Color(0xFF4D4D4D);    // Standard border
  static const Color borderLight = Color(0xFF7C7C7C);    // Outlined elements

  // Semantic
  static const Color successColor = Color(0xFF1ED760);   // Green (same as accent)
  static const Color errorColor = Color(0xFFF3727F);     // Spotify negative red
  static const Color warningColor = Color(0xFFFFA42B);   // Warning orange
  static const Color infoColor = Color(0xFF539DF5);      // Announcement blue

  // ── Border Radius ─────────────────────────────────────────────────
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 20.0;
  static const double radiusPill = 9999.0;   // Full pill for buttons
  static const double radiusLargePill = 500.0; // Large pill for primary CTAs

  // ── Shadows ───────────────────────────────────────────────────────
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowHeavy => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowGreen => [
    BoxShadow(
      color: accentColor.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Text Styles (Inter ≈ CircularSp/SpotifyMixUI) ────────────────
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMd => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.3,
      );

  static TextStyle get titleLg => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  static TextStyle get titleMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  static TextStyle get titleSm => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: text2Color,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: text3Color,
      );

  // Spotify button label: UPPERCASE + wide letter-spacing
  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.4,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: text2Color,
        letterSpacing: 1.2,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.8,
      );

  // ── Theme Data ────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,

      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.black,     // Black text on Spotify Green (high contrast)
        onSecondary: Colors.black,
        onSurface: textColor,
        onError: Colors.white,
      ),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: text2Color),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs (pill style like Spotify) ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: borderColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: text2Color, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: text3Color, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: errorColor, fontSize: 12),
      ),

      // ── Elevated Button (Spotify Green pill — primary CTA) ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: const StadiumBorder(),   // Full pill
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),

      // ── Outlined Button (pill, outlined variant) ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: borderLight, width: 1),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(color: borderColor, space: 1),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface3Color,
        contentTextStyle: GoogleFonts.inter(color: textColor, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: text3Color,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // ── Progress Indicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: surface3Color,
      ),

      // ── Icon ──
      iconTheme: const IconThemeData(color: text2Color, size: 22),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: surface2Color,
        labelStyle: GoogleFonts.inter(color: textColor, fontSize: 12),
        side: const BorderSide(color: borderColor),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  // ── Convenience: dark pill chip / badge ──────────────────────────
  static BoxDecoration pillDecoration({
    Color? background,
    Color? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: background ?? surface2Color,
      borderRadius: BorderRadius.circular(radiusPill),
      border: border != null ? Border.all(color: border, width: 1) : null,
      boxShadow: shadows,
    );
  }

  static BoxDecoration cardDecoration({
    Color? background,
    bool hasShadow = false,
    bool hasBorder = false,
  }) {
    return BoxDecoration(
      color: background ?? surfaceColor,
      borderRadius: BorderRadius.circular(radiusMd),
      border: hasBorder ? Border.all(color: borderColor, width: 0.8) : null,
      boxShadow: hasShadow ? shadowMedium : null,
    );
  }
}
