import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/models/emergency_contact.dart';
import 'package:toll_companion/models/guide_entry.dart';
import 'package:toll_companion/models/route_model.dart';
import 'package:toll_companion/screens/main_navigation_scaffold.dart';
import 'package:toll_companion/screens/toll_calculator_screen.dart';
import 'package:toll_companion/screens/emergency_contacts_screen.dart';
import 'package:toll_companion/screens/quick_guide_screen.dart';
import 'package:toll_companion/services/contacts_service.dart';
import 'package:toll_companion/services/guide_service.dart';
import 'package:toll_companion/services/toll_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/models/toll_plaza.dart';
import 'package:toll_companion/widgets/aero_mascot.dart';

class MockTollService extends TollService {
  @override
  Stream<List<RouteModel>> getActiveRoutes() => Stream.value([]);

  @override
  Stream<List<TollPlaza>> getActivePlazas() => Stream.value(TollService.defaultPlazas);
}

class MockContactsService extends ContactsService {
  @override
  Stream<List<EmergencyContact>> getEmergencyContacts() => Stream.value([]);
}

class MockGuideService extends GuideService {
  @override
  Stream<List<GuideEntry>> getGuideEntries() => Stream.value([]);
}

void main() {
  testWidgets(
      'Aero smoke test - verifies branding, dashboard, and bottom navigation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScaffold(
          tollService: MockTollService(),
          contactsService: MockContactsService(),
          guideService: MockGuideService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home Top App Bar
    expect(find.text('Hello, Driver'), findsOneWidget);

    // Verify Dashboard Sections
    expect(find.text('AERO CO-PILOT READY'), findsOneWidget);
    expect(find.text('Expressway Radar Active'), findsOneWidget);
    expect(find.text('Toll Balances'), findsOneWidget);
    expect(find.text('AUTOSWEEP RFID'), findsOneWidget);
    expect(find.text('EASYTRIP RFID'), findsOneWidget);
    expect(find.text('Recent Routes'), findsOneWidget);
    expect(find.text('No routes calculated yet'), findsOneWidget);

    // Verify Bottom Navigation Bar Tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tolls'), findsOneWidget);
    expect(find.text('Emergency'), findsWidgets);
    expect(find.text('Guide'), findsOneWidget);

    // Switch to Tolls Tab
    await tester.tap(find.byIcon(Icons.payments));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TollCalculatorScreen), findsOneWidget);

    // Switch to Emergency Tab
    await tester.tap(find.byIcon(Icons.emergency));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EmergencyContactsScreen), findsOneWidget);

    // Switch to Guide Tab
    await tester.tap(find.byIcon(Icons.explore));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(QuickGuideScreen), findsOneWidget);
    expect(find.byType(AeroSpeechBubble), findsOneWidget);
  });
}

