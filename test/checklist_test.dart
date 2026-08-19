import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/checklist_item.dart';
import 'package:toll_companion/models/route_model.dart';
import 'package:toll_companion/screens/checklist_screen.dart';
import 'package:toll_companion/services/checklist_service.dart';

class MockChecklistService extends ChecklistService {
  final Stream<List<ChecklistItem>> Function()? itemsStreamProvider;

  MockChecklistService({this.itemsStreamProvider});

  @override
  Stream<List<ChecklistItem>> getChecklistItems() {
    final provider = itemsStreamProvider;
    if (provider != null) {
      return provider();
    }
    return Stream.value([]);
  }
}

void main() {
  group('ChecklistItem Model Unit Tests', () {
    test('ChecklistItem model serializes to and from Firestore map', () {
      const item = ChecklistItem(
        id: 'item_1',
        title: 'Tire Pressure & Spare Tire',
        description: 'Verify 32-35 PSI on all tires.',
        category: 'vehicle',
        operator: null,
        sortOrder: 1,
        isActive: true,
      );

      final map = item.toFirestore();
      expect(map['title'], 'Tire Pressure & Spare Tire');
      expect(map['category'], 'vehicle');
      expect(map['operator'], isNull);
      expect(map['sortOrder'], 1);
      expect(map['isActive'], isTrue);
    });
  });

  group('ChecklistScreen Widget Tests', () {
    final sampleItems = [
      const ChecklistItem(
        id: 'check_rfid_auto',
        title: 'Autosweep RFID Balance',
        description: 'Confirm balance for SMC roads.',
        category: 'rfid',
        operator: 'autosweep',
        sortOrder: 1,
        isActive: true,
      ),
      const ChecklistItem(
        id: 'check_tires',
        title: 'Tire Pressure & Spare Tire',
        description: 'Check PSI on all 4 road tires.',
        category: 'vehicle',
        sortOrder: 2,
        isActive: true,
      ),
      const ChecklistItem(
        id: 'check_license',
        title: 'Driver\'s License & OR/CR',
        description: 'Carry physical original copies.',
        category: 'documents',
        sortOrder: 3,
        isActive: true,
      ),
    ];

    testWidgets('Renders categorized checklist items and progress bar',
        (WidgetTester tester) async {
      final mockService = MockChecklistService(
        itemsStreamProvider: () => Stream.value(sampleItems),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistScreen(checklistService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & progress readout
      expect(find.text('Pre-Trip Checklist'), findsOneWidget);
      expect(find.text('0 of 3 Ready'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // Verify Category Headers
      expect(find.text('RFID & TOLL WALLETS'), findsOneWidget);
      expect(find.text('VEHICLE ROADWORTHINESS'), findsOneWidget);
      expect(find.text('DRIVER & VEHICLE DOCUMENTS'), findsOneWidget);

      // Verify Items
      expect(find.text('Autosweep RFID Balance'), findsOneWidget);
      expect(find.text('AUTOSWEEP'), findsOneWidget);
      expect(find.text('Tire Pressure & Spare Tire'), findsOneWidget);
      expect(find.text('Driver\'s License & OR/CR'), findsOneWidget);
    });

    testWidgets('Tapping checklist item updates progress in session and resets',
        (WidgetTester tester) async {
      final mockService = MockChecklistService(
        itemsStreamProvider: () => Stream.value(sampleItems),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistScreen(checklistService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 of 3 Ready'), findsOneWidget);

      // Tap first item
      await tester.tap(find.text('Autosweep RFID Balance'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 Ready'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Tap second item
      await tester.tap(find.text('Tire Pressure & Spare Tire'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 Ready'), findsOneWidget);

      // Tap third item -> completes all 3!
      await tester.tap(find.text('Driver\'s License & OR/CR'));
      await tester.pumpAndSettle();

      expect(find.text('3 of 3 Ready'), findsOneWidget);
      expect(find.text('Ready to Drive'), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.text('0 of 3 Ready'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('Displays route context banner when route is passed',
        (WidgetTester tester) async {
      final mockService = MockChecklistService(
        itemsStreamProvider: () => Stream.value(sampleItems),
      );

      const sampleRoute = RouteModel(
        id: 'route_sample',
        name: 'Plaza A1 → Plaza B3',
        origin: 'Plaza A1',
        destination: 'Plaza B3',
        segmentIds: ['seg_1'],
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistScreen(
            checklistService: mockService,
            route: sampleRoute,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TRIP CONTEXT'), findsOneWidget);
      expect(find.text('Plaza A1 → Plaza B3'), findsOneWidget);
    });

    testWidgets('Displays empty state when no items exist',
        (WidgetTester tester) async {
      final mockService = MockChecklistService(
        itemsStreamProvider: () => Stream.value([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistScreen(checklistService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No checklist items available yet'), findsOneWidget);
      expect(find.text('Seed Sample Checklist Items'), findsOneWidget);
    });

    testWidgets('Displays error state when checklist stream fails',
        (WidgetTester tester) async {
      final mockService = MockChecklistService(
        itemsStreamProvider: () => Stream.error('Firestore connection timeout'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChecklistScreen(checklistService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Couldn\'t load checklist'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
