import 'package:flutter/material.dart';
import 'screens/main_navigation_scaffold.dart';
import 'screens/toll_calculator_screen.dart';
import 'screens/quick_guide_screen.dart';
import 'screens/guide_detail_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/route_briefing_screen.dart';
import 'theme.dart';

/// Root Application Widget for Aero — Philippine Expressway Companion.
///
/// Implements the Aero Nocturnal Command design system:
/// - Dark canvas background: #0A0A0A
/// - Surface cards: #1A1A1A with #2A2A2A border
/// - Action accent: Electric Blue #0088FF
/// - Persistent Bottom Navigation: Home, Tolls, Emergency, Guide
class TollCompanionApp extends StatelessWidget {
  const TollCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aero - Expressway Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: AeroColors.surfaceBase,
        colorScheme: const ColorScheme.dark(
          primary: AeroColors.neonBlue,
          onPrimary: Colors.white,
          primaryContainer: AeroColors.primaryContainer,
          secondary: AeroColors.warningAmber,
          surface: AeroColors.surfaceDim,
          onSurface: AeroColors.textPrimary,
          onSurfaceVariant: AeroColors.textSecondary,
          error: AeroColors.errorRed,
          outline: AeroColors.border,
          outlineVariant: AeroColors.outlineVariant,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AeroColors.surfaceBase,
          foregroundColor: AeroColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          shape: Border(
            bottom: BorderSide(color: AeroColors.border, width: 1),
          ),
        ),
        cardTheme: CardThemeData(
          color: AeroColors.surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AeroColors.border, width: 1),
          ),
        ),
        dividerColor: AeroColors.border,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AeroColors.neonBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AeroColors.neonBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AeroColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AeroColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AeroColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AeroColors.neonBlue, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AeroColors.textSecondary),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScaffold(),
        '/toll-calculator': (context) => const TollCalculatorScreen(),
        '/checklist': (context) => const ChecklistScreen(),
        '/route-briefing': (context) => const RouteBriefingScreen(),
        '/quick-guide': (context) => const QuickGuideScreen(),
        '/guide-detail': (context) => const GuideDetailScreen(),
        '/emergency-contacts': (context) => const EmergencyContactsScreen(),
      },
    );
  }
}
