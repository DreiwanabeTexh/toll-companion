import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/route_model.dart';
import 'package:toll_companion/models/route_briefing.dart';
import 'package:toll_companion/screens/route_briefing_screen.dart';
import 'package:toll_companion/services/briefing_service.dart';
import 'package:toll_companion/services/toll_service.dart';

class MockBriefingService extends BriefingService {
  final Stream<RouteBriefing?> Function(String routeId)? briefingStreamProvider;

  MockBriefingService({this.briefingStreamProvider});

  @override
  Stream<RouteBriefing?> getBriefingForRoute(String routeId) {
    final provider = briefingStreamProvider;
    if (provider != null) {
      return provider(routeId);
    }
    return Stream.value(null);
  }
}

class MockTollService extends TollService {
  final Stream<List<RouteModel>> Function()? routesStreamProvider;

  MockTollService({this.routesStreamProvider});

  @override
  Stream<List<RouteModel>> getActiveRoutes() {
    final provider = routesStreamProvider;
    if (provider != null) {
      return provider();
    }
    return Stream.value([]);
  }
}

void main() {
  group('RouteBriefing Model Unit Tests', () {
    test('RouteBriefing model serializes correctly', () {
      final briefing = RouteBriefing(
        id: 'briefing_1',
        routeId: 'route_1',
        routeName: 'Sample Route A → B',
        generalAdvice: 'General route caution.',
        laneTips: const [
          LaneTip(
            title: 'Speed Limit',
            description: 'Maintain 80 km/h.',
            icon: 'speed',
          ),
        ],
        restStops: const [
          RestStop(
            name: 'Service Plaza 1',
            location: 'KM 25',
            kilometer: 'KM 25',
            amenities: ['Fuel', 'Food'],
          ),
        ],
        exitConfusions: const [
          ExitWarning(
            location: 'Exit 4B Split',
            warning: 'Sharp right fork.',
            tip: 'Pre-position in right lane.',
          ),
        ],
        lastUpdated: DateTime(2025, 1, 15),
        isActive: true,
      );

      final map = briefing.toFirestore();
      expect(map['routeId'], 'route_1');
      expect(map['routeName'], 'Sample Route A → B');
      expect((map['laneTips'] as List).length, 1);
      expect((map['restStops'] as List).length, 1);
      expect((map['exitConfusions'] as List).length, 1);
      expect(map['isActive'], isTrue);
    });
  });

  group('RouteBriefingScreen Widget Tests', () {
    const sampleRoute = RouteModel(
      id: 'sample_route_1',
      name: 'Sample Expressway Route (A → B)',
      origin: 'Plaza A',
      destination: 'Plaza B',
      segmentIds: ['seg_1'],
      isActive: true,
    );

    final sampleBriefing = RouteBriefing(
      id: 'briefing_sample_1',
      routeId: 'sample_route_1',
      routeName: 'Sample Expressway Route (A → B)',
      generalAdvice:
          'Maintain safe following distance and keep RFID tags positioned correctly.',
      laneTips: const [
        LaneTip(
          title: 'Transition Gantry Approach',
          description: 'Slow down to 20 km/h at toll barrier.',
          icon: 'speed',
        ),
      ],
      restStops: const [
        RestStop(
          name: 'Central Travel Oasis',
          location: 'KM 30 Southbound',
          kilometer: 'KM 30',
          amenities: ['Fuel', 'Restrooms', 'Food'],
        ),
      ],
      exitConfusions: const [
        ExitWarning(
          location: 'Plaza A2 Fork Split',
          warning: 'Right 2 lanes exit to industrial bypass.',
          tip: 'Stay on the left 2 lanes 1 km before fork.',
        ),
      ],
      lastUpdated: DateTime(2025, 1, 15),
      isActive: true,
    );

    testWidgets('Renders route briefing with tabs for lane tips, rest stops, and exit warnings',
        (WidgetTester tester) async {
      final mockTollService = MockTollService(
        routesStreamProvider: () => Stream.value([sampleRoute]),
      );
      final mockBriefingService = MockBriefingService(
        briefingStreamProvider: (id) => Stream.value(sampleBriefing),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteBriefingScreen(
            tollService: mockTollService,
            briefingService: mockBriefingService,
            routeId: 'sample_route_1',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Route Advisory
      expect(find.text('Route Briefing'), findsOneWidget);
      expect(find.text('ROUTE ADVISORY'), findsOneWidget);
      expect(find.textContaining('Maintain safe following distance'), findsOneWidget);

      // Verify 3 Tabs
      expect(find.text('Lane Tips'), findsOneWidget);
      expect(find.text('Rest Stops'), findsOneWidget);
      expect(find.text('Exit Warnings'), findsOneWidget);

      // Verify Lane Tip in first tab
      expect(find.text('Transition Gantry Approach'), findsOneWidget);
      expect(find.text('Slow down to 20 km/h at toll barrier.'), findsOneWidget);

      // Switch to Rest Stops Tab
      await tester.tap(find.text('Rest Stops'));
      await tester.pumpAndSettle();

      expect(find.text('Central Travel Oasis'), findsOneWidget);
      expect(find.text('KM 30'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Restrooms'), findsOneWidget);

      // Switch to Exit Warnings Tab
      await tester.tap(find.text('Exit Warnings'));
      await tester.pumpAndSettle();

      expect(find.text('Plaza A2 Fork Split'), findsOneWidget);
      expect(find.text('Right 2 lanes exit to industrial bypass.'), findsOneWidget);
      expect(find.text('Stay on the left 2 lanes 1 km before fork.'), findsOneWidget);
    });

    testWidgets('Displays empty state when no briefing exists for route',
        (WidgetTester tester) async {
      final mockTollService = MockTollService(
        routesStreamProvider: () => Stream.value([sampleRoute]),
      );
      final mockBriefingService = MockBriefingService(
        briefingStreamProvider: (id) => Stream.value(null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteBriefingScreen(
            tollService: mockTollService,
            briefingService: mockBriefingService,
            routeId: 'sample_route_1',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No briefing for this route yet'), findsOneWidget);
      expect(find.text('Seed Sample Route Briefings'), findsOneWidget);
    });

    testWidgets('Displays error state when briefing stream fails',
        (WidgetTester tester) async {
      final mockTollService = MockTollService(
        routesStreamProvider: () => Stream.value([sampleRoute]),
      );
      final mockBriefingService = MockBriefingService(
        briefingStreamProvider: (id) => Stream.error('Network disconnect'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RouteBriefingScreen(
            tollService: mockTollService,
            briefingService: mockBriefingService,
            routeId: 'sample_route_1',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Couldn\'t load briefing'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
