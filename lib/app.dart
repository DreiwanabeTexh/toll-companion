import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/toll_calculator_screen.dart';
import 'screens/quick_guide_screen.dart';
import 'screens/guide_detail_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/route_briefing_screen.dart';

/// Root Application Widget configuring theme and top-level routing.
///
/// Implements the authoritative "Nocturnal Command" design system:
/// - Dark canvas background: #0A0A0A
/// - Surface Level 2 cards: #1A1A1A with #2A2A2A border
/// - Action accent: Electric Blue #0088FF
class TollCompanionApp extends StatelessWidget {
  const TollCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PH Expressway Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0088FF),
          onPrimary: Color(0xFF003061),
          primaryContainer: Color(0xFF002955),
          secondary: Color(0xFFFFA000),
          surface: Color(0xFF141414),
          onSurface: Color(0xFFE3E2E2),
          onSurfaceVariant: Color(0xFF8A919F),
          error: Color(0xFFFF5252),
          outline: Color(0xFF2A2A2A),
          outlineVariant: Color(0xFF343535),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141414),
          foregroundColor: Color(0xFFE3E2E2),
          elevation: 0,
          centerTitle: false,
          shape: Border(
            bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
        ),
        dividerColor: const Color(0xFF2A2A2A),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0088FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0088FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141414),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0088FF), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF8A919F)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
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
