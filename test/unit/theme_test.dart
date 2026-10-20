import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_quizlet_mobile_app/core/theme/app_theme.dart';
import 'package:simple_quizlet_mobile_app/presentation/blocs/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme & Color Palette Verification', () {
    test('AppTheme accentColor is Spotify emerald green (no purple)', () {
      expect(AppTheme.accentColor, const Color(0xFF1ED760));
      // Verify hue is green (around 141 deg in HSV), strictly NOT purple (260-310 deg)
      final hsv = HSVColor.fromColor(AppTheme.accentColor);
      expect(hsv.hue, inInclusiveRange(130.0, 150.0));
    });

    test('Dark theme background colors follow dark mode standard', () {
      expect(AppTheme.bgColor, const Color(0xFF121212));
      expect(AppTheme.surfaceColor, const Color(0xFF181818));
      expect(AppTheme.surface2Color, const Color(0xFF1F1F1F));
      expect(AppTheme.textColor, const Color(0xFFFFFFFF));
      expect(AppTheme.text2Color, const Color(0xFFB3B3B3));
    });

    test('Light theme background colors are bright and readable', () {
      expect(AppTheme.lightBgColor, const Color(0xFFF8FAFC));
      expect(AppTheme.lightSurfaceColor, const Color(0xFFFFFFFF));
      expect(AppTheme.lightSurface2Color, const Color(0xFFF1F5F9));
      expect(AppTheme.lightTextColor, const Color(0xFF0F172A));
      expect(AppTheme.lightText2Color, const Color(0xFF475569));
    });

    testWidgets('AppTheme dynamic context getters adapt to theme brightness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: AppTheme.darkTheme,
            child: Builder(
              builder: (context) {
                expect(AppTheme.isDark(context), isTrue);
                expect(AppTheme.bg(context), AppTheme.bgColor);
                expect(AppTheme.surface(context), AppTheme.surfaceColor);
                expect(AppTheme.text(context), AppTheme.textColor);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: AppTheme.lightTheme,
            child: Builder(
              builder: (context) {
                expect(AppTheme.isDark(context), isFalse);
                expect(AppTheme.bg(context), AppTheme.lightBgColor);
                expect(AppTheme.surface(context), AppTheme.lightSurfaceColor);
                expect(AppTheme.text(context), AppTheme.lightTextColor);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('ThemeCubit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initial theme mode is dark by default', () {
      final cubit = ThemeCubit(prefs);
      expect(cubit.state, ThemeMode.dark);
    });

    test('setThemeMode updates state properly and persists to prefs', () async {
      final cubit = ThemeCubit(prefs);
      await cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state, ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');

      await cubit.setThemeMode(ThemeMode.system);
      expect(cubit.state, ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');

      await cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state, ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');
    });
  });
}
