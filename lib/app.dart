import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/name_input_screen.dart';
import 'screens/main_navigation_scaffold.dart';
import 'screens/toll_calculator_screen.dart';
import 'screens/quick_guide_screen.dart';
import 'screens/guide_detail_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/route_briefing_screen.dart';
import 'services/cache_service.dart';
import 'theme.dart';

/// Root Application Widget for Aero — Philippine Expressway Companion.
///
/// Implements dual theme capability (Nocturnal Command Dark & Solar Lumina Light):
/// - Persistent ThemeMode managed via AeroColors.themeModeNotifier
/// - Saved locally via CacheService
/// - Persistent Bottom Navigation: Home, Tolls, Emergency, Guide
class TollCompanionApp extends StatefulWidget {
  const TollCompanionApp({super.key});

  @override
  State<TollCompanionApp> createState() => _TollCompanionAppState();
}

class _TollCompanionAppState extends State<TollCompanionApp> {
  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final cacheService = CacheService();
    final modeStr = await cacheService.getThemeMode();
    if (modeStr == 'light') {
      AeroColors.setThemeMode(ThemeMode.light);
    } else {
      AeroColors.setThemeMode(ThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AeroColors.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Aero - Expressway Companion',
          debugShowCheckedModeBanner: false,
          theme: AeroTheme.lightTheme,
          darkTheme: AeroTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/get-started': (context) => const GetStartedScreen(),
            '/name-input': (context) => const NameInputScreen(),
            '/': (context) => const MainNavigationScaffold(),
            '/home': (context) => const MainNavigationScaffold(),
            '/toll-calculator': (context) => const TollCalculatorScreen(),
            '/checklist': (context) => const ChecklistScreen(),
            '/route-briefing': (context) => const RouteBriefingScreen(),
            '/quick-guide': (context) => const QuickGuideScreen(),
            '/guide-detail': (context) => const GuideDetailScreen(),
            '/emergency-contacts': (context) => const EmergencyContactsScreen(),
          },
        );
      },
    );
  }
}
