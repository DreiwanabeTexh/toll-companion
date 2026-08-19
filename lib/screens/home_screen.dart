import 'package:flutter/material.dart';

/// Home hub screen displaying navigation cards for Phase 1 and Phase 2 features.
///
/// Designed with the Nocturnal Command visual system:
/// - Dark canvas background (#0A0A0A)
/// - Card surfaces (#1A1A1A with #2A2A2A border)
/// - High-contrast glanceable layout for drivers
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_car_filled, color: Color(0xFF0088FF), size: 22),
            SizedBox(width: 10),
            Text('PH Expressway Companion'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0, top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DRIVING DASHBOARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0088FF),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Expressway Companion',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE3E2E2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-operator toll planning, readiness checks, and route guidance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          _FeatureCard(
            title: 'Toll Calculator',
            subtitle: 'Route builder with Autosweep vs. Easytrip RFID fare breakdown.',
            icon: Icons.calculate_outlined,
            iconColor: const Color(0xFF0088FF),
            badgeText: 'FARES',
            onTap: () => Navigator.pushNamed(context, '/toll-calculator'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: 'Pre-Trip Checklist',
            subtitle: 'Readiness checklist for RFID balances, tires, fluids, and docs.',
            icon: Icons.checklist_rtl,
            iconColor: const Color(0xFF00CC88),
            badgeText: 'PHASE 2',
            onTap: () => Navigator.pushNamed(context, '/checklist'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: 'Route Briefing',
            subtitle: 'Lane positioning tips, rest stop plazas, and fork warnings.',
            icon: Icons.alt_route,
            iconColor: const Color(0xFF3491FF),
            badgeText: 'PHASE 2',
            onTap: () => Navigator.pushNamed(context, '/route-briefing'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: 'Quick Guide',
            subtitle: 'What to do during RFID issues, breakdowns, and wrong exits.',
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFFFFA000),
            onTap: () => Navigator.pushNamed(context, '/quick-guide'),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            title: 'Emergency Contacts',
            subtitle: 'Official expressway hotlines (Tier 1) with tap-to-call.',
            icon: Icons.emergency_outlined,
            iconColor: const Color(0xFFFF5252),
            badgeText: 'TIER 1',
            onTap: () => Navigator.pushNamed(context, '/emergency-contacts'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Designed for Philippine Expressway Drivers',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE3E2E2),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: iconColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A919F),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF8A919F), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
