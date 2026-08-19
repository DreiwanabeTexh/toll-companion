import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/guide_entry.dart';
import 'package:toll_companion/screens/quick_guide_screen.dart';
import 'package:toll_companion/screens/guide_detail_screen.dart';
import 'package:toll_companion/services/guide_service.dart';

class MockGuideService extends GuideService {
  final Stream<List<GuideEntry>> Function()? guideEntriesStreamProvider;

  MockGuideService({
    this.guideEntriesStreamProvider,
  });

  @override
  Stream<List<GuideEntry>> getGuideEntries() {
    final provider = guideEntriesStreamProvider;
    if (provider != null) {
      return provider();
    }
    return Stream.value([]);
  }
}

void main() {
  group('GuideEntry Model Tests', () {
    test('GuideEntry model holds all expected fields and serialization', () {
      final now = DateTime(2025, 1, 15);
      final entry = GuideEntry(
        id: 'test_id',
        title: 'Sample Test Question?',
        shortTitle: 'Test Question',
        category: 'rfid',
        content: 'Step 1: Do this.\nStep 2: Do that.',
        sortOrder: 1,
        tags: ['rfid', 'test'],
        isActive: true,
        lastUpdated: now,
      );

      expect(entry.id, 'test_id');
      expect(entry.title, 'Sample Test Question?');
      expect(entry.shortTitle, 'Test Question');
      expect(entry.category, 'rfid');
      expect(entry.tags, contains('rfid'));
      expect(entry.tags, contains('test'));
      expect(entry.sortOrder, 1);
      expect(entry.isActive, isTrue);

      final firestoreMap = entry.toFirestore();
      expect(firestoreMap['title'], 'Sample Test Question?');
      expect(firestoreMap['category'], 'rfid');
      expect(firestoreMap['tags'], ['rfid', 'test']);
    });
  });

  group('QuickGuideScreen & GuideDetailScreen Widget Tests', () {
    final sampleEntries = [
      GuideEntry(
        id: 'guide_1',
        title: 'What do I do if my RFID is not detected at the toll gantry?',
        shortTitle: 'RFID Not Reading',
        category: 'rfid',
        content: 'Stay in lane. Await teller assistance.',
        sortOrder: 1,
        tags: ['rfid', 'toll'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      GuideEntry(
        id: 'guide_2',
        title: 'What do I do if I get a flat tire on the expressway shoulder?',
        shortTitle: 'Flat Tire on Shoulder',
        category: 'breakdown',
        content: 'Turn on hazard lights. Stay behind guardrail.',
        sortOrder: 2,
        tags: ['flat tire', 'breakdown'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
      GuideEntry(
        id: 'guide_3',
        title: 'What do I do if I miss my planned expressway exit?',
        shortTitle: 'Missed Expressway Exit',
        category: 'navigation',
        content: 'Do NOT reverse. Proceed to next exit.',
        sortOrder: 3,
        tags: ['navigation'],
        isActive: true,
        lastUpdated: DateTime(2025, 1, 15),
      ),
    ];

    testWidgets('Renders expandable accordion categories and Contact Support card',
        (WidgetTester tester) async {
      final mockService = MockGuideService(
        guideEntriesStreamProvider: () => Stream.value(sampleEntries),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuickGuideScreen(guideService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Quick Guide'), findsWidgets);

      // Verify Accordion Categories
      expect(find.text('RFID & Tolls'), findsOneWidget);
      expect(find.text('Vehicle Status & Breakdown'), findsOneWidget);
      expect(find.text('Expressway Navigation'), findsOneWidget);
      expect(find.text('Road Safety Protocols'), findsOneWidget);

      // RFID category is expanded by default in Aero (shows description and action buttons)
      expect(
        find.text(
            'Transponder issues, toll zone discrepancies, and account linking.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Troubleshoot'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'View FAQ'), findsOneWidget);

      // Verify Contact Support Card
      expect(find.text('Need human assistance?'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Contact Support'), findsOneWidget);
    });

    testWidgets('Tapping accordion header toggles category expand/collapse',
        (WidgetTester tester) async {
      final mockService = MockGuideService(
        guideEntriesStreamProvider: () => Stream.value(sampleEntries),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuickGuideScreen(guideService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Breakdown category is initially collapsed
      expect(
        find.text(
            'Battery optimization, tire pressure alerts, and emergency towing.'),
        findsNothing,
      );

      // Tap Vehicle Status & Breakdown header to expand it
      await tester.tap(find.text('Vehicle Status & Breakdown'));
      await tester.pumpAndSettle();

      // Description is now visible
      expect(
        find.text(
            'Battery optimization, tire pressure alerts, and emergency towing.'),
        findsOneWidget,
      );

      // Tap again to collapse it
      await tester.tap(find.text('Vehicle Status & Breakdown'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Battery optimization, tire pressure alerts, and emergency towing.'),
        findsNothing,
      );
    });

    testWidgets(
        'Tapping Troubleshoot button navigates to GuideDetailScreen with full content',
        (WidgetTester tester) async {
      final mockService = MockGuideService(
        guideEntriesStreamProvider: () => Stream.value(sampleEntries),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuickGuideScreen(guideService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Troubleshoot button in expanded RFID category
      await tester.tap(find.widgetWithText(ElevatedButton, 'Troubleshoot'));
      await tester.pumpAndSettle();

      // Should now be on GuideDetailScreen
      expect(find.byType(GuideDetailScreen), findsOneWidget);
      expect(find.text('Recommended Actions'), findsOneWidget);
      expect(find.text('Stay in lane. Await teller assistance.'), findsOneWidget);
      expect(find.text('#rfid'), findsOneWidget);
      expect(find.text('#toll'), findsOneWidget);

      // Tap back button
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Back on QuickGuideScreen
      expect(find.byType(QuickGuideScreen), findsOneWidget);
    });

    testWidgets('Displays empty state when no guide entries exist',
        (WidgetTester tester) async {
      final mockService = MockGuideService(
        guideEntriesStreamProvider: () => Stream.value([]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuickGuideScreen(guideService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No guide entries available yet'), findsOneWidget);
      expect(find.text('Seed Sample Placeholder Guides'), findsOneWidget);
    });

    testWidgets('Displays error state when guide stream fails',
        (WidgetTester tester) async {
      final mockService = MockGuideService(
        guideEntriesStreamProvider:
            () => Stream.error('Firestore connection timeout'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuickGuideScreen(guideService: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(
          find.textContaining('Couldn\'t load guide entries'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
