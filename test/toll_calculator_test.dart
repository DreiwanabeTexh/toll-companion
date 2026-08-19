import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/toll_segment.dart';
import 'package:toll_companion/models/route_model.dart';
import 'package:toll_companion/models/route_result.dart';
import 'package:toll_companion/screens/toll_calculator_screen.dart';
import 'package:toll_companion/services/toll_service.dart';

class MockTollService extends TollService {
  final Stream<List<RouteModel>> Function()? routesStreamProvider;
  final Future<List<TollSegment>> Function(RouteModel)? segmentsProvider;

  MockTollService({
    this.routesStreamProvider,
    this.segmentsProvider,
  });

  @override
  Stream<List<RouteModel>> getActiveRoutes() {
    final provider = routesStreamProvider;
    if (provider != null) {
      return provider();
    }
    return Stream.value([]);
  }

  @override
  Future<List<TollSegment>> getSegmentsForRoute(RouteModel route) async {
    final provider = segmentsProvider;
    if (provider != null) {
      return provider(route);
    }
    return [];
  }
}

void main() {
  group('RouteResult Fare Calculation Unit Tests', () {
    final sampleSegmentAutosweep1 = TollSegment(
      id: 'seg_auto_1',
      expressway: 'ALPHA_EXPRESSWAY',
      expresswayName: 'Alpha Tollway',
      operator: 'autosweep',
      entryPoint: 'Plaza A1',
      exitPoint: 'Plaza A2',
      fareClass1: 50.0,
      fareClass2: 100.0,
      fareClass3: 150.0,
      lastUpdated: DateTime(2025, 1, 10),
    );

    final sampleSegmentAutosweep2 = TollSegment(
      id: 'seg_auto_2',
      expressway: 'ALPHA_EXPRESSWAY',
      expresswayName: 'Alpha Tollway',
      operator: 'autosweep',
      entryPoint: 'Plaza A2',
      exitPoint: 'Plaza A3',
      fareClass1: 75.0,
      fareClass2: 150.0,
      fareClass3: 225.0,
      lastUpdated: DateTime(2025, 1, 12),
    );

    final sampleSegmentEasytrip1 = TollSegment(
      id: 'seg_easy_1',
      expressway: 'BETA_EXPRESSWAY',
      expresswayName: 'Beta Tollway',
      operator: 'easytrip',
      entryPoint: 'Plaza B1',
      exitPoint: 'Plaza B2',
      fareClass1: 85.0,
      fareClass2: 170.0,
      fareClass3: 255.0,
      lastUpdated: DateTime(2025, 1, 15),
    );

    final sampleSegmentEasytrip2 = TollSegment(
      id: 'seg_easy_2',
      expressway: 'BETA_EXPRESSWAY',
      expresswayName: 'Beta Tollway',
      operator: 'easytrip',
      entryPoint: 'Plaza B2',
      exitPoint: 'Plaza B3',
      fareClass1: 65.0,
      fareClass2: 130.0,
      fareClass3: 195.0,
      lastUpdated: DateTime(2025, 1, 15),
    );

    test('Multi-operator route correctly partitions fares by operator and sums to total', () {
      final segments = [
        sampleSegmentAutosweep1,
        sampleSegmentAutosweep2,
        sampleSegmentEasytrip1,
        sampleSegmentEasytrip2,
      ];

      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);

      // Verify separate operator subtotals
      expect(result.fareByOperator['autosweep'], 125.0); // 50 + 75
      expect(result.fareByOperator['easytrip'], 150.0);  // 85 + 65

      // Verify total is exact sum of per-operator subtotals
      expect(result.totalFare, 275.0); // 125 + 150

      // Verify segment grouping
      expect(result.segmentsByOperator['autosweep']?.length, 2);
      expect(result.segmentsByOperator['easytrip']?.length, 2);

      // Verify top-up advisories
      expect(result.topUpAdvisories, contains('Load at least ₱125.00 on Autosweep'));
      expect(result.topUpAdvisories, contains('Load at least ₱150.00 on Easytrip'));
    });

    test('Vehicle class changes (Class 2 and Class 3) update per-operator fares proportionally', () {
      final segments = [
        sampleSegmentAutosweep1,
        sampleSegmentEasytrip1,
      ];

      // Class 2
      final resultClass2 = RouteResult.calculate(segments: segments, vehicleClass: 2);
      expect(resultClass2.fareByOperator['autosweep'], 100.0);
      expect(resultClass2.fareByOperator['easytrip'], 170.0);
      expect(resultClass2.totalFare, 270.0);

      // Class 3
      final resultClass3 = RouteResult.calculate(segments: segments, vehicleClass: 3);
      expect(resultClass3.fareByOperator['autosweep'], 150.0);
      expect(resultClass3.fareByOperator['easytrip'], 255.0);
      expect(resultClass3.totalFare, 405.0);
    });

    test('Single-operator route only contains that operator in breakdown', () {
      final autosweepOnly = [sampleSegmentAutosweep1, sampleSegmentAutosweep2];
      final result = RouteResult.calculate(segments: autosweepOnly, vehicleClass: 1);

      expect(result.fareByOperator.containsKey('autosweep'), isTrue);
      expect(result.fareByOperator.containsKey('easytrip'), isFalse);
      expect(result.fareByOperator['autosweep'], 125.0);
      expect(result.totalFare, 125.0);
      expect(result.topUpAdvisories.length, 1);
      expect(result.topUpAdvisories.first, 'Load at least ₱125.00 on Autosweep');
    });
  });

  group('TollCalculatorScreen Widget Tests', () {
    final sampleMultiOperatorRoute = const RouteModel(
      id: 'sample_multi_route',
      name: 'Sample Multi-Operator Corridor',
      origin: 'Plaza A1 Terminal',
      destination: 'Plaza B2 Terminal',
      segmentIds: ['seg_auto_1', 'seg_easy_1'],
      isActive: true,
    );

    final sampleSegments = [
      TollSegment(
        id: 'seg_auto_1',
        expressway: 'ALPHA_EXPRESSWAY',
        expresswayName: 'Alpha Tollway',
        operator: 'autosweep',
        entryPoint: 'Plaza A1',
        exitPoint: 'Plaza A2',
        fareClass1: 50.0,
        fareClass2: 100.0,
        fareClass3: 150.0,
        lastUpdated: DateTime(2025, 1, 10),
      ),
      TollSegment(
        id: 'seg_easy_1',
        expressway: 'BETA_EXPRESSWAY',
        expresswayName: 'Beta Tollway',
        operator: 'easytrip',
        entryPoint: 'Plaza B1',
        exitPoint: 'Plaza B2',
        fareClass1: 85.0,
        fareClass2: 170.0,
        fareClass3: 255.0,
        lastUpdated: DateTime(2025, 1, 15),
      ),
    ];

    testWidgets('Renders route selector, vehicle class, operator cards and total card',
        (WidgetTester tester) async {
      final mockService = MockTollService(
        routesStreamProvider: () => Stream.value([sampleMultiOperatorRoute]),
        segmentsProvider: (r) async => sampleSegments,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TollCalculatorScreen(tollService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Toll Calculator'), findsOneWidget);

      // Verify Route selector contains the route name
      expect(find.text('Sample Multi-Operator Corridor'), findsWidgets);

      // Verify Vehicle Class selector
      expect(find.text('Class 1'), findsOneWidget);
      expect(find.text('Class 2'), findsOneWidget);
      expect(find.text('Class 3'), findsOneWidget);

      // Verify Autosweep Operator Card
      expect(find.text('Autosweep Roads'), findsOneWidget);
      expect(find.text('Alpha Tollway'), findsOneWidget);
      expect(find.text('Plaza A1 → Plaza A2'), findsOneWidget);
      expect(find.text('₱50.00'), findsWidgets);

      // Verify Easytrip Operator Card
      expect(find.text('Easytrip Roads'), findsOneWidget);
      expect(find.text('Beta Tollway'), findsOneWidget);
      expect(find.text('Plaza B1 → Plaza B2'), findsOneWidget);
      expect(find.text('₱85.00'), findsWidgets);

      // Verify Total Toll Fare Card (50 + 85 = 135)
      expect(find.text('TOTAL TOLL FARE'), findsOneWidget);
      expect(find.text('₱135.00'), findsOneWidget);

      // Verify Wallet Top-Up Callouts
      expect(find.text('Load at least ₱50.00 on Autosweep'), findsOneWidget);
      expect(find.text('Load at least ₱85.00 on Easytrip'), findsOneWidget);

      // Switch to Class 2 and verify updated fares (100 + 170 = 270)
      await tester.tap(find.text('Class 2'));
      await tester.pumpAndSettle();

      expect(find.text('₱100.00'), findsWidgets);
      expect(find.text('₱170.00'), findsWidgets);
      expect(find.text('₱270.00'), findsOneWidget);
      expect(find.text('Load at least ₱100.00 on Autosweep'), findsOneWidget);
      expect(find.text('Load at least ₱170.00 on Easytrip'), findsOneWidget);
    });

    testWidgets('Displays empty state when no routes are available',
        (WidgetTester tester) async {
      final mockService = MockTollService(
        routesStreamProvider: () => Stream.value([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TollCalculatorScreen(tollService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No routes available yet'), findsOneWidget);
      expect(find.text('Seed Sample Placeholder Routes'), findsOneWidget);
    });

    testWidgets('Displays error state when route stream emits error',
        (WidgetTester tester) async {
      final mockService = MockTollService(
        routesStreamProvider: () => Stream.error('Network connection error'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TollCalculatorScreen(tollService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Couldn\'t load routes'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
