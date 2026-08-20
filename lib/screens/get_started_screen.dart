import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import 'name_input_screen.dart';

/// First-run Get Started introduction screen.
///
/// Features:
/// - Prominent expressway skyway illustration (`assets/images/get_started_illustration.png`)
/// - Clear, confident value proposition describing Aero's toll, safety, and route intelligence
/// - "Get Started" action button leading to the required [NameInputScreen]
class GetStartedScreen extends StatelessWidget {
  final CacheService? cacheService;

  const GetStartedScreen({super.key, this.cacheService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Small Brand Tag
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AeroColors.neonBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AeroColors.neonBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flight_takeoff, size: 14, color: AeroColors.neonBlue),
                        SizedBox(width: 6),
                        Text(
                          'AERO EXPRESSWAY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AeroColors.neonBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Main Headline
              Text(
                'Drive Philippine Expressways with Confidence',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: AeroColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline Explanatory Text
              // Copy Option 1 (Default): "Your companion for every PH expressway trip — tolls, safety, and peace of mind."
              Text(
                'Your companion for every PH expressway trip — tolls, safety, and peace of mind.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AeroColors.textSecondary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 16),

              // Prominent Expressway Illustration Container
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AeroColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AeroColors.border,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AeroColors.neonBlue.withValues(alpha: 0.10),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Get Started Illustration Image Asset
                        Image.asset(
                          'assets/images/get_started_illustration.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/get_started_illustration.jpeg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AeroColors.surfaceContainerLow,
                                  child: Center(
                                    child: Icon(
                                      Icons.add_road_rounded,
                                      size: 72,
                                      color: AeroColors.neonBlue,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // Subtle bottom gradient overlay for smooth contrast
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AeroColors.surfaceBase.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Feature Highlights Row
              Row(
                children: [
                  _buildFeatureBadge(Icons.account_balance_wallet_outlined, 'RFID Tracking'),
                  const SizedBox(width: 8),
                  _buildFeatureBadge(Icons.phone_in_talk_outlined, '24/7 Hotlines'),
                  const SizedBox(width: 8),
                  _buildFeatureBadge(Icons.alt_route_rounded, 'Trip Fares'),
                ],
              ),

              const SizedBox(height: 20),

              // "Get Started" CTA Button
              SizedBox(
                width: double.infinity,
                child: AeroBouncyTap(
                  scaleDown: 0.97,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NameInputScreen(
                            cacheService: cacheService,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AeroColors.neonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: AeroColors.neonBlue.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AeroColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AeroColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AeroColors.neonBlue),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AeroColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
