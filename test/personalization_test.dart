import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/models/recent_trip.dart';
import 'package:toll_companion/services/cache_service.dart';
import 'package:toll_companion/screens/home_screen.dart';
import 'package:toll_companion/screens/toll_calculator_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentTrip Model Tests', () {
    test('toJson and fromJson preserves all fields', () {
      final now = DateTime.now();
      final trip = RecentTrip(
        id: 'trip_123',
        originId: 'slex_calamba',
        originName: 'Calamba Exit',
        destinationId: 'nlex_bocaue',
        destinationName: 'Bocaue Barrier',
        vehicleClass: 2,
        totalFare: 1128.0,
        corridors: ['SLEX', 'SKYWAY', 'NLEX'],
        timestamp: now,
        isFavorite: true,
      );

      final json = trip.toJson();
      final restored = RecentTrip.fromJson(json);

      expect(restored.id, 'trip_123');
      expect(restored.originId, 'slex_calamba');
      expect(restored.originName, 'Calamba Exit');
      expect(restored.destinationId, 'nlex_bocaue');
      expect(restored.destinationName, 'Bocaue Barrier');
      expect(restored.vehicleClass, 2);
      expect(restored.totalFare, 1128.0);
      expect(restored.corridors, ['SLEX', 'SKYWAY', 'NLEX']);
      expect(restored.isFavorite, isTrue);
    });

    test('copyWith modifies targeted properties', () {
      final trip = RecentTrip(
        id: 'trip_1',
        originId: 'slex_calamba',
        originName: 'Calamba Exit',
        destinationId: 'slex_alabang',
        destinationName: 'Alabang',
        vehicleClass: 1,
        totalFare: 154.0,
        corridors: ['SLEX'],
        timestamp: DateTime.now(),
      );

      final favorited = trip.copyWith(isFavorite: true, totalFare: 160.0);
      expect(favorited.isFavorite, isTrue);
      expect(favorited.totalFare, 160.0);
      expect(favorited.originName, 'Calamba Exit');
    });
  });

  group('CacheService Personalization Tests', () {
    late CacheService cacheService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cacheService = CacheService();
    });

    test('getRfidBalances returns default values when uninitialized', () async {
      final balances = await cacheService.getRfidBalances();
      expect(balances['autosweep'], 1250.0);
      expect(balances['easytrip'], 840.50);
    });

    test('saveRfidBalances updates and persists values', () async {
      await cacheService.saveRfidBalances(autosweep: 2500.0, easytrip: 150.0);
      final balances = await cacheService.getRfidBalances();
      expect(balances['autosweep'], 2500.0);
      expect(balances['easytrip'], 150.0);
    });

    test('addRecentTrip adds trip to front and avoids duplicate pair', () async {
      final tripA = RecentTrip(
        id: '1',
        originId: 'slex_calamba',
        originName: 'Calamba',
        destinationId: 'nlex_bocaue',
        destinationName: 'Bocaue',
        vehicleClass: 1,
        totalFare: 689.0,
        corridors: ['SLEX', 'NLEX'],
        timestamp: DateTime.now(),
      );

      final tripB = RecentTrip(
        id: '2',
        originId: 'star_batangas',
        originName: 'Batangas',
        destinationId: 'slex_calamba',
        destinationName: 'Calamba',
        vehicleClass: 1,
        totalFare: 210.0,
        corridors: ['STAR', 'SLEX'],
        timestamp: DateTime.now(),
      );

      await cacheService.addRecentTrip(tripA);
      await cacheService.addRecentTrip(tripB);

      var trips = await cacheService.getRecentTrips();
      expect(trips.first.originId, 'star_batangas');

      // Re-adding tripA should move it to the front without duplicating
      final tripAUpdated = tripA.copyWith(totalFare: 700.0);
      await cacheService.addRecentTrip(tripAUpdated);

      trips = await cacheService.getRecentTrips();
      expect(trips.first.originId, 'slex_calamba');
      expect(trips.first.totalFare, 700.0);
    });

    test('toggleFavoriteTrip toggles favorite status correctly', () async {
      final trip = RecentTrip(
        id: 'fav_test',
        originId: 'slex_calamba',
        originName: 'Calamba',
        destinationId: 'nlex_bocaue',
        destinationName: 'Bocaue',
        vehicleClass: 1,
        totalFare: 689.0,
        corridors: ['SLEX', 'NLEX'],
        timestamp: DateTime.now(),
        isFavorite: false,
      );

      await cacheService.addRecentTrip(trip);
      await cacheService.toggleFavoriteTrip('fav_test');

      var trips = await cacheService.getRecentTrips();
      expect(trips.firstWhere((t) => t.id == 'fav_test').isFavorite, isTrue);

      await cacheService.toggleFavoriteTrip('fav_test');
      trips = await cacheService.getRecentTrips();
      expect(trips.firstWhere((t) => t.id == 'fav_test').isFavorite, isFalse);
    });
  });

  group('HomeScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'aero_balance_autosweep': 1800.0,
        'aero_balance_easytrip': 120.0, // Low balance (<200)
      });
    });

    testWidgets('HomeScreen renders balance cards and status tags accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check balances render with formatted currency
      expect(find.text('₱1800.00'), findsOneWidget);
      expect(find.text('₱120.00'), findsOneWidget);

      // Check status indicators: 1800 -> Active, 120 -> Low Balance
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Low Balance'), findsOneWidget);
    });

    testWidgets('Tapping EDIT opens dialog and updates balance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find EDIT button on Autosweep card
      final editButtons = find.text('EDIT');
      expect(editButtons, findsNWidgets(2));

      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Check dialog opened
      expect(find.text('Update Autosweep RFID Balance'), findsOneWidget);

      // Enter new balance
      final input = find.byType(TextFormField);
      await tester.enterText(input, '3500.50');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save Balance'));
      await tester.pumpAndSettle();

      // Verify updated balance on screen
      expect(find.text('₱3500.50'), findsOneWidget);
    });

    testWidgets('TollCalculatorScreen displays low balance warning when fare exceeds wallet', (tester) async {
      SharedPreferences.setMockInitialValues({
        'aero_balance_autosweep': 50.0, // Low Autosweep balance (<150 needed for Calamba)
        'aero_balance_easytrip': 1000.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TollCalculatorScreen(
            initialOriginPlazaId: 'slex_calamba',
            initialDestinationPlazaId: 'slex_alabang',
            initialVehicleClass: 1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fare is 150.00, Autosweep balance is 50.00 -> Warning banner should appear
      expect(find.text('LOW RFID BALANCE WARNING'), findsOneWidget);
      expect(find.textContaining('Autosweep balance'), findsOneWidget);
      expect(find.text('Wallet: ₱50 (Short)'), findsOneWidget);
    });
  });
}

