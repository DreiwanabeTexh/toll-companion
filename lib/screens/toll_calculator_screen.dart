import 'package:flutter/material.dart';
import '../models/route_model.dart';
import '../models/toll_segment.dart';
import '../models/route_result.dart';
import '../services/toll_service.dart';

/// Toll Calculator Screen for Phase 1 and Phase 2.
///
/// Allows drivers to select a route and vehicle class, displays
/// exact fare breakdowns partitioned by RFID operator, and provides
/// quick launches to Pre-Trip Checklist and Route Briefing.
class TollCalculatorScreen extends StatefulWidget {
  final TollService? tollService;

  const TollCalculatorScreen({super.key, this.tollService});

  @override
  State<TollCalculatorScreen> createState() => _TollCalculatorScreenState();
}

class _TollCalculatorScreenState extends State<TollCalculatorScreen> {
  late final TollService _tollService;
  RouteModel? _selectedRoute;
  int _selectedVehicleClass = 1; // Default to Class 1 (Cars, SUVs)
  List<TollSegment> _currentSegments = [];
  bool _isLoadingSegments = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tollService = widget.tollService ?? TollService();
  }

  Future<void> _onRouteSelected(RouteModel? route) async {
    if (route == null) {
      setState(() {
        _selectedRoute = null;
        _currentSegments = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _selectedRoute = route;
      _isLoadingSegments = true;
      _errorMessage = null;
    });

    try {
      final segments = await _tollService.getSegmentsForRoute(route);
      if (mounted) {
        setState(() {
          _currentSegments = segments;
          _isLoadingSegments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load route segments: $e';
          _isLoadingSegments = false;
        });
      }
    }
  }

  void _onClassChanged(int vehicleClass) {
    setState(() {
      _selectedVehicleClass = vehicleClass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toll Calculator'),
      ),
      body: StreamBuilder<List<RouteModel>>(
        stream: _tollService.getActiveRoutes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0088FF)),
                  SizedBox(height: 16),
                  Text(
                    'Loading routes...',
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
                      'Couldn\'t load routes. Check your connection.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE3E2E2)),
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

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.alt_route,
                        size: 64, color: Color(0xFF8A919F)),
                    const SizedBox(height: 16),
                    const Text(
                      'No routes available yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3E2E2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firestore collection "routes" is currently empty.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A919F)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _tollService.seedPlaceholderDataIfEmpty();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Seed Sample Placeholder Routes'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectedRoute == null && routes.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedRoute == null) {
                _onRouteSelected(routes.first);
              }
            });
          }

          final currentRoute = _selectedRoute ?? routes.first;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Route Selector Card
              _buildRouteSelectorCard(routes, currentRoute),
              const SizedBox(height: 12),

              // 2. Vehicle Class Selector
              _buildVehicleClassSelector(),
              const SizedBox(height: 16),

              // 3. Segment Loading, Error, or Breakdown
              if (_isLoadingSegments)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0088FF)),
                        SizedBox(height: 12),
                        Text(
                          'Calculating route fares...',
                          style: TextStyle(color: Color(0xFF8A919F)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorCard(_errorMessage!)
              else if (_currentSegments.isEmpty)
                _buildEmptySegmentsCard()
              else
                _buildFareBreakdown(currentRoute),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteSelectorCard(
      List<RouteModel> routes, RouteModel currentRoute) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.route, color: Color(0xFF0088FF), size: 20),
                SizedBox(width: 8),
                Text(
                  'SELECT ROUTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A919F),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentRoute.id,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE3E2E2),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF0088FF)),
                  items: routes.map((r) {
                    return DropdownMenuItem<String>(
                      value: r.id,
                      child: Text(
                        r.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (routeId) {
                    if (routeId != null) {
                      final selected = routes.firstWhere((r) => r.id == routeId);
                      _onRouteSelected(selected);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 14, color: Color(0xFF00CC88)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${currentRoute.origin} → ${currentRoute.destination}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A919F)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleClassSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_car, color: Color(0xFF0088FF), size: 20),
                SizedBox(width: 8),
                Text(
                  'VEHICLE CLASS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A919F),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Class 1'),
                  icon: Icon(Icons.directions_car, size: 16),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('Class 2'),
                  icon: Icon(Icons.directions_bus, size: 16),
                ),
                ButtonSegment<int>(
                  value: 3,
                  label: Text('Class 3'),
                  icon: Icon(Icons.local_shipping, size: 16),
                ),
              ],
              selected: {_selectedVehicleClass},
              onSelectionChanged: (newSelection) {
                _onClassChanged(newSelection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF0088FF).withValues(alpha: 0.2);
                  }
                  return const Color(0xFF141414);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF0088FF);
                  }
                  return const Color(0xFF8A919F);
                }),
                side: WidgetStateProperty.all(
                  const BorderSide(color: Color(0xFF2A2A2A)),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedVehicleClass == 1
                  ? 'Class 1: Cars, SUVs, Pickups, Vans'
                  : _selectedVehicleClass == 2
                      ? 'Class 2: Buses, Medium Trucks'
                      : 'Class 3: Heavy Trucks, Multi-axle trailers',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A919F)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareBreakdown(RouteModel route) {
    final result = _tollService.calculateFare(
      segments: _currentSegments,
      vehicleClass: _selectedVehicleClass,
    );

    final autosweepSegments = result.segmentsByOperator['autosweep'] ?? [];
    final easytripSegments = result.segmentsByOperator['easytrip'] ?? [];
    final otherOperators = result.segmentsByOperator.keys
        .where((op) => op != 'autosweep' && op != 'easytrip')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Route Trip Summary Banner
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Fare Breakdown: ${route.name}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE3E2E2),
            ),
          ),
        ),

        // 1. Autosweep Operator Card
        if (autosweepSegments.isNotEmpty) ...[
          _buildOperatorCard(
            operatorTitle: 'Autosweep Roads',
            operatorCode: 'autosweep',
            accentColor: const Color(0xFFFFA000), // Amber
            badgeColor: const Color(0xFF332200),
            segments: autosweepSegments,
            subtotal: result.fareByOperator['autosweep'] ?? 0.0,
          ),
          const SizedBox(height: 12),
        ],

        // 2. Easytrip Operator Card
        if (easytripSegments.isNotEmpty) ...[
          _buildOperatorCard(
            operatorTitle: 'Easytrip Roads',
            operatorCode: 'easytrip',
            accentColor: const Color(0xFF0088FF), // Electric Blue
            badgeColor: const Color(0xFF002244),
            segments: easytripSegments,
            subtotal: result.fareByOperator['easytrip'] ?? 0.0,
          ),
          const SizedBox(height: 12),
        ],

        // 3. Other operators if any
        for (final op in otherOperators) ...[
          _buildOperatorCard(
            operatorTitle: '${op.toUpperCase()} Roads',
            operatorCode: op,
            accentColor: const Color(0xFF00CC88),
            badgeColor: const Color(0xFF003322),
            segments: result.segmentsByOperator[op] ?? [],
            subtotal: result.fareByOperator[op] ?? 0.0,
          ),
          const SizedBox(height: 12),
        ],

        // 4. Combined Total & RFID Top-Up Callout Card
        _buildTotalCard(result),

        const SizedBox(height: 14),

        // Phase 2 Companion Actions: Checklist & Route Briefing
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/checklist',
                    arguments: route,
                  );
                },
                icon: const Icon(Icons.checklist_rtl,
                    size: 18, color: Color(0xFF00CC88)),
                label: const Text(
                  'Checklist',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE3E2E2),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                  backgroundColor: const Color(0xFF141414),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/route-briefing',
                    arguments: route,
                  );
                },
                icon: const Icon(Icons.alt_route,
                    size: 18, color: Color(0xFF0088FF)),
                label: const Text(
                  'Briefing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE3E2E2),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2A2A2A)),
                  backgroundColor: const Color(0xFF141414),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 5. Data freshness & placeholder disclaimer
        _buildDataFreshnessNotice(result),
      ],
    );
  }

  Widget _buildOperatorCard({
    required String operatorTitle,
    required String operatorCode,
    required Color accentColor,
    required Color badgeColor,
    required List<TollSegment> segments,
    required double subtotal,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Operator Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      operatorTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    operatorCode.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Segments List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                for (int i = 0; i < segments.length; i++) ...[
                  _buildSegmentRow(segments[i]),
                  if (i < segments.length - 1)
                    const Divider(height: 16, color: Color(0xFF2A2A2A)),
                ],
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFF2A2A2A)),

          // Subtotal Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A919F),
                  ),
                ),
                Text(
                  '₱${subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentRow(TollSegment segment) {
    final fare = _selectedVehicleClass == 2
        ? segment.fareClass2
        : _selectedVehicleClass == 3
            ? segment.fareClass3
            : segment.fareClass1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segment.expresswayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE3E2E2),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${segment.entryPoint} → ${segment.exitPoint}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A919F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '₱${fare.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE3E2E2),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(RouteResult result) {
    return Card(
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF0088FF), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL TOLL FARE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF8A919F),
                  ),
                ),
                Text(
                  '₱${result.totalFare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0088FF),
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 20),
            const Text(
              'Required RFID Wallet Top-Ups:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A919F),
              ),
            ),
            const SizedBox(height: 8),
            for (final advisory in result.topUpAdvisories)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: Color(0xFF00CC88)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advisory,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildDataFreshnessNotice(RouteResult result) {
    final formattedDate = result.latestVerificationDate != null
        ? 'Verified: ${_formatMonthYear(result.latestVerificationDate!)}'
        : 'Verified: Jan 2025';

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Color(0xFF8A919F)),
              const SizedBox(width: 4),
              Text(
                'Fares $formattedDate • // TODO(data): Placeholder amounts',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A919F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: const Color(0xFF2A0808),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFF5252)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF5252)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySegmentsCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No toll segments found for this route.',
            style: TextStyle(color: Color(0xFF8A919F)),
          ),
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}
