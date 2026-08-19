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
  }) {
    final state =
        context.findAncestorStateOfType<_MainNavigationScaffoldState>();
    if (state != null) {
      state._onRouteSelected(originId, destinationId, vehicleClass);
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
  Key _tollKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onRouteSelected(String originId, String destId, int vehicleClass) {
    setState(() {
      _tollOriginId = originId;
      _tollDestId = destId;
      _tollVehicleClass = vehicleClass;
      _tollKey = UniqueKey();
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.012),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: [
            const HomeScreen(),
            TollCalculatorScreen(
              key: _tollKey,
              tollService: widget.tollService,
              initialOriginPlazaId: _tollOriginId,
              initialDestinationPlazaId: _tollDestId,
              initialVehicleClass: _tollVehicleClass,
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
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
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
