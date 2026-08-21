import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/models/data_report.dart';
import 'package:toll_companion/models/emergency_contact.dart';
import 'package:toll_companion/models/route_model.dart';
import 'package:toll_companion/models/toll_segment.dart';
import 'package:toll_companion/models/guide_entry.dart';
import 'package:toll_companion/services/cache_service.dart';
import 'package:toll_companion/services/report_service.dart';
import 'package:toll_companion/widgets/aero_offline_banner.dart';
import 'package:toll_companion/widgets/report_dialog.dart';

class MockReportService extends ReportService {
  DataReport? lastSubmittedReport;
  bool shouldSucceed;

  MockReportService({this.shouldSucceed = true});

  @override
  Future<bool> submitReport({
    required String reportType,
    required String targetId,
    required String targetName,
    required String issueDescription,
    String appVersion = '1.0.0+1',
    Map<String, dynamic> contextData = const {},
  }) async {
    lastSubmittedReport = DataReport(
      reportType: reportType,
      targetId: targetId,
      targetName: targetName,
      issueDescription: issueDescription,
      appVersion: appVersion,
      contextData: contextData,
      timestamp: DateTime.now(),
    );
    return shouldSucceed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Caches and retrieves Emergency Contacts offline', () async {
      final cacheService = CacheService();
      final sampleContacts = [
        const EmergencyContact(
          id: 'c1',
          agencyName: 'Test Agency',
          agencyShort: 'TA',
          coverageArea: 'Luzon',
          phoneNumber: '09123456789',
          displayNumber: '0912-345-6789',
          description: 'Emergency assistance',
        ),
      ];

      await cacheService.saveEmergencyContacts(sampleContacts);
      final retrieved = await cacheService.getEmergencyContacts();

      expect(retrieved, isNotNull);
      expect(retrieved!.length, 1);
      expect(retrieved.first.id, 'c1');
      expect(retrieved.first.agencyName, 'Test Agency');
    });

    test('Caches and retrieves Routes & Toll Segments offline', () async {
      final cacheService = CacheService();
      const sampleRoutes = [
        RouteModel(
          id: 'r1',
          name: 'North Corridor',
          origin: 'Plaza A',
          destination: 'Plaza B',
          segmentIds: ['s1'],
        ),
      ];

      final sampleSegments = [
        TollSegment(
          id: 's1',
          expressway: 'NLEX',
          expresswayName: 'North Luzon Expressway',
          operator: 'easytrip',
          entryPoint: 'Plaza A',
          exitPoint: 'Plaza B',
          fareClass1: 100,
          fareClass2: 200,
          fareClass3: 300,
          lastUpdated: DateTime(2025, 1, 1),
          lastVerified: DateTime(2025, 1, 1),
        ),
      ];

      await cacheService.saveRoutes(sampleRoutes);
      await cacheService.saveRouteSegments('r1', sampleSegments);

      final cachedRoutes = await cacheService.getRoutes();
      final cachedSegments = await cacheService.getRouteSegments('r1');

      expect(cachedRoutes, isNotNull);
      expect(cachedRoutes!.first.name, 'North Corridor');
      expect(cachedSegments, isNotNull);
      expect(cachedSegments!.first.fareClass1, 100);
      expect(cachedSegments.first.isVerified, isTrue);
    });

    test('Caches and retrieves Guide Entries offline', () async {
      final cacheService = CacheService();
      final sampleEntries = [
        GuideEntry(
          id: 'g1',
          title: 'RFID Troubleshooting',
          shortTitle: 'RFID',
          category: 'rfid',
          content: 'Keep calm and contact teller',
          lastUpdated: DateTime(2025, 1, 1),
        ),
      ];

      await cacheService.saveGuideEntries(sampleEntries);
      final retrieved = await cacheService.getGuideEntries();

      expect(retrieved, isNotNull);
      expect(retrieved!.first.title, 'RFID Troubleshooting');
    });

    test('Caches and retrieves last trip calculation', () async {
      final cacheService = CacheService();
      await cacheService.saveLastTripCalculation(
        routeId: 'r1',
        vehicleClass: 1,
        totalFare: 135.0,
        fareByOperator: {'autosweep': 50.0, 'easytrip': 85.0},
      );

      final lastTrip = await cacheService.getLastTripCalculation();
      expect(lastTrip, isNotNull);
      expect(lastTrip!['routeId'], 'r1');
      expect(lastTrip['totalFare'], 135.0);
    });
  });

  group('DataReport Model and ReportDialog Widget Tests', () {
    test('DataReport serializes correctly to Firestore map', () {
      final report = DataReport(
        reportType: 'toll_fare',
        targetId: 'route_1',
        targetName: 'Metro Corridor',
        issueDescription: 'Fare changed to 150',
        timestamp: DateTime(2025, 2, 1),
        contextData: {'fare': 150},
      );

      final map = report.toFirestore();
      expect(map['reportType'], 'toll_fare');
      expect(map['targetName'], 'Metro Corridor');
      expect(map['issueDescription'], 'Fare changed to 150');
      expect(map.containsKey('status'), isFalse);
      expect(map.containsKey('timestamp'), isTrue);
    });

    testWidgets('ReportDialog opens, accepts input, and submits report',
        (WidgetTester tester) async {
      final mockService = MockReportService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ReportDialog.show(
                  context,
                  reportType: 'emergency_contact',
                  targetId: 'c1',
                  targetName: 'MMDA Hotline',
                  contextData: {'number': '136'},
                  reportService: mockService,
                ),
                child: const Text('Open Report'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();

      expect(find.text('Report Incorrect Info'), findsOneWidget);
      expect(find.text('MMDA Hotline'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Hotline is currently 136, not 000-000-0000',
      );

      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      expect(mockService.lastSubmittedReport, isNotNull);
      expect(mockService.lastSubmittedReport!.reportType, 'emergency_contact');
      expect(mockService.lastSubmittedReport!.issueDescription,
          'Hotline is currently 136, not 000-000-0000');
      expect(find.text("Thanks, we'll review this."), findsOneWidget);
    });

    testWidgets('AeroOfflineBanner renders with custom message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AeroOfflineBanner(
              message: 'Offline — showing saved emergency contacts',
            ),
          ),
        ),
      );

      expect(
        find.text('Offline — showing saved emergency contacts'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });
}
