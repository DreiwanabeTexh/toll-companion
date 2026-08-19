import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../models/route_briefing.dart';
import '../services/briefing_service.dart';
import '../services/toll_service.dart';

/// Route Briefing screen (Phase 2).
///
/// Displays route-specific lane positioning tips, service plaza rest stops,
/// and exit/fork warnings tied to the selected expressway route.
class RouteBriefingScreen extends StatefulWidget {
  final BriefingService? briefingService;
  final TollService? tollService;
  final String? routeId;
  final RouteModel? route;

  const RouteBriefingScreen({
    super.key,
    this.briefingService,
    this.tollService,
    this.routeId,
    this.route,
  });

  @override
  State<RouteBriefingScreen> createState() => _RouteBriefingScreenState();
}

class _RouteBriefingScreenState extends State<RouteBriefingScreen>
    with SingleTickerProviderStateMixin {
  late final BriefingService _briefingService;
  late final TollService _tollService;
  late final Stream<List<RouteModel>> _routesStream;
  late TabController _tabController;

  String? _selectedRouteId;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _briefingService = widget.briefingService ?? BriefingService();
    _tollService = widget.tollService ?? TollService();
    _routesStream = _tollService.getActiveRoutes();
    _tabController = TabController(length: 3, vsync: this);
    _selectedRouteId = widget.routeId ?? widget.route?.id;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for arguments passed via named route (can be RouteModel or String routeId)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_selectedRouteId == null) {
      if (args is RouteModel) {
        _selectedRouteId = args.id;
      } else if (args is String) {
        _selectedRouteId = args;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Briefing'),
      ),
      body: StreamBuilder<List<RouteModel>>(
        stream: _routesStream,
        initialData: TollService.defaultRoutes,
        builder: (context, routesSnapshot) {
          final routes = routesSnapshot.data ?? [];

          // Auto-select first route if none selected yet and routes loaded
          if (_selectedRouteId == null && routes.isNotEmpty) {
            _selectedRouteId = routes.first.id;
          }

          return Column(
            children: [
              // Route Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF141414),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, color: Color(0xFF0088FF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: routes.isEmpty
                          ? const Text(
                              'Loading available routes...',
                              style: TextStyle(color: Color(0xFF8A919F)),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: routes.any((r) => r.id == _selectedRouteId)
                                    ? _selectedRouteId
                                    : (routes.isNotEmpty ? routes.first.id : null),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1A1A1A),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE3E2E2),
                                ),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF0088FF),
                                ),
                                items: routes.map((r) {
                                  return DropdownMenuItem<String>(
                                    value: r.id,
                                    child: Text(
                                      r.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newId) {
                                  if (newId != null) {
                                    setState(() {
                                      _selectedRouteId = newId;
                                    });
                                  }
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Tab Bar Navigation
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0088FF),
                labelColor: const Color(0xFF0088FF),
                unselectedLabelColor: const Color(0xFF8A919F),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.alt_route, size: 18),
                    text: 'Lane Tips',
                  ),
                  Tab(
                    icon: Icon(Icons.local_gas_station, size: 18),
                    text: 'Rest Stops',
                  ),
                  Tab(
                    icon: Icon(Icons.warning_amber_rounded, size: 18),
                    text: 'Exit Warnings',
                  ),
                ],
              ),

              // Briefing Content Canvas
              Expanded(
                child: _selectedRouteId == null
                    ? const Center(
                        child: Text(
                          'Select a route to view briefing',
                          style: TextStyle(color: Color(0xFF8A919F)),
                        ),
                      )
                    : StreamBuilder<RouteBriefing?>(
                        stream: _briefingService
                            .getBriefingForRoute(_selectedRouteId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                      color: Color(0xFF0088FF)),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading route briefing...',
                                    style: TextStyle(color: Color(0xFF8A919F)),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48, color: Color(0xFFFF5252)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Couldn\'t load briefing. Check connection.\n${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Color(0xFFE3E2E2)),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => setState(() {}),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final briefing = snapshot.data;

                          if (briefing == null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.menu_book_outlined,
                                        size: 64, color: Color(0xFF8A919F)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No briefing for this route yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE3E2E2),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Firestore collection "routeBriefings" does not have an entry for this route.',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Color(0xFF8A919F)),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _isSeeding
                                          ? null
                                          : () async {
                                              setState(() => _isSeeding = true);
                                              await _briefingService
                                                  .seedPlaceholderDataIfEmpty();
                                              if (mounted) {
                                                setState(
                                                    () => _isSeeding = false);
                                              }
                                            },
                                      icon: _isSeeding
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.cloud_upload),
                                      label: const Text(
                                          'Seed Sample Route Briefings'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLaneTipsTab(briefing),
                              _buildRestStopsTab(briefing),
                              _buildExitWarningsTab(briefing),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLaneTipsTab(RouteBriefing briefing) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // General Advice Summary
        if (briefing.generalAdvice.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0088FF).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF0088FF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF0088FF), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ROUTE ADVISORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0088FF),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        briefing.generalAdvice,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE3E2E2),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (briefing.laneTips.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No specific lane tips recorded for this route.',
                style: TextStyle(color: Color(0xFF8A919F)),
              ),
            ),
          )
        else
          for (final tip in briefing.laneTips) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0088FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _resolveIcon(tip.icon),
                        color: const Color(0xFF0088FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE3E2E2),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tip.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8A919F),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildRestStopsTab(RouteBriefing briefing) {
    if (briefing.restStops.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No rest stops or service plazas listed for this route.',
            style: TextStyle(color: Color(0xFF8A919F)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        for (final stop in briefing.restStops) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stop.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE3E2E2),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0088FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF0088FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          stop.kilometer,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0088FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 15, color: Color(0xFF8A919F)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A919F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stop.amenities.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stop.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF2A2A2A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_resolveAmenityIcon(amenity),
                                  size: 13, color: const Color(0xFF00CC88)),
                              const SizedBox(width: 4),
                              Text(
                                amenity,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFE3E2E2),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExitWarningsTab(RouteBriefing briefing) {
    if (briefing.exitConfusions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No high-confusion exit warnings recorded for this route.',
            style: TextStyle(color: Color(0xFF8A919F)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        for (final exit in briefing.exitConfusions) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFFFA000),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFFA000), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exit.location,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE3E2E2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Risk: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFA000),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            exit.warning,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE3E2E2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CC88).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tip: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00CC88),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            exit.tip,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE3E2E2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _resolveIcon(String iconStr) {
    switch (iconStr.toLowerCase()) {
      case 'speed':
        return Icons.speed;
      case 'sensors':
        return Icons.sensors;
      case 'visibility':
        return Icons.visibility;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'camera_alt':
        return Icons.camera_alt;
      default:
        return Icons.alt_route;
    }
  }

  IconData _resolveAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('fuel') || lower.contains('gas')) {
      return Icons.local_gas_station;
    }
    if (lower.contains('food') || lower.contains('dining') || lower.contains('snack')) {
      return Icons.restaurant;
    }
    if (lower.contains('restroom') || lower.contains('clean')) {
      return Icons.wc;
    }
    if (lower.contains('charging') || lower.contains('ev')) {
      return Icons.ev_station;
    }
    if (lower.contains('tire') || lower.contains('air') || lower.contains('water')) {
      return Icons.build;
    }
    if (lower.contains('atm')) {
      return Icons.atm;
    }
    return Icons.check_circle_outline;
  }
}
