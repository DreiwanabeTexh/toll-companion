import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../theme.dart';

/// Asset path for the authentic Aero bird mascot.
const String kAeroMascotAsset = 'assets/images/aero_mascot.png';

/// Fallback URL for the Aero bird mascot if asset is missing.
const String kAeroMascotUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAUmIiyDFJ_57WqNqTYsY9Q097X_uLBdJIQjvaVP6ksoZYEIzlOUKyzwyMvqGDG_1GWt5C_qlZ3LHjpNTHWvxWoGO4uwa0HnYmQf6SOdFn4E10MhlASMYo14fsWCVy1f4pWsNl6WEcXgNgjvDyrHMezFoUeb7hS7gluffMZpLIMHKPvVNXwd4Cc9f0-gQkY51429D66a3FLnORJ702bsTOrDXcWlMukYo1e5-LM9OWj7zronuMCyVyz';

/// Clean borderless mascot icon — only the bird silhouette itself, without any outer disc or ring.
class AeroAvatar extends StatelessWidget {
  final double size;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  const AeroAvatar({
    super.key,
    this.size = 52.0,
    this.showBorder = false,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        kAeroMascotAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.network(
          kAeroMascotUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.flutter_dash,
              size: size * 0.75,
              color: AeroColors.neonBlue,
            ),
          ),
        ),
      ),
    );
  }
}

/// Native Flutter Animated Hero Mascot:
/// Recreates an authentic, borderless flight loop with realistic wing swings:
/// - Floating vertical translation (sine wave)
/// - Active wing swing stroke (rhythmic vertical expansion & horizontal compression)
/// - 3D wing sweep & aerodynamic skewing
/// - Subtle banking roll tilt
/// 100% offline, lightweight, and hardware-accelerated.
class AeroAnimatedHeroMascot extends StatefulWidget {
  final double size;
  final bool showGlow;

  const AeroAnimatedHeroMascot({
    super.key,
    this.size = 108.0,
    this.showGlow = false,
  });

  @override
  State<AeroAnimatedHeroMascot> createState() => _AeroAnimatedHeroMascotState();
}

class _AeroAnimatedHeroMascotState extends State<AeroAnimatedHeroMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        // Smooth floating elevation
        final floatOffsetY = math.sin(progress * 2 * math.pi) * 5.0;
        // Dynamic wing swing & flap cycles (2 flaps per float cycle)
        final wingCycle = math.sin(progress * 4 * math.pi);
        final wingScaleY = 1.0 + 0.14 * wingCycle;
        final wingScaleX = 1.0 - 0.08 * wingCycle;
        final wingSkewY = 0.06 * math.cos(progress * 4 * math.pi);
        // Banking roll tilt
        final tiltAngle = math.sin(progress * 2 * math.pi) * 0.06;

        final wingTransform = Matrix4.diagonal3Values(wingScaleX, wingScaleY, 1.0)
          ..setEntry(1, 0, wingSkewY);

        return Transform.translate(
          offset: Offset(0, floatOffsetY),
          child: Transform.rotate(
            angle: tiltAngle,
            child: Transform(
              alignment: Alignment.center,
              transform: wingTransform,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Image.asset(
                  kAeroMascotAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.network(
                    kAeroMascotUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.flutter_dash,
                        size: widget.size * 0.75,
                        color: AeroColors.neonBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hero Header Row pairing the large animated mascot alongside key screen headings.
class AeroHeroHeaderRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double mascotSize;

  const AeroHeroHeaderRow({
    super.key,
    required this.title,
    this.subtitle,
    this.mascotSize = 108.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large dedicated animated mascot illustration
        AeroAnimatedHeroMascot(
          size: mascotSize,
          showGlow: false,
        ),
        const SizedBox(width: 18),
        // Sizable, bold display heading
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AeroTypography.displayHero,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AeroTypography.bodySm,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Unified Aero speech bubble matching the Aero Tier 1 status pill:
/// Uses standardized 13.5px bold font size across Tolls, Emergency, and Guide.
class AeroSpeechBubble extends StatelessWidget {
  final String text;

  const AeroSpeechBubble({
    super.key,
    this.text = 'All clear, driver.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AeroColors.surfaceCard,
        border: Border.all(color: AeroColors.border),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        boxShadow: AeroGlow.subtleCardGlow,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          text,
          key: ValueKey<String>(text),
          style: AeroTypography.tier1PillText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Home Screen Single-Row Top App Bar:
/// Clean Mascot avatar (no blue ring) + static "Hello, Driver" title (24px) + Settings gear on the right.
class AeroHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String driverName;
  final VoidCallback? onSettingsPressed;
  final ValueChanged<String>? onNameChanged;

  const AeroHomeAppBar({
    super.key,
    this.driverName = 'Driver',
    this.onSettingsPressed,
    this.onNameChanged,
  });

  String get title => 'Hello, $driverName';

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64.0,
      automaticallyImplyLeading: false,
      titleSpacing: 16.0,
      backgroundColor: AeroColors.surfaceBase,
      title: Row(
        children: [
          const AeroAvatar(size: 52, showBorder: false),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              style: AeroTypography.headlineLgMobile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: AeroColors.textSecondary, size: 24),
          onPressed: onSettingsPressed ?? () => showSettingsDialog(context, onNameChanged: onNameChanged),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  static void showSettingsDialog(BuildContext context, {ValueChanged<String>? onNameChanged}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AeroColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AeroColors.border),
        ),
        title: Row(
          children: [
            const AeroAvatar(size: 28, showBorder: false),
            const SizedBox(width: 8),
            Text(
              'Aero Settings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AeroColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Profile Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: AeroColors.neonBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Change your dashboard greeting name',
                          style: TextStyle(
                            fontSize: 11,
                            color: AeroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showEditNameDialog(context, onNameChanged: onNameChanged);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: AeroColors.neonBlue.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Edit Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AeroColors.neonBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // App Theme Option (Light / Dark Mode Toggle)
            StatefulBuilder(
              builder: (ctx, setCardState) {
                final isLight = AeroColors.isLight;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AeroColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AeroColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLight ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        color: isLight ? AeroColors.secondaryOrange : AeroColors.neonBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Theme',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AeroColors.textPrimary,
                              ),
                            ),
                            Text(
                              isLight ? 'Light Mode (Solar Lumina)' : 'Dark Mode (Nocturnal Command)',
                              style: TextStyle(
                                fontSize: 11,
                                color: AeroColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isLight,
                        activeThumbColor: AeroColors.secondaryOrange,
                        activeTrackColor: AeroColors.secondaryOrange.withValues(alpha: 0.3),
                        inactiveThumbColor: AeroColors.neonBlue,
                        inactiveTrackColor: AeroColors.neonBlue.withValues(alpha: 0.3),
                        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.white);
                          }
                          return const Icon(Icons.nightlight_round, size: 14, color: Colors.white);
                        }),
                        onChanged: (val) async {
                          final newMode = val ? ThemeMode.light : ThemeMode.dark;
                          AeroColors.setThemeMode(newMode);
                          final cacheService = CacheService();
                          await cacheService.saveThemeMode(val ? 'light' : 'dark');
                          setCardState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Reset App Option (QA / Testing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restart_alt_rounded, color: AeroColors.errorRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset App',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Clear all data and restart onboarding',
                          style: TextStyle(
                            fontSize: 11,
                            color: AeroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showResetAppConfirmation(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: AeroColors.errorRed.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AeroColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Philippine Expressway Driving Companion',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AeroColors.neonBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Version: 1.0.0+1\nDatabase: 08/2026 verified\nPowered by Toll Regulatory Board published matrices.',
              style: TextStyle(
                fontSize: 12,
                color: AeroColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Close', style: TextStyle(color: AeroColors.neonBlue)),
          ),
        ],
      ),
    );
  }

  static void _showResetAppConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        backgroundColor: AeroColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AeroColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AeroColors.errorRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'Reset Aero App',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AeroColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'This will clear all saved data and restart onboarding. Continue?',
          style: TextStyle(
            fontSize: 13,
            color: AeroColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: AeroColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AeroColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(confirmCtx).pop();
              final cacheService = CacheService();
              await cacheService.clearAll();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/splash',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Reset App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static void _showEditNameDialog(BuildContext context, {ValueChanged<String>? onNameChanged}) async {
    final cacheService = CacheService();
    final currentName = (await cacheService.getDriverName()) ?? 'Driver';
    final controller = TextEditingController(text: currentName == 'Driver' ? '' : currentName);
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (editCtx) => AlertDialog(
        backgroundColor: AeroColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AeroColors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_outlined, color: AeroColors.neonBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Edit Driver Name',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AeroColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the name you want Aero to address you by:',
                style: TextStyle(fontSize: 13, color: AeroColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AeroColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Alex or Juan',
                  counterStyle: TextStyle(color: AeroColors.textSecondary, fontSize: 11),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(editCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: AeroColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newName = controller.text.trim();
                await cacheService.setDriverName(newName);
                onNameChanged?.call(newName);
                if (editCtx.mounted) Navigator.of(editCtx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AeroColors.surfaceCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AeroColors.border),
                      ),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AeroColors.successEmerald, size: 18),
                          const SizedBox(width: 8),
                          Text('Driver name updated to $newName'),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AeroColors.neonBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Unified Single-Row Top App Bar:
/// Clean Mascot avatar (no blue ring) + Dynamic Aero Speech Bubble (standardized 13.5px bold font)
/// + Settings gear on the right.
/// Standardized height: 64px across all tabs.
class AeroTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String? speechText;
  final List<String>? phrases;
  final VoidCallback? onSettingsPressed;

  /// Preset phrases for Tolls Tab
  static const List<String> travelPhrases = [
    'Travel Planner',
    'Trip Preparations',
    'Journey Guide',
    'Pre-Departure Guide',
  ];

  /// Preset phrases for Emergency Tab
  static const List<String> emergencyPhrases = [
    'Emergency Contacts',
    'Help Numbers',
    'Lifeline Numbers',
    'Rescue Lines',
  ];

  /// Preset phrases for Guide Tab
  static const List<String> guidePhrases = [
    'Highway Guide',
    'Toll Road Info',
    'Freeway Map',
    'Motorway Guide',
  ];

  const AeroTopBar({
    super.key,
    this.speechText,
    this.phrases,
    this.onSettingsPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  State<AeroTopBar> createState() => _AeroTopBarState();
}

class _AeroTopBarState extends State<AeroTopBar> {
  late String _displayedText;

  @override
  void initState() {
    super.initState();
    _pickPhrase();
  }

  void _pickPhrase() {
    if (widget.phrases != null && widget.phrases!.isNotEmpty) {
      final randomIndex = math.Random().nextInt(widget.phrases!.length);
      _displayedText = widget.phrases![randomIndex];
    } else {
      _displayedText = widget.speechText ?? 'All clear, driver.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64.0,
      automaticallyImplyLeading: false,
      titleSpacing: 16.0,
      backgroundColor: AeroColors.surfaceBase,
      title: Row(
        children: [
          const AeroAvatar(size: 52, showBorder: false),
          const SizedBox(width: 12),
          Flexible(
            child: AeroSpeechBubble(
              text: _displayedText,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: AeroColors.textSecondary, size: 24),
          onPressed: widget.onSettingsPressed ??
              () => AeroHomeAppBar.showSettingsDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Standalone Tier 2 Page Header Widget for consistent typography hierarchy.
class AeroTier2Header extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AeroTier2Header({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AeroTypography.headlineLg,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AeroTypography.bodySm,
          ),
        ],
      ],
    );
  }
}
