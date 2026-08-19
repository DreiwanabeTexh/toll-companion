import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/app.dart';

void main() {
  testWidgets('App smoke test - verifies HomeScreen title and navigation cards',
      (WidgetTester tester) async {
    // Build the app shell with a comfortable test window size
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TollCompanionApp());
    await tester.pumpAndSettle();

    // Verify app bar title and 5 feature cards
    expect(find.text('PH Expressway Companion'), findsOneWidget);
    expect(find.text('Toll Calculator'), findsOneWidget);
    expect(find.text('Pre-Trip Checklist'), findsOneWidget);
    expect(find.text('Route Briefing'), findsOneWidget);
    expect(find.text('Quick Guide'), findsOneWidget);
    expect(find.text('Emergency Contacts'), findsOneWidget);
  });
}
