import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/toll_plaza.dart';
import 'package:toll_companion/models/route_result.dart';
import 'package:toll_companion/services/toll_service.dart';
import 'package:toll_companion/widgets/plaza_picker_sheet.dart';

void main() {
  group('Toll Routing Engine Pathfinding Unit Tests', () {
    final tollService = TollService();

    test('Pathfinding correctly calculates intra-expressway route (STAR Batangas -> STAR Lipa)', () async {
      final segments = await tollService.findPathBetweenPlazas('star_batangas', 'star_lipa');
      expect(segments.isNotEmpty, isTrue);
      expect(segments.length, 2); // Batangas -> Ibaan -> Lipa
      expect(segments.first.expressway, 'STAR');
      expect(segments.first.operator, 'autosweep');

      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);
      expect(result.totalFare, 89.0); // 35 + 54 = 89
      expect(result.fareByOperator['autosweep'], 89.0);
      expect(result.fareByOperator.containsKey('easytrip'), isFalse);
    });

    test('Pathfinding correctly calculates multi-expressway cross-operator route (STAR Batangas -> NLEX Bocaue)', () async {
      final segments = await tollService.findPathBetweenPlazas('star_batangas', 'nlex_bocaue');
      expect(segments.isNotEmpty, isTrue);

      final resultClass1 = RouteResult.calculate(segments: segments, vehicleClass: 1);

      // Verify that both operators are traversed
      expect(resultClass1.fareByOperator.containsKey('autosweep'), isTrue);
      expect(resultClass1.fareByOperator.containsKey('easytrip'), isTrue);

      // Verify strict sum of subtotals
      final autosweepTotal = resultClass1.fareByOperator['autosweep']!;
      final easytripTotal = resultClass1.fareByOperator['easytrip']!;
      expect(resultClass1.totalFare, autosweepTotal + easytripTotal);

      // Verify vehicle class scaling
      final resultClass2 = RouteResult.calculate(segments: segments, vehicleClass: 2);
      expect(resultClass2.totalFare, greaterThan(resultClass1.totalFare));
      expect(resultClass2.fareByOperator['autosweep']!, greaterThan(autosweepTotal));
      expect(resultClass2.fareByOperator['easytrip']!, greaterThan(easytripTotal));
    });

    test('Pathfinding correctly computes long-range Central/North Luzon corridor (SCTEX Subic -> TPLEX Rosario)', () async {
      final segments = await tollService.findPathBetweenPlazas('sctex_subic_tipo', 'tplex_rosario');
      expect(segments.isNotEmpty, isTrue);

      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);
      expect(result.fareByOperator.containsKey('easytrip'), isTrue); // SCTEX
      expect(result.fareByOperator.containsKey('autosweep'), isTrue); // TPLEX
      expect(result.totalFare, result.fareByOperator['easytrip']! + result.fareByOperator['autosweep']!);
    });

    test('Pathfinding correctly calculates Southern Luzon CALAX connection (CALAX Silang -> SLEX Alabang)', () async {
      final segments = await tollService.findPathBetweenPlazas('calax_silang', 'slex_alabang');
      expect(segments.isNotEmpty, isTrue);

      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);
      expect(result.fareByOperator.containsKey('easytrip'), isTrue); // CALAX portion
      expect(result.fareByOperator.containsKey('autosweep'), isTrue); // SLEX portion
      expect(result.totalFare, result.fareByOperator['easytrip']! + result.fareByOperator['autosweep']!);
    });

    test('Pathfinding correctly calculates standalone Visayas bridge (CCLEX Cebu SRP -> Cordova)', () async {
      final segments = await tollService.findPathBetweenPlazas('cclex_cebu_srp', 'cclex_cordova');
      expect(segments.isNotEmpty, isTrue);
      expect(segments.length, 1);
      expect(segments.first.expressway, 'CCLEX');

      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);
      expect(result.totalFare, 90.0);
    });

    test('Pathfinding works in reverse direction (NLEX Bocaue -> STAR Batangas)', () async {
      final segmentsForward = await tollService.findPathBetweenPlazas('star_batangas', 'nlex_bocaue');
      final segmentsReverse = await tollService.findPathBetweenPlazas('nlex_bocaue', 'star_batangas');

      expect(segmentsReverse.isNotEmpty, isTrue);
      expect(segmentsReverse.length, segmentsForward.length);

      final resultForward = RouteResult.calculate(segments: segmentsForward, vehicleClass: 1);
      final resultReverse = RouteResult.calculate(segments: segmentsReverse, vehicleClass: 1);

      expect(resultReverse.totalFare, resultForward.totalFare);
      expect(resultReverse.fareByOperator['autosweep'], resultForward.fareByOperator['autosweep']);
      expect(resultReverse.fareByOperator['easytrip'], resultForward.fareByOperator['easytrip']);
    });

    test('CALAX to SLEX interchange routing correctly computes cross-expressway path', () async {
      final segments = await tollService.findPathBetweenPlazas('calax_silang', 'slex_alabang');
      expect(segments.isNotEmpty, isTrue);

      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);
      expect(result.fareByOperator.containsKey('easytrip'), isTrue); // CALAX portion
      expect(result.fareByOperator.containsKey('autosweep'), isTrue); // SLEX portion
      expect(result.totalFare, result.fareByOperator['easytrip']! + result.fareByOperator['autosweep']!);
    });

    test('Swap correctness: origin↔destination swap produces identical fare', () async {
      final fwd = await tollService.findPathBetweenPlazas('slex_calamba', 'nlex_bocaue');
      final rev = await tollService.findPathBetweenPlazas('nlex_bocaue', 'slex_calamba');

      final fwdResult = RouteResult.calculate(segments: fwd, vehicleClass: 1);
      final revResult = RouteResult.calculate(segments: rev, vehicleClass: 1);

      // Totals must match exactly after swap
      expect(revResult.totalFare, fwdResult.totalFare);

      // Per-operator subtotals must also match
      expect(revResult.fareByOperator['autosweep'], fwdResult.fareByOperator['autosweep']);
      expect(revResult.fareByOperator['easytrip'], fwdResult.fareByOperator['easytrip']);

      // Segment count must match
      expect(rev.length, fwd.length);
    });

    test('Corridor breadcrumb order matches traversal sequence (Calamba → Bocaue)', () async {
      final segments = await tollService.findPathBetweenPlazas('slex_calamba', 'nlex_bocaue');

      // Build ordered expressway chain, dedup adjacent
      final List<String> orderedExpressways = [];
      for (final seg in segments) {
        if (orderedExpressways.isEmpty || orderedExpressways.last != seg.expressway) {
          orderedExpressways.add(seg.expressway);
        }
      }

      // Expected order: SLEX → SKYWAY → NLEX (interchange connectors may appear)
      // Verify SLEX appears before SKYWAY, SKYWAY before NLEX
      final slexIdx = orderedExpressways.indexOf('SLEX');
      final skywayIdx = orderedExpressways.indexOf('SKYWAY');
      final nlexIdx = orderedExpressways.indexOf('NLEX');

      expect(slexIdx, greaterThanOrEqualTo(0), reason: 'SLEX should be in corridor');
      expect(skywayIdx, greaterThan(slexIdx), reason: 'SKYWAY should come after SLEX');
      expect(nlexIdx, greaterThan(skywayIdx), reason: 'NLEX should come after SKYWAY');
    });

    test('Per-operator subtotals match manual segment sum (Calamba → Bocaue)', () async {
      final segments = await tollService.findPathBetweenPlazas('slex_calamba', 'nlex_bocaue');
      final result = RouteResult.calculate(segments: segments, vehicleClass: 1);

      // Manually sum autosweep segments
      double manualAutosweep = 0;
      double manualEasytrip = 0;
      for (final seg in segments) {
        if (seg.operator == 'autosweep') {
          manualAutosweep += seg.fareClass1;
        } else if (seg.operator == 'easytrip') {
          manualEasytrip += seg.fareClass1;
        }
      }

      expect(result.fareByOperator['autosweep'], manualAutosweep);
      expect(result.fareByOperator['easytrip'], manualEasytrip);
      expect(result.totalFare, manualAutosweep + manualEasytrip);
    });
  });

  group('PlazaPickerSheet Widget Tests', () {
    testWidgets('PlazaPickerSheet filters plazas by text search and expressway chips', (WidgetTester tester) async {
      TollPlaza? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await PlazaPickerSheet.show(
                    context: context,
                    title: 'Select Origin Exit',
                    plazas: TollService.defaultPlazas,
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select Origin Exit'), findsOneWidget);
      expect(find.text('Batangas City Terminal'), findsOneWidget);

      // Filter by expressway chip 'NLEX'
      await tester.tap(find.widgetWithText(ChoiceChip, 'NLEX'));
      await tester.pumpAndSettle();

      expect(find.text('Balintawak Barrier (NLEX)'), findsOneWidget);
      expect(find.text('Mindanao Ave Exit (Smart Connect)'), findsOneWidget);
      expect(find.text('Batangas City Terminal'), findsNothing);

      // Search by text 'Marilao'
      await tester.enterText(find.byType(TextField), 'Marilao');
      await tester.pumpAndSettle();

      expect(find.text('Marilao Exit'), findsOneWidget);

      // Select 'Marilao Exit'
      await tester.tap(find.text('Marilao Exit'));
      await tester.pumpAndSettle();

      expect(selectedResult?.id, 'nlex_marilao');
    });

    testWidgets('PlazaPickerSheet partial-name search: "Calam" finds Calamba', (WidgetTester tester) async {
      TollPlaza? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await PlazaPickerSheet.show(
                    context: context,
                    title: 'Select Exit',
                    plazas: TollService.defaultPlazas,
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Type partial name
      await tester.enterText(find.byType(TextField), 'Calam');
      await tester.pumpAndSettle();

      // Should find Calamba
      expect(find.text('Calamba Exit'), findsOneWidget);

      // Should NOT show unrelated plazas
      expect(find.text('Batangas City Terminal'), findsNothing);
      expect(find.text('Bocaue Barrier'), findsNothing);

      // Select it
      await tester.tap(find.text('Calamba Exit'));
      await tester.pumpAndSettle();

      expect(selectedResult?.id, 'slex_calamba');
    });
  });
}
