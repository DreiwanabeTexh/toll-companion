import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/toll_plaza.dart';
import 'package:toll_companion/models/toll_segment.dart';
import 'package:toll_companion/models/route_result.dart';
import 'package:toll_companion/screens/toll_calculator_screen.dart';
import 'package:toll_companion/services/toll_service.dart';

class MockTollService extends TollService {
  final Stream<List<TollPlaza>> Function()? plazasStreamProvider;

  MockTollService({this.plazasStreamProvider});

  @override
  Stream<List<TollPlaza>> getActivePlazas() {
    final provider = plazasStreamProvider;
    if (provider != null) {
      return provider();
    }
    return Stream.value(TollService.defaultPlazas);
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
      lastVerified: DateTime(2025, 1, 10),
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
      lastVerified: DateTime(2025, 1, 12),
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
      lastVerified: DateTime(2025, 1, 15),
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
      lastVerified: DateTime(2025, 1, 15),
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

  group('TollCalculatorScreen Exit-to-Exit Widget Tests', () {
    testWidgets('Renders Trip Details, Origin/Destination cards, class selector, and calculated fare breakdown',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockTollService(
        plazasStreamProvider: () => Stream.value(TollService.defaultPlazas),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TollCalculatorScreen(tollService: mockService),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify Header & Hero Section
      expect(find.text('Trip Details'), findsWidgets);
      expect(find.text('ORIGIN EXIT'), findsOneWidget);
      expect(find.text('DESTINATION EXIT'), findsOneWidget);

      // Verify empty-state placeholder text (no default route pre-selected)
      expect(find.text('Tap to select origin exit...'), findsOneWidget);
      expect(find.text('Tap to select destination exit...'), findsOneWidget);

      // Verify Vehicle Class selector
      expect(find.text('Class 1'), findsOneWidget);
      expect(find.text('Class 2'), findsOneWidget);
      expect(find.text('Class 3'), findsOneWidget);

      // Verify Calculate Button
      expect(find.text('CALCULATE FARE'), findsOneWidget);

      // Switch to Class 2
      await tester.tap(find.text('Class 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Class 2'), findsOneWidget);
    });

    testWidgets('Renders Total Trip Cost hero card and Fuel Estimator controls when route is calculated',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockTollService(
        plazasStreamProvider: () => Stream.value(TollService.defaultPlazas),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TollCalculatorScreen(
            tollService: mockService,
            initialOriginPlazaId: 'star_batangas',
            initialDestinationPlazaId: 'star_lipa',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Initially no fare is calculated until user taps Calculate Fare button
      expect(find.text('CALCULATE FARE'), findsOneWidget);
      expect(find.text('TOTAL ESTIMATED TRIP COST'), findsNothing);

      // Tap Calculate Fare button
      await tester.tap(find.text('CALCULATE FARE'));
      await tester.pumpAndSettle();

      // Verify Total Estimated Trip Cost Hero Card
      expect(find.text('TOTAL ESTIMATED TRIP COST'), findsOneWidget);
      expect(find.text('(Toll + Fuel)'), findsOneWidget);
      expect(find.text('TOLL FARE'), findsOneWidget);
      expect(find.text('EST. FUEL'), findsOneWidget);
      expect(find.text('DISTANCE'), findsOneWidget);

      // Verify Gas & Fuel Estimator Accordion
      expect(find.text('Gas & Fuel Estimator'), findsOneWidget);

      // Tap on Gas & Fuel Estimator to expand settings
      await tester.tap(find.text('Gas & Fuel Estimator'));
      await tester.pumpAndSettle();

      // Verify Simplified Senior-Friendly Preset and Input Labels
      expect(find.text('CAR TYPE (AUTO-FILLS KM/L)'), findsOneWidget);
      expect(find.text('MANUAL INPUTS (EDIT ANYTIME)'), findsOneWidget);
      expect(find.text('KM / LITER'), findsOneWidget);
      expect(find.text('GAS PRICE'), findsOneWidget);
      expect(find.text('Your trip and fuel settings are saved on this device.'), findsOneWidget);
      expect(find.text('Sedan'), findsOneWidget);
      expect(find.text('SUV'), findsOneWidget);
      expect(find.text('Van/Pickup'), findsOneWidget);

      // Switch preset to SUV
      await tester.tap(find.text('SUV'));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL ESTIMATED TRIP COST'), findsOneWidget);
    });

    testWidgets('TollCalculatorScreen Skyway toggle switches between Elevated and At-Grade route',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final tollService = TollService();

      await tester.pumpWidget(
        MaterialApp(
          home: TollCalculatorScreen(
            tollService: tollService,
            initialOriginPlazaId: 'slex_calamba',
            initialDestinationPlazaId: 'nlex_balintawak',
            initialVehicleClass: 1,
            initialUseSkyway: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Calculate Fare button
      await tester.tap(find.text('CALCULATE FARE'));
      await tester.pumpAndSettle();

      // Verify Skyway toggle is visible and set to Elevated route
      expect(find.text('Via Skyway (Elevated)'), findsOneWidget);
      expect(find.text('VIA SKYWAY'), findsOneWidget);

      // Tap Switch to toggle off Skyway
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Outdated banner appears indicating inputs changed
      expect(find.text('Route details changed. Tap Calculate Fare to update.'), findsOneWidget);

      // Tap Calculate Fare to re-calculate At-Grade route
      await tester.tap(find.text('CALCULATE FARE'));
      await tester.pumpAndSettle();

      // Verify toggle switched to SLEX At-Grade route and outdated banner disappears
      expect(find.text('SLEX At-Grade (Surface)'), findsOneWidget);
      expect(find.text('AT-GRADE'), findsOneWidget);
      expect(find.text('Route details changed. Tap Calculate Fare to update.'), findsNothing);
    });

    testWidgets('Calculate Fare button disabled when missing exits and enabled when selected',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TollCalculatorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find Calculate button
      final btnFinder = find.widgetWithText(ElevatedButton, 'CALCULATE FARE');
      expect(btnFinder, findsOneWidget);

      final btnWidget = tester.widget<ElevatedButton>(btnFinder);
      expect(btnWidget.onPressed, isNull); // Disabled!
    });
  });

  group('Skyway vs SLEX At-Grade Routing Engine Unit Tests', () {
    final tollService = TollService();

    test('findPathSync with useSkyway=true traverses elevated Skyway Stages 1-3', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'slex_calamba',
        destinationPlazaId: 'nlex_balintawak',
        vehicleClass: 1,
        useSkyway: true,
      );

      final expressways = result.segments.map((s) => s.expressway).toSet();
      expect(expressways.contains('SKYWAY'), isTrue);
      expect(expressways.contains('SLEX'), isTrue);

      // Skyway elevated route includes SLEX (137) + Skyway Stages 1&2 (164) + Skyway Stage 3 (264) = 565.00
      expect(result.totalFare, 565.0);
    });

    test('findPathSync with useSkyway=false routes via SLEX at-grade avoiding Skyway', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'slex_calamba',
        destinationPlazaId: 'nlex_balintawak',
        vehicleClass: 1,
        useSkyway: false,
      );

      final expressways = result.segments.map((s) => s.expressway).toSet();
      expect(expressways.contains('SKYWAY'), isFalse);
      expect(expressways.contains('SLEX'), isTrue);

      // At-grade route avoids Skyway elevated toll (₱137 + ₱45 = ₱182.00)
      expect(result.totalFare, 182.0);
    });

    test('findPathSync with Lipa to Mindanao Ave with useSkyway=true returns exact regulatory fare 735', () {
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'star_lipa',
        destinationPlazaId: 'nlex_mindanao_ave',
        vehicleClass: 1,
        useSkyway: true,
      );

      expect(result.fareByOperator['autosweep'], 666.0); // STAR 64 + SLEX 174 + Skyway 428 = 666
      expect(result.fareByOperator['easytrip'], 69.0);   // NLEX 69
      expect(result.totalFare, 735.0);
    });
  });
}
