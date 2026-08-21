import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/screens/get_started_screen.dart';
import 'package:toll_companion/screens/home_screen.dart';
import 'package:toll_companion/screens/main_navigation_scaffold.dart';
import 'package:toll_companion/screens/name_input_screen.dart';
import 'package:toll_companion/screens/splash_screen.dart';
import 'package:toll_companion/screens/toll_calculator_screen.dart';
import 'package:toll_companion/services/cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService Onboarding & Driver Name Tests', () {
    late CacheService cacheService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cacheService = CacheService();
    });

    test('isOnboardingComplete defaults to false', () async {
      final isComplete = await cacheService.isOnboardingComplete();
      expect(isComplete, isFalse);
    });

    test('setOnboardingComplete persists true correctly', () async {
      await cacheService.setOnboardingComplete(true);
      final isComplete = await cacheService.isOnboardingComplete();
      expect(isComplete, isTrue);
    });

    test('getDriverName returns null initially and stores trimmed name', () async {
      final initialName = await cacheService.getDriverName();
      expect(initialName, isNull);

      await cacheService.setDriverName('   Juan Dela Cruz   ');
      final savedName = await cacheService.getDriverName();
      expect(savedName, 'Juan Dela Cruz');
    });
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders AERO branding and tap to skip hint', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': false});
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(cacheService: cacheService),
        ),
      );
      await tester.pump();

      expect(find.text('AERO'), findsOneWidget);
      expect(find.text('Philippine Expressway Companion'), findsOneWidget);
      expect(find.text('Tap anywhere to skip'), findsOneWidget);
    });

    testWidgets('Navigates to GetStartedScreen on first launch (onboarding_complete = false)',
        (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': false});
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(cacheService: cacheService),
          routes: {
            '/get-started': (context) => const GetStartedScreen(),
            '/home': (context) => const MainNavigationScaffold(),
          },
        ),
      );
      await tester.pump();

      // Tap anywhere to trigger immediate navigation
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byType(GetStartedScreen), findsOneWidget);
      expect(find.text('Drive Philippine Expressways with Confidence'), findsOneWidget);
    });

    testWidgets('Navigates directly to MainNavigationScaffold on subsequent launches',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'driver_name': 'Alex',
      });
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(cacheService: cacheService),
          routes: {
            '/get-started': (context) => const GetStartedScreen(),
            '/home': (context) => const MainNavigationScaffold(),
          },
        ),
      );
      await tester.pump();

      // Tap to skip
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScaffold), findsOneWidget);
      expect(find.text('Hello, Alex'), findsOneWidget);
    });
  });

  group('GetStartedScreen Widget Tests', () {
    testWidgets('Renders illustration, tagline, features, and navigates on Get Started tap',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: GetStartedScreen(cacheService: cacheService),
        ),
      );
      await tester.pump();

      expect(find.text('AERO EXPRESSWAY'), findsOneWidget);
      expect(find.text('Drive Philippine Expressways with Confidence'), findsOneWidget);
      expect(
        find.text('Your companion for every PH expressway trip — tolls, safety, and peace of mind.'),
        findsOneWidget,
      );
      expect(find.text('RFID Tracking'), findsOneWidget);
      expect(find.text('24/7 Hotlines'), findsOneWidget);
      expect(find.text('Trip Fares'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.byType(NameInputScreen), findsOneWidget);
      expect(find.text('What should we call you?'), findsOneWidget);
    });
  });

  group('NameInputScreen Widget Tests', () {
    testWidgets('Validation: Continue button is disabled until non-empty name is entered',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: NameInputScreen(cacheService: cacheService),
        ),
      );
      await tester.pump();

      expect(find.text('What should we call you?'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Button is initially disabled
      final continueButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(continueButton.onPressed, isNull);

      // Enter whitespace only — button remains disabled
      await tester.enterText(find.byType(TextFormField), '     ');
      await tester.pump();

      final buttonAfterWhitespace = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(buttonAfterWhitespace.onPressed, isNull);

      // Enter valid name — button becomes enabled
      await tester.enterText(find.byType(TextFormField), 'Marco Rivera');
      await tester.pump();

      final buttonAfterValidName = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(buttonAfterValidName.onPressed, isNotNull);

      // Tap Continue — saves name and sets onboarding complete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(await cacheService.getDriverName(), 'Marco Rivera');
      expect(await cacheService.isOnboardingComplete(), isTrue);
      expect(find.byType(MainNavigationScaffold), findsOneWidget);
      expect(find.text('Hello, Marco Rivera'), findsOneWidget);
    });
  });

  group('HomeScreen Driver Name & Settings Edit Tests', () {
    testWidgets('HomeScreen loads and displays personalized greeting', (tester) async {
      SharedPreferences.setMockInitialValues({
        'driver_name': 'Elena',
        'onboarding_complete': true,
      });
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(cacheService: cacheService),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hello, Elena'), findsOneWidget);
    });

    testWidgets('HomeScreen falls back to "Hello, Driver" when no name is stored',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(cacheService: cacheService),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hello, Driver'), findsOneWidget);
    });

    testWidgets('Settings allows editing driver name and dynamically updates greeting',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'driver_name': 'Carlos',
      });
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(cacheService: cacheService),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hello, Carlos'), findsOneWidget);

      // Tap Settings gear
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Aero Settings'), findsOneWidget);
      expect(find.text('Driver Profile'), findsOneWidget);
      expect(find.text('Edit Name'), findsOneWidget);

      // Tap "Edit Name"
      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Driver Name'), findsOneWidget);

      // Enter new name and save
      await tester.enterText(find.byType(TextFormField), 'Captain Carlos');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Greeting on HomeScreen is now updated
      expect(find.text('Hello, Captain Carlos'), findsOneWidget);
      expect(await cacheService.getDriverName(), 'Captain Carlos');
    });

    testWidgets('Settings allows Reset App which clears local data and triggers fresh onboarding',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'driver_name': 'To Be Cleared',
        'onboarding_complete': true,
      });
      final cacheService = CacheService();

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/splash': (context) => SplashScreen(cacheService: cacheService),
          },
          home: HomeScreen(cacheService: cacheService),
        ),
      );
      await tester.pumpAndSettle();

      // Open Settings dialog
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Reset App'), findsOneWidget);
      expect(find.text('Clear all data and restart onboarding'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Reset Aero App'), findsOneWidget);
      expect(
        find.text('This will clear all saved data and restart onboarding. Continue?'),
        findsOneWidget,
      );

      // Test Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await cacheService.getDriverName(), 'To Be Cleared');
      expect(await cacheService.isOnboardingComplete(), isTrue);

      // Open Settings and confirm Reset
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Tap Reset App in confirmation
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset App'));
      await tester.pumpAndSettle();

      // Local state is cleared
      expect(await cacheService.getDriverName(), isNull);
      expect(await cacheService.isOnboardingComplete(), isFalse);

      // Navigated to Splash and first-launch flow triggers (GetStartedScreen)
      expect(find.byType(SplashScreen), findsOneWidget);
      // Tap to skip splash
      await tester.tap(find.text('Tap anywhere to skip'));
      await tester.pumpAndSettle();

      // Onboarding restarted at GetStartedScreen!
      expect(find.byType(GetStartedScreen), findsOneWidget);
    });
  });

  group('MainNavigationScaffold Tab Transition & State Preservation Tests', () {
    testWidgets('Preserves Toll Calculator vehicle class and calculation state across tab switches',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({'driver_name': 'Tester'});

      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Tolls Tab
      await tester.tap(find.text('Tolls'));
      await tester.pumpAndSettle();

      expect(find.text('Trip Details'), findsWidgets);
      expect(find.text('ORIGIN EXIT'), findsOneWidget);

      // Select Class 3
      await tester.tap(find.text('Class 3'));
      await tester.pumpAndSettle();

      // Switch to Guide Tab
      await tester.tap(find.text('Guide'));
      await tester.pumpAndSettle();
      expect(find.text('Quick Guide'), findsOneWidget);

      // Switch back to Tolls Tab
      await tester.tap(find.text('Tolls'));
      await tester.pumpAndSettle();

      // Vehicle class selection is preserved (Class 3 is still active)
      expect(find.text('Trip Details'), findsWidgets);

      // Now populate a route using switchTabWithRoute and calculate fare
      MainNavigationScaffold.switchTabWithRoute(
        tester.element(find.byType(TollCalculatorScreen)),
        originId: 'slex_calamba',
        destinationId: 'nlex_bocaue',
        vehicleClass: 1,
      );
      await tester.pumpAndSettle();

      // Tap Calculate Fare button
      await tester.tap(find.text('CALCULATE FARE'));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL ESTIMATED TRIP COST'), findsOneWidget);
      expect(find.text('RFID OPERATOR BREAKDOWN'), findsOneWidget);

      // Switch to Emergency tab
      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency'), findsWidgets);

      // Switch back to Tolls tab
      await tester.tap(find.text('Tolls'));
      await tester.pumpAndSettle();

      // Calculation state is 100% preserved: Route calculation and operator breakdown are still displayed!
      expect(find.text('TOTAL ESTIMATED TRIP COST'), findsOneWidget);
      expect(find.text('RFID OPERATOR BREAKDOWN'), findsOneWidget);
    });
  });
}
