import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/models/recent_trip.dart';
import 'package:toll_companion/screens/main_navigation_scaffold.dart';
import 'package:toll_companion/screens/toll_calculator_screen.dart';
import 'package:toll_companion/services/cache_service.dart';
import 'package:toll_companion/services/toll_service.dart';
import 'package:toll_companion/theme.dart';
import 'package:toll_companion/widgets/aero_mascot.dart';

Future<void> saveRepaintBoundaryScreenshot(WidgetTester tester, Finder finder, String path) async {
  await tester.runAsync(() async {
    final element = tester.element(finder);
    final renderObject = element.renderObject;
    RenderRepaintBoundary boundary;
    if (renderObject is RenderRepaintBoundary) {
      boundary = renderObject;
    } else {
      boundary = element.findAncestorRenderObjectOfType<RenderRepaintBoundary>()!;
    }
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final file = File(path);
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Capture Real App Screenshots for README', () {
    testWidgets('Capture 6 essential real Aero screenshots', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cacheService = CacheService();
      await cacheService.setDriverName('Juan');
      await cacheService.saveRfidBalances(autosweep: 1250.0, easytrip: 840.50);
      await cacheService.saveRecentTrips([
        RecentTrip(
          id: 'sample_trip_1',
          originId: 'slex_calamba',
          originName: 'Calamba Exit',
          destinationId: 'nlex_balintawak',
          destinationName: 'Balintawak Barrier',
          vehicleClass: 1,
          totalFare: 689.0,
          corridors: ['SLEX', 'SKYWAY', 'NLEX'],
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isFavorite: true,
          useSkyway: true,
        ),
        RecentTrip(
          id: 'sample_trip_2',
          originId: 'nlex_balintawak',
          originName: 'Balintawak Barrier',
          destinationId: 'sctex_clark_south',
          destinationName: 'Clark South Exit',
          vehicleClass: 1,
          totalFare: 338.0,
          corridors: ['NLEX', 'SCTEX'],
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isFavorite: false,
          useSkyway: true,
        ),
      ]);

      // -----------------------------------------------------------------------
      // 1. Home Dashboard (assets/screenshots/home.png)
      // -----------------------------------------------------------------------
      AeroColors.setThemeMode(ThemeMode.dark);
      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          darkTheme: AeroTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const RepaintBoundary(
            child: MainNavigationScaffold(
              initialIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await saveRepaintBoundaryScreenshot(tester, find.byType(RepaintBoundary).first, 'assets/screenshots/home.png');

      // -----------------------------------------------------------------------
      // 2. Recent Routes (assets/screenshots/recent-routes.png)
      // -----------------------------------------------------------------------
      // Scroll down on Home to showcase recent routes
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -350));
      await tester.pumpAndSettle();
      await saveRepaintBoundaryScreenshot(tester, find.byType(RepaintBoundary).first, 'assets/screenshots/recent-routes.png');

      // -----------------------------------------------------------------------
      // 3. Toll Calculator (assets/screenshots/toll-calculator.png)
      // -----------------------------------------------------------------------
      final tollService = TollService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          darkTheme: AeroTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: RepaintBoundary(
            child: TollCalculatorScreen(
              tollService: tollService,
              cacheService: cacheService,
              initialOriginPlazaId: 'slex_calamba',
              initialDestinationPlazaId: 'nlex_balintawak',
              initialVehicleClass: 1,
              initialUseSkyway: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Calculate Fare button
      await tester.tap(find.text('CALCULATE FARE'));
      await tester.pumpAndSettle();

      await saveRepaintBoundaryScreenshot(tester, find.byType(RepaintBoundary).first, 'assets/screenshots/toll-calculator.png');

      // -----------------------------------------------------------------------
      // 4. Dark Mode (assets/screenshots/dark-mode.png)
      // -----------------------------------------------------------------------
      await saveRepaintBoundaryScreenshot(tester, find.byType(RepaintBoundary).first, 'assets/screenshots/dark-mode.png');

      // -----------------------------------------------------------------------
      // 5. Light Mode (assets/screenshots/light-mode.png)
      // -----------------------------------------------------------------------
      AeroColors.setThemeMode(ThemeMode.light);
      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          darkTheme: AeroTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: RepaintBoundary(
            child: TollCalculatorScreen(
              tollService: tollService,
              cacheService: cacheService,
              initialOriginPlazaId: 'slex_calamba',
              initialDestinationPlazaId: 'nlex_balintawak',
              initialVehicleClass: 1,
              initialUseSkyway: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Calculate Fare button in light mode
      await tester.tap(find.text('CALCULATE FARE'));
      await tester.pumpAndSettle();

      await saveRepaintBoundaryScreenshot(tester, find.byType(RepaintBoundary).first, 'assets/screenshots/light-mode.png');

      // -----------------------------------------------------------------------
      // 6. Settings Modal (assets/screenshots/settings.png)
      // -----------------------------------------------------------------------
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      await saveRepaintBoundaryScreenshot(tester, find.byType(Dialog), 'assets/screenshots/settings.png');

      // Cleanup
      AeroColors.setThemeMode(ThemeMode.dark);
    });
  });
}
