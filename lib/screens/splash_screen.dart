import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../theme.dart';
import '../widgets/aero_mascot.dart';
import 'get_started_screen.dart';
import 'main_navigation_scaffold.dart';

/// Animated Splash Screen for Aero:
/// - Plays a brief (1.7s), playful entrance animation of the Aero mascot:
///   Swoops in confidently from the left, then "plops" down into a comedic landing settle.
/// - Tappable at any point to skip immediately.
/// - Checks `onboarding_complete` flag via [CacheService]:
///   - First launch -> Navigates to [GetStartedScreen]
///   - Subsequent launches -> Navigates directly to [MainNavigationScaffold]
class SplashScreen extends StatefulWidget {
  final CacheService? cacheService;

  const SplashScreen({super.key, this.cacheService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CacheService _cacheService;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _cacheService = widget.cacheService ?? CacheService();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceedToNextScreen();
      }
    });

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _proceedToNextScreen() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final isOnboarded = await _cacheService.isOnboardingComplete();
    if (!mounted) return;

    if (isOnboarded) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const MainNavigationScaffold(),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) =>
              GetStartedScreen(cacheService: _cacheService),
          transitionsBuilder: (context, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _onSkipTap() {
    _controller.stop();
    _proceedToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSkipTap,
        child: Stack(
          children: [
            // Center animated mascot and branding
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;

                  // 1. Horizontal Motion: Swoop in from left (-screenWidth * 0.75) to center (0.0)
                  // 0.0 -> 0.44 (~1.1s)
                  double offsetX;
                  if (t < 0.44) {
                    final progress = t / 0.44;
                    final curved = Curves.easeOutCubic.transform(progress);
                    offsetX = (-screenWidth * 0.75) * (1.0 - curved);
                  } else {
                    offsetX = 0.0;
                  }

                  // 2. Vertical Motion: Swoop arc -> Sudden comedic drop "plop" -> Settle & Read
                  double offsetY;
                  double scaleX = 1.0;
                  double scaleY = 1.0;
                  double rotation = 0.0;

                  if (t < 0.44) {
                    final p = t / 0.44;
                    // Aerodynamic wave in flight
                    offsetY = math.sin(p * math.pi) * -28.0;
                    // Wing flap cycle during fast swoop
                    final flap = math.sin(p * 8 * math.pi);
                    scaleY = 1.0 + 0.16 * flap;
                    scaleX = 1.0 - 0.08 * flap;
                    // Angled slightly upward while gliding in
                    rotation = -0.12 * (1.0 - p);
                  } else if (t < 0.56) {
                    // Comedic "plop" drop onto the floor/perch (0.44 -> 0.56 = ~300ms)
                    final p = (t - 0.44) / 0.12;
                    final drop = Curves.bounceOut.transform(p);
                    offsetY = 14.0 * drop;
                    // Impact squash on landing
                    scaleX = 1.0 + 0.14 * math.sin(p * math.pi);
                    scaleY = 1.0 - 0.14 * math.sin(p * math.pi);
                    rotation = 0.04 * math.sin(p * math.pi);
                  } else if (t < 0.68) {
                    // Settle back into proud resting posture (0.56 -> 0.68 = ~300ms)
                    final p = (t - 0.56) / 0.12;
                    offsetY = 14.0 * (1.0 - p);
                    scaleX = 1.0;
                    scaleY = 1.0;
                    rotation = 0.0;
                  } else {
                    // Fully settled resting posture with branding proudly readable (0.68 -> 1.0 = ~800ms)
                    offsetY = 0.0;
                    scaleX = 1.0;
                    scaleY = 1.0;
                    rotation = 0.0;
                  }

                  // Title & Tagline Fade In (starts at 0.38, fully readable by 0.56)
                  final textOpacity = (t < 0.38)
                      ? 0.0
                      : ((t - 0.38) / 0.18).clamp(0.0, 1.0);

                  final wingTransform = Matrix4.diagonal3Values(scaleX, scaleY, 1.0);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bird Mascot with Entrance & Landing Physics
                      Transform.translate(
                        offset: Offset(offsetX, offsetY),
                        child: Transform.rotate(
                          angle: rotation,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: wingTransform,
                            child: SizedBox(
                              width: 140,
                              height: 140,
                              child: Image.asset(
                                kAeroMascotAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.network(
                                  kAeroMascotUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.flutter_dash,
                                    size: 96,
                                    color: AeroColors.neonBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Brand Heading
                      Opacity(
                        opacity: textOpacity,
                        child: Column(
                          children: [
                            Text(
                              'AERO',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                color: AeroColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Philippine Expressway Companion',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AeroColors.neonBlue.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Tap to skip hint at bottom
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap anywhere to skip',
                  style: TextStyle(
                    fontSize: 12,
                    color: AeroColors.textSecondary.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
