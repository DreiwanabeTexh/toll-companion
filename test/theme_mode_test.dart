import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/screens/guide_detail_screen.dart';
import 'package:toll_companion/services/cache_service.dart';
import 'package:toll_companion/theme.dart';
import 'package:toll_companion/widgets/aero_mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Light Mode / Theme Management Tests', () {
    test('AeroColors toggle changes dynamic theme colors and broadcasts to themeModeNotifier', () {
      // Default / initial state is Dark
      AeroColors.setThemeMode(ThemeMode.dark);
      expect(AeroColors.isLight, isFalse);
      expect(AeroColors.themeModeNotifier.value, ThemeMode.dark);
      expect(AeroColors.surfaceBase, const Color(0xFF0A0A0A));
      expect(AeroColors.surfaceCard, const Color(0xFF1A1A1A));

      // Switch to Light Mode
      AeroColors.setThemeMode(ThemeMode.light);
      expect(AeroColors.isLight, isTrue);
      expect(AeroColors.themeModeNotifier.value, ThemeMode.light);
      expect(AeroColors.surfaceBase, const Color(0xFFF6F8FA));
      expect(AeroColors.surfaceCard, const Color(0xFFFFFFFF));
      expect(AeroColors.textPrimary, const Color(0xFF0F172A));

      // Switch back to Dark Mode
      AeroColors.setThemeMode(ThemeMode.dark);
      expect(AeroColors.isLight, isFalse);
      expect(AeroColors.themeModeNotifier.value, ThemeMode.dark);
      expect(AeroColors.surfaceBase, const Color(0xFF0A0A0A));
    });

    test('CacheService saves and retrieves ThemeMode preference', () async {
      final cacheService = CacheService();

      // Verify default when none saved is dark
      expect(await cacheService.getThemeMode(), 'dark');

      // Save light mode
      await cacheService.saveThemeMode('light');
      expect(await cacheService.getThemeMode(), 'light');

      // Save dark mode
      await cacheService.saveThemeMode('dark');
      expect(await cacheService.getThemeMode(), 'dark');
    });

    testWidgets('Settings Dialog renders App Theme toggle and triggers mode change', (tester) async {
      AeroColors.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          darkTheme: AeroTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AeroHomeAppBar.showSettingsDialog(context),
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to open Settings
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Verify Theme Card is displayed in dialog
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('Dark Mode (Nocturnal Command)'), findsOneWidget);

      // Find and toggle the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify switch toggled to Light mode
      expect(AeroColors.isLight, isTrue);
      expect(find.text('Light Mode (Solar Lumina)'), findsOneWidget);

      // Cleanup
      AeroColors.setThemeMode(ThemeMode.dark);
    });

    testWidgets('GuideDetailScreen renders with crisp text colors in light mode', (tester) async {
      AeroColors.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          home: GuideDetailScreen(
            entry: null,
          ),
        ),
      );

      expect(find.text('Guide Details'), findsOneWidget);
      expect(find.text('No Guide Selected'), findsOneWidget);

      // Cleanup
      AeroColors.setThemeMode(ThemeMode.dark);
    });
  });
}
