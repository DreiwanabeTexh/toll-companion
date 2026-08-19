import 'package:flutter/material.dart';

/// Aero Design System Tokens (Authoritative Reference: Aero Nocturnal Command)
class AeroColors {
  // Surface Tiers
  static const Color surfaceBase = Color(0xFF0A0A0A);
  static const Color surfaceDim = Color(0xFF121414);
  static const Color surfaceContainerLow = Color(0xFF1B1C1C);
  static const Color surfaceContainer = Color(0xFF1F2020);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color surfaceContainerHighest = Color(0xFF343535);

  // Border & Outlines
  static const Color border = Color(0xFF2A2A2A);
  static const Color outlineVariant = Color(0xFF404754);

  // Primary & Electric Blue Accents
  static const Color neonBlue = Color(0xFF0088FF);
  static const Color primaryTint = Color(0xFFA8C8FF);
  static const Color primaryContainer = Color(0xFF002955);

  // Semantic Status Colors
  static const Color successEmerald = Color(0xFF34D399);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color secondaryOrange = Color(0xFFFF9800);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color errorRed = Color(0xFFFF5252);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A919F);
  static const Color textMuted = Color(0xFFC0C6D6);
}

/// Aero Typography Scale (Refined for balanced, confident automotive ergonomics)
class AeroTypography {
  // Balanced monetary display (Balances on Home & Estimated Fare on Tolls: 36px)
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AeroColors.neonBlue,
    letterSpacing: -0.02,
    height: 1.15,
  );

  // Total Fare Display on Toll Calculator: 34px
  static const TextStyle displayFare = TextStyle(
    fontFamily: 'Inter',
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: AeroColors.neonBlue,
    letterSpacing: -0.02,
    height: 1.15,
  );

  // Large Hero Heading for Emergency & Quick Guide: 36px
  static const TextStyle displayHero = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AeroColors.textPrimary,
    letterSpacing: -0.02,
    height: 1.15,
  );

  // Trip Details Heading on Toll Calculator: 32px
  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AeroColors.textPrimary,
    letterSpacing: -0.01,
  );

  // "Hello, Driver" Heading on Home AppBar: 24px
  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AeroColors.textPrimary,
    letterSpacing: -0.01,
  );

  // Section titles and card headers: 20px
  static const TextStyle titleMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AeroColors.textPrimary,
  );

  // Unified Tier 1 Status Pill Text (Tolls, Emergency, Guide): 13.5px
  static const TextStyle tier1PillText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AeroColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AeroColors.textMuted,
    height: 1.4,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AeroColors.textSecondary,
    height: 1.35,
  );

  static const TextStyle labelCaps = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AeroColors.textSecondary,
    letterSpacing: 0.8,
  );
}

/// Common Visual Effects
class AeroGlow {
  static List<BoxShadow> neonBlueGlow = [
    BoxShadow(
      color: const Color(0xFF0088FF).withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> subtleCardGlow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
