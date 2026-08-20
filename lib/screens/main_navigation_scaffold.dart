import 'package:flutter/material.dart';
import '../services/toll_service.dart';
import '../services/contacts_service.dart';
import '../services/guide_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import 'home_screen.dart';
import 'toll_calculator_screen.dart';
import 'emergency_contacts_screen.dart';
import 'quick_guide_screen.dart';

/// Top-level navigation container with Aero's persistent bottom navigation bar.
class MainNavigationScaffold extends StatefulWidget {
  final int initialIndex;
  final TollService? tollService;
  final ContactsService? contactsService;
  final GuideService? guideService;

  const MainNavigationScaffold({
    super.key,
    this.initialIndex = 0,
    this.tollService,
    this.contactsService,
    this.guideService,
  });

  /// Allows child widgets in the tree to request switching tabs.
  static void switchTab(BuildContext context, int tabIndex) {
    final state =
        context.findAncestorStateOfType<_MainNavigationScaffoldState>();
    if (state != null) {
      state._onTabSelected(tabIndex);
    }
  }

  /// Switches to Toll Calculator tab and pre-populates/calculates the given route.
  static void switchTabWithRoute(
    BuildContext context, {
    required String originId,
    required String destinationId,
    int vehicleClass = 1,
    bool useSkyway = true,
  }) {
    final state =
        context.findAncestorStateOfType<_MainNavigationScaffoldState>();
    if (state != null) {
      state._onRouteSelected(originId, destinationId, vehicleClass, useSkyway);
    }
  }

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late int _currentIndex;
  String? _tollOriginId;
  String? _tollDestId;
  int? _tollVehicleClass;
  bool? _tollUseSkyway;
  Key _tollKey = UniqueKey();
  Key _homeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        if (index == 0) {
          _homeKey = UniqueKey();
        }
        _currentIndex = index;
      });
    }
  }

  void _onRouteSelected(String originId, String destId, int vehicleClass, bool useSkyway) {
    setState(() {
      _tollOriginId = originId;
      _tollDestId = destId;
      _tollVehicleClass = vehicleClass;
      _tollUseSkyway = useSkyway;
      _tollKey = UniqueKey();
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AeroColors.themeModeNotifier,
      builder: (context, themeMode, _) {
        return Scaffold(
          key: ValueKey(themeMode),
          backgroundColor: AeroColors.surfaceBase,
          body: _FadeIndexedStack(
            index: _currentIndex,
            duration: const Duration(milliseconds: 200),
            children: [
              HomeScreen(key: _homeKey),
              TollCalculatorScreen(
                key: _tollKey,
                tollService: widget.tollService,
                initialOriginPlazaId: _tollOriginId,
                initialDestinationPlazaId: _tollDestId,
                initialVehicleClass: _tollVehicleClass,
                initialUseSkyway: _tollUseSkyway,
                isTab: true,
              ),
              EmergencyContactsScreen(
                contactsService: widget.contactsService,
                isTab: true,
              ),
              QuickGuideScreen(
                guideService: widget.guideService,
                isTab: true,
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AeroColors.surfaceContainer,
              border: Border(
                top: BorderSide(color: AeroColors.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.payments,
                    label: 'Tolls',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.emergency,
                    label: 'Emergency',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.explore,
                    label: 'Guide',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return AeroBouncyTap(
      scaleDown: 0.92,
      duration: const Duration(milliseconds: 120),
      onTap: () => _onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AeroColors.neonBlue.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AeroColors.neonBlue.withValues(alpha: 0.35),
                  width: 1,
                )
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.14 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AeroColors.neonBlue
                    : AeroColors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? AeroColors.neonBlue
                    : AeroColors.textSecondary,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hardware-accelerated, state-preserving tab switcher for Aero navigation.
///
/// Features:
/// - Keeps all 4 tab screens continuously alive in memory without disposing or rebuilding
/// - Smooth 200ms crossfade with a subtle, snappy slide transform
/// - Zero frame drops and zero tab state reset
class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const _FadeIndexedStack({
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late int _activePosition;

  @override
  void initState() {
    super.initState();
    _activePosition = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.008),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _activePosition = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: _activePosition,
          children: widget.children,
        ),
      ),
    );
  }
}

