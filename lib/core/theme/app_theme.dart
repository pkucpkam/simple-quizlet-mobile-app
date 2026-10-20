import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/theme/theme_cubit.dart';

class AppTheme {
  // ── Dark OLED Palette ──────────────────────────────────────────────
  static const Color bgColor = Color(0xFF121212); // Deepest background
  static const Color surfaceColor = Color(0xFF181818); // Cards, containers
  static const Color surface2Color = Color(0xFF1F1F1F); // Interactive surfaces, inputs
  static const Color surface3Color = Color(0xFF262626); // Elevated cards
  static const Color surface4Color = Color(0xFF2E2E2E); // Hover/pressed state

  static const Color accentColor = Color(0xFF1ED760); // Spotify Green
  static const Color accentDark = Color(0xFF1DB954); // Pressed state, borders

  static const Color textColor = Color(0xFFFFFFFF); // Primary — pure white
  static const Color text2Color = Color(0xFFB3B3B3); // Secondary — silver
  static const Color text3Color = Color(0xFF71717A); // Muted
  static const Color text4Color = Color(0xFF404040); // Disabled/placeholder

  static const Color borderColor = Color(0xFF333333); // Standard border
  static const Color borderLight = Color(0xFF4B5563); // Outlined elements

  // ── Light Clean Slate & Emerald Palette ────────────────────────────
  static const Color lightBgColor = Color(0xFFF8FAFC); // Clean slate white
  static const Color lightSurfaceColor = Color(0xFFFFFFFF); // Pure crisp white
  static const Color lightSurface2Color = Color(0xFFF1F5F9); // Light slate container
  static const Color lightSurface3Color = Color(0xFFE2E8F0); // Subtle elevated surface
  static const Color lightSurface4Color = Color(0xFFCBD5E1); // Hover/pressed

  static const Color lightAccentColor = Color(0xFF16A34A); // High-contrast Emerald Green
  static const Color lightAccentDark = Color(0xFF15803D); // Pressed state

  static const Color lightTextColor = Color(0xFF0F172A); // Deep slate charcoal
  static const Color lightText2Color = Color(0xFF475569); // Secondary slate
  static const Color lightText3Color = Color(0xFF94A3B8); // Muted slate
  static const Color lightText4Color = Color(0xFFCBD5E1); // Placeholder

  static const Color lightBorderColor = Color(0xFFE2E8F0); // Delicate light border
  static const Color lightBorderLight = Color(0xFFCBD5E1); // Medium border

  // ── Semantic Colors (Consistent across themes) ─────────────────────
  static const Color successColor = Color(0xFF1ED760); // Green
  static const Color lightSuccessColor = Color(0xFF16A34A);
  static const Color errorColor = Color(0xFFF43F5E); // Crisp red (anti-purple)
  static const Color warningColor = Color(0xFFF59E0B); // Amber warning
  static const Color infoColor = Color(0xFF0EA5E9); // Sky / Electric blue

  // ── Border Radius ─────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusButton = 10.0; // Standardized sleek subtle button radius
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 9999.0; // Full pill for badges
  static const double radiusLargePill = 500.0;

  // ── Shadows ───────────────────────────────────────────────────────
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowHeavy => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowGreen => [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Context-aware dynamic helpers ─────────────────────────────────
  static bool isDark(BuildContext context) {
    try {
      final themeCubit = BlocProvider.of<ThemeCubit>(context, listen: false);
      if (themeCubit.state == ThemeMode.light) return false;
      if (themeCubit.state == ThemeMode.dark) return true;
    } catch (_) {}
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color bg(BuildContext context) =>
      isDark(context) ? bgColor : lightBgColor;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceColor : lightSurfaceColor;

  static Color surface2(BuildContext context) =>
      isDark(context) ? surface2Color : lightSurface2Color;

  static Color surface3(BuildContext context) =>
      isDark(context) ? surface3Color : lightSurface3Color;

  static Color text(BuildContext context) =>
      isDark(context) ? textColor : lightTextColor;

  static Color text2(BuildContext context) =>
      isDark(context) ? text2Color : lightText2Color;

  static Color text3(BuildContext context) =>
      isDark(context) ? text3Color : lightText3Color;

  static Color border(BuildContext context) =>
      isDark(context) ? borderColor : lightBorderColor;

  static Color accent(BuildContext context) =>
      isDark(context) ? accentColor : lightAccentColor;

  static List<BoxShadow> shadow(BuildContext context) =>
      isDark(context) ? shadowMedium : shadowLight;

  // ── Typography ────────────────────────────────────────────────────
  static ThemeTextStyle get displayLg => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.6,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get displayMd => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.4,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get titleLg => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.2,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get titleMd => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get titleSm => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get bodyLg => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get bodyMd => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: text2Color,
      ), (ctx) => text2(ctx));

  static ThemeTextStyle get bodySm => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: text3Color,
      ), (ctx) => text3(ctx));

  static ThemeTextStyle get labelLg => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 1.2,
      ), (ctx) => text(ctx));

  static ThemeTextStyle get labelMd => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: text2Color,
        letterSpacing: 1.0,
      ), (ctx) => text2(ctx));

  static ThemeTextStyle get labelSm => ThemeTextStyle.from(GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.8,
      ), (ctx) => text(ctx));

  // Context-aware typography helpers
  static TextStyle displayLgOf(BuildContext context) => displayLg(context);
  static TextStyle displayMdOf(BuildContext context) => displayMd(context);
  static TextStyle titleLgOf(BuildContext context) => titleLg(context);
  static TextStyle titleMdOf(BuildContext context) => titleMd(context);
  static TextStyle titleSmOf(BuildContext context) => titleSm(context);
  static TextStyle bodyLgOf(BuildContext context) => bodyLg(context);
  static TextStyle bodyMdOf(BuildContext context) => bodyMd(context);
  static TextStyle bodySmOf(BuildContext context) => bodySm(context);
  static TextStyle labelLgOf(BuildContext context) => labelLg(context);
  static TextStyle labelMdOf(BuildContext context) => labelMd(context);
  static TextStyle labelSmOf(BuildContext context) => labelSm(context);

  // ── Dark Theme Data ───────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: text2Color),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2Color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: accentColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        labelStyle: GoogleFonts.inter(color: text2Color, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: text3Color, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: errorColor, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 50),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: borderLight, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface3Color,
        contentTextStyle: GoogleFonts.inter(color: textColor, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: text3Color,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: surface3Color,
      ),
      iconTheme: const IconThemeData(color: text2Color, size: 22),
    );
  }

  // ── Light Theme Data ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBgColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.light(
        primary: lightAccentColor,
        secondary: lightAccentColor,
        surface: lightSurfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBgColor,
        foregroundColor: lightTextColor,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: lightTextColor,
        ),
        iconTheme: const IconThemeData(color: lightText2Color),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lightBorderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface2Color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: lightBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: lightBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: lightAccentColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLargePill),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        labelStyle: GoogleFonts.inter(color: lightText2Color, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: lightText3Color, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: errorColor, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 50),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextColor,
          side: const BorderSide(color: lightBorderLight, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightAccentColor,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightBorderColor, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextColor,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurfaceColor,
        selectedItemColor: lightAccentColor,
        unselectedItemColor: lightText3Color,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightAccentColor,
        linearTrackColor: lightSurface3Color,
      ),
      iconTheme: const IconThemeData(color: lightText2Color, size: 22),
    );
  }

  // ── Helper BoxDecorations ─────────────────────────────────────────
  static BoxDecoration pillDecoration({
    BuildContext? context,
    Color? background,
    Color? border,
    List<BoxShadow>? shadows,
  }) {
    final isDarkMode = context != null ? isDark(context) : true;
    final defaultBg = isDarkMode ? surface2Color : lightSurface2Color;
    return BoxDecoration(
      color: background ?? defaultBg,
      borderRadius: BorderRadius.circular(radiusPill),
      border: (!isDarkMode && border != null)
          ? Border.all(color: border, width: 1)
          : null,
      boxShadow: shadows,
    );
  }

  static BoxDecoration cardDecoration({
    BuildContext? context,
    Color? background,
    bool hasShadow = false,
    bool hasBorder = false,
    double? radius,
  }) {
    final isDarkMode = context != null ? isDark(context) : true;
    final bgCol = background ?? (isDarkMode ? surfaceColor : lightSurfaceColor);
    final borderCol = isDarkMode ? borderColor : lightBorderColor;
    return BoxDecoration(
      color: bgCol,
      borderRadius: BorderRadius.circular(radius ?? radiusMd),
      border: (!isDarkMode && hasBorder)
          ? Border.all(color: borderCol, width: 0.8)
          : null,
      boxShadow: hasShadow
          ? (isDarkMode ? shadowMedium : shadowLight)
          : null,
    );
  }
}

/// A [TextStyle] subclass that can be used directly as a [TextStyle]
/// or invoked as a callable `(context)` to resolve colors dynamically.
class ThemeTextStyle extends TextStyle {
  final Color Function(BuildContext context)? _resolver;

  ThemeTextStyle.from(TextStyle s, [this._resolver])
      : super(
          inherit: s.inherit,
          color: s.color,
          backgroundColor: s.backgroundColor,
          fontSize: s.fontSize,
          fontWeight: s.fontWeight,
          fontStyle: s.fontStyle,
          letterSpacing: s.letterSpacing,
          wordSpacing: s.wordSpacing,
          textBaseline: s.textBaseline,
          height: s.height,
          leadingDistribution: s.leadingDistribution,
          locale: s.locale,
          foreground: s.foreground,
          background: s.background,
          shadows: s.shadows,
          fontFeatures: s.fontFeatures,
          fontVariations: s.fontVariations,
          decoration: s.decoration,
          decorationColor: s.decorationColor,
          decorationStyle: s.decorationStyle,
          decorationThickness: s.decorationThickness,
          debugLabel: s.debugLabel,
          fontFamily: s.fontFamily,
          fontFamilyFallback: s.fontFamilyFallback,
          overflow: s.overflow,
        );

  TextStyle call([BuildContext? context]) {
    if (context == null) return this;
    if (_resolver != null) {
      return copyWith(color: _resolver(context));
    }
    return copyWith(color: AppTheme.text(context));
  }
}
