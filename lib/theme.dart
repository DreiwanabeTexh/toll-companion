import 'package:flutter/material.dart';

/// Aero Design System Tokens with Dual Theme Support (Nocturnal Command & Solar Lumina)
class AeroColors {
  static bool _isLight = false;

  /// Whether Light Mode is currently active
  static bool get isLight => _isLight;

  /// Whether Dark Mode is currently active
  static bool get isDark => !_isLight;

  /// ValueNotifier to broadcast theme changes across the app
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// Change theme mode programmatically
  static void setThemeMode(ThemeMode mode) {
    _isLight = (mode == ThemeMode.light);
    themeModeNotifier.value = mode;
  }

  // --- Dark Palette Tokens (Nocturnal Command) ---
  static const Color _darkSurfaceBase = Color(0xFF0A0A0A);
  static const Color _darkSurfaceDim = Color(0xFF121414);
  static const Color _darkSurfaceContainerLow = Color(0xFF1B1C1C);
  static const Color _darkSurfaceContainer = Color(0xFF1F2020);
  static const Color _darkSurfaceCard = Color(0xFF1A1A1A);
  static const Color _darkSurfaceContainerHighest = Color(0xFF343535);

  static const Color _darkBorder = Color(0xFF2A2A2A);
  static const Color _darkOutlineVariant = Color(0xFF404754);

  static const Color _darkNeonBlue = Color(0xFF0088FF);
  static const Color _darkPrimaryTint = Color(0xFFA8C8FF);
  static const Color _darkPrimaryContainer = Color(0xFF002955);

  static const Color _darkTextPrimary = Color(0xFFFFFFFF);
  static const Color _darkTextSecondary = Color(0xFF8A919F);
  static const Color _darkTextMuted = Color(0xFFC0C6D6);

  // --- Light Palette Tokens (Solar Lumina) ---
  static const Color _lightSurfaceBase = Color(0xFFF6F8FA);
  static const Color _lightSurfaceDim = Color(0xFFEDF2F7);
  static const Color _lightSurfaceContainerLow = Color(0xFFF1F5F9);
  static const Color _lightSurfaceContainer = Color(0xFFE2E8F0);
  static const Color _lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color _lightSurfaceContainerHighest = Color(0xFFCBD5E1);

  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightOutlineVariant = Color(0xFF94A3B8);

  static const Color _lightNeonBlue = Color(0xFF0070F3);
  static const Color _lightPrimaryTint = Color(0xFF0052CC);
  static const Color _lightPrimaryContainer = Color(0xFFE0EFFF);

  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);
  static const Color _lightTextMuted = Color(0xFF475569);

  // --- Dynamic Surface Colors ---
  static Color get surfaceBase => _isLight ? _lightSurfaceBase : _darkSurfaceBase;
  static Color get surfaceDim => _isLight ? _lightSurfaceDim : _darkSurfaceDim;
  static Color get surfaceContainerLow =>
      _isLight ? _lightSurfaceContainerLow : _darkSurfaceContainerLow;
  static Color get surfaceContainer =>
      _isLight ? _lightSurfaceContainer : _darkSurfaceContainer;
  static Color get surfaceCard => _isLight ? _lightSurfaceCard : _darkSurfaceCard;
  static Color get surfaceContainerHighest =>
      _isLight ? _lightSurfaceContainerHighest : _darkSurfaceContainerHighest;

  // --- Dynamic Border & Outlines ---
  static Color get border => _isLight ? _lightBorder : _darkBorder;
  static Color get outlineVariant =>
      _isLight ? _lightOutlineVariant : _darkOutlineVariant;

  // --- Dynamic Primary Accents ---
  static Color get neonBlue => _isLight ? _lightNeonBlue : _darkNeonBlue;
  static Color get primaryTint => _isLight ? _lightPrimaryTint : _darkPrimaryTint;
  static Color get primaryContainer =>
      _isLight ? _lightPrimaryContainer : _darkPrimaryContainer;

  // --- Semantic Status Colors (Universal High-Contrast) ---
  static const Color successEmerald = Color(0xFF10B981);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // --- Dynamic Text Colors ---
  static Color get textPrimary => _isLight ? _lightTextPrimary : _darkTextPrimary;
  static Color get textSecondary =>
      _isLight ? _lightTextSecondary : _darkTextSecondary;
  static Color get textMuted => _isLight ? _lightTextMuted : _darkTextMuted;
}

/// Aero Typography Scale (Dynamically adapts to active Light/Dark theme)
class AeroTypography {
  static TextStyle get displayLg => TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AeroColors.neonBlue,
        letterSpacing: -0.02,
        height: 1.15,
      );

  static TextStyle get displayFare => TextStyle(
        fontFamily: 'Inter',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AeroColors.neonBlue,
        letterSpacing: -0.02,
        height: 1.15,
      );

  static TextStyle get displayHero => TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AeroColors.textPrimary,
        letterSpacing: -0.02,
        height: 1.15,
      );

  static TextStyle get headlineLg => TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AeroColors.textPrimary,
        letterSpacing: -0.01,
      );

  static TextStyle get headlineLgMobile => TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AeroColors.textPrimary,
        letterSpacing: -0.01,
      );

  static TextStyle get titleMd => TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AeroColors.textPrimary,
      );

  static TextStyle get tier1PillText => TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AeroColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get bodyLg => TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AeroColors.textMuted,
        height: 1.4,
      );

  static TextStyle get bodySm => TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AeroColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get labelCaps => TextStyle(
        fontFamily: 'Inter',
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AeroColors.textSecondary,
        letterSpacing: 0.8,
      );
}

/// Aero Visual Effects (Shadows and Glows)
class AeroGlow {
  static List<BoxShadow> get neonBlueGlow => [
        BoxShadow(
          color: AeroColors.neonBlue.withValues(alpha: AeroColors.isLight ? 0.2 : 0.4),
          blurRadius: AeroColors.isLight ? 12 : 20,
          spreadRadius: AeroColors.isLight ? 1 : 2,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get subtleCardGlow => [
        BoxShadow(
          color: AeroColors.isLight
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.5),
          blurRadius: AeroColors.isLight ? 8 : 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Complete Material 3 Theme Definitions for Aero
class AeroTheme {
  static ThemeData get darkTheme => ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0088FF),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF002955),
          secondary: Color(0xFFFBBF24),
          surface: Color(0xFF121414),
          onSurface: Color(0xFFFFFFFF),
          onSurfaceVariant: Color(0xFF8A919F),
          error: Color(0xFFFF5252),
          outline: Color(0xFF2A2A2A),
          outlineVariant: Color(0xFF404754),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          foregroundColor: Color(0xFFFFFFFF),
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
          fillColor: const Color(0xFF1B1C1C),
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
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1F2020),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          actionTextColor: const Color(0xFF0088FF),
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0070F3),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFE0EFFF),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFFEDF2F7),
          onSurface: Color(0xFF0F172A),
          onSurfaceVariant: Color(0xFF64748B),
          error: Color(0xFFEF4444),
          outline: Color(0xFFE2E8F0),
          outlineVariant: Color(0xFF94A3B8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F8FA),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: false,
          shape: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        dividerColor: const Color(0xFFE2E8F0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0070F3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0070F3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0070F3), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
          actionTextColor: const Color(0xFF0070F3),
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
        ),
      );
}
