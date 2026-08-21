import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toll_companion/theme.dart';
import 'package:toll_companion/widgets/aero_snackbar.dart';

void main() {
  group('AeroSnackBar High-Contrast Tests', () {
    testWidgets('Shows readable high-contrast success SnackBar in Light Mode', (tester) async {
      AeroColors.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AeroSnackBar.showSuccess(context, 'Driver name updated to Captain Juan');
                },
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      expect(find.text('Driver name updated to Captain Juan'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFF1E293B)); // Dark slate background in Light Mode

      final text = tester.widget<Text>(find.text('Driver name updated to Captain Juan'));
      expect(text.style?.color, Colors.white); // Pure white high-contrast text
    });

    testWidgets('Shows readable high-contrast success SnackBar in Dark Mode', (tester) async {
      AeroColors.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AeroSnackBar.showSuccess(context, 'Driver name updated to Captain Juan');
                },
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      expect(find.text('Driver name updated to Captain Juan'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFF1F2020)); // Charcoal container background in Dark Mode

      final text = tester.widget<Text>(find.text('Driver name updated to Captain Juan'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('Shows readable high-contrast error and info SnackBars', (tester) async {
      AeroColors.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AeroSnackBar.showError(context, 'Error occurred'),
                    child: const Text('Show Error'),
                  ),
                  ElevatedButton(
                    onPressed: () => AeroSnackBar.showInfo(context, 'Info notice'),
                    child: const Text('Show Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();
      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Show Info'));
      await tester.pumpAndSettle();
      expect(find.text('Info notice'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
