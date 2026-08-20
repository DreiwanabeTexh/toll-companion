import 'package:flutter/material.dart';
import '../models/toll_plaza.dart';
import '../models/route_result.dart';
import '../models/fuel_estimate.dart';
import '../models/recent_trip.dart';
import '../services/toll_service.dart';
import '../services/cache_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import '../widgets/aero_mascot.dart';
import '../widgets/plaza_picker_sheet.dart';
import '../widgets/report_dialog.dart';

/// Aero Toll Calculator Screen powered by the Exit-to-Exit Toll Routing Engine.
///
/// Features:
/// - Search-based Origin & Destination Exit Picker across all Philippine expressways
/// - Multi-segment pathfinding with automatic operator boundary detection (Autosweep vs Easytrip)
/// - Regulatory Class 1, 2, 3 vehicle selectors with instant fare recalculation
/// - Total Trip Cost Calculator (Expressway Tolls + Fuel Cost Estimator)
/// - Strict sum-of-subtotals operator breakdown and trust-first verification indicators
/// - Reversible origin/destination swap and deep links to Checklist and Route Briefings
class TollCalculatorScreen extends StatefulWidget {
  final TollService? tollService;
  final CacheService? cacheService;
  final bool isTab;
  final String? initialOriginPlazaId;
  final String? initialDestinationPlazaId;
  final int? initialVehicleClass;
  final bool? initialUseSkyway;

  const TollCalculatorScreen({
    super.key,
    this.tollService,
    this.cacheService,
    this.isTab = false,
    this.initialOriginPlazaId,
    this.initialDestinationPlazaId,
    this.initialVehicleClass,
    this.initialUseSkyway,
  });

  @override
  State<TollCalculatorScreen> createState() => _TollCalculatorScreenState();
}

class _TollCalculatorScreenState extends State<TollCalculatorScreen> {
  late final TollService _tollService;
  late final CacheService _cacheService;
  late final Stream<List<TollPlaza>> _plazasStream;
  List<TollPlaza>? _initialPlazas;

  TollPlaza? _originPlaza;
  TollPlaza? _destinationPlaza;
  int _selectedVehicleClass = 1;
  bool _useSkyway = true;

  RouteResult? _routeResult;
  bool _isCalculating = false;
  String? _routingError;
  double? _userAutosweepBalance;
  double? _userEasytripBalance;

  // Fuel Estimator State
  bool _fuelEstimatorEnabled = true;
  VehicleProfile _selectedVehicleProfile = VehicleProfile.custom;
  double _customFuelPrice = FuelDefaults.defaultPricePerLiter;
  double _customFuelEfficiency = FuelDefaults.defaultEfficiencyKmL;
  bool _isFuelSettingsExpanded = false;
  late final TextEditingController _fuelPriceController;
  late final TextEditingController _fuelEfficiencyController;

  @override
  void initState() {
    super.initState();
    _tollService = widget.tollService ?? TollService();
    _cacheService = widget.cacheService ?? CacheService();
    _plazasStream = _tollService.getActivePlazas();
    _initialPlazas = TollService.defaultPlazas;
    if (widget.initialVehicleClass != null) {
      _selectedVehicleClass = widget.initialVehicleClass!;
    }
    if (widget.initialUseSkyway != null) {
      _useSkyway = widget.initialUseSkyway!;
    }
    _fuelPriceController =
        TextEditingController(text: _customFuelPrice.toStringAsFixed(2));
    _fuelEfficiencyController =
        TextEditingController(text: _customFuelEfficiency.toStringAsFixed(1));
    _loadUserBalances();
    _loadFuelPreferences();
    _loadSkywayPreference();
    _initializeDefaultRoute();
  }

  @override
  void dispose() {
    _fuelPriceController.dispose();
    _fuelEfficiencyController.dispose();
    super.dispose();
  }

  Future<void> _loadSkywayPreference() async {
    final pref = await _cacheService.getUseSkyway();
    if (mounted) {
      setState(() {
        _useSkyway = pref;
      });
    }
  }

  void _saveSkywayPreference(bool val) {
    _cacheService.saveUseSkyway(val);
  }

  Future<void> _loadFuelPreferences() async {
    final prefs = await _cacheService.getFuelPreferences();
    if (mounted) {
      setState(() {
        _fuelEstimatorEnabled = prefs['isEnabled'] as bool? ?? true;
        _customFuelPrice =
            prefs['fuelPrice'] as double? ?? FuelDefaults.defaultPricePerLiter;
        _customFuelEfficiency = prefs['fuelEfficiency'] as double? ??
            FuelDefaults.defaultEfficiencyKmL;
        _selectedVehicleProfile =
            VehicleProfile.fromString(prefs['vehicleProfile'] as String?);
        _fuelPriceController.text = _customFuelPrice.toStringAsFixed(2);
        _fuelEfficiencyController.text =
            _customFuelEfficiency.toStringAsFixed(1);
      });
    }
  }

  void _saveFuelPreferences() {
    _cacheService.saveFuelPreferences(
      fuelPrice: _customFuelPrice,
      fuelEfficiency: _customFuelEfficiency,
      vehicleProfile: _selectedVehicleProfile.name,
      isEnabled: _fuelEstimatorEnabled,
    );
  }

  Future<void> _loadUserBalances() async {
    final balances = await _cacheService.getRfidBalances();
    if (mounted) {
      setState(() {
        _userAutosweepBalance = balances['autosweep'];
        _userEasytripBalance = balances['easytrip'];
      });
    }
  }

  void _initializeDefaultRoute() {
    if (widget.initialOriginPlazaId != null && widget.initialDestinationPlazaId != null) {
      final origin = _initialPlazas?.firstWhere(
        (p) => p.id == widget.initialOriginPlazaId,
        orElse: () => _initialPlazas!.first,
      );
      final dest = _initialPlazas?.firstWhere(
        (p) => p.id == widget.initialDestinationPlazaId,
        orElse: () => _initialPlazas!.last,
      );
      _originPlaza = origin;
      _destinationPlaza = dest;
      _calculateFare();
    } else {
      _originPlaza = null;
      _destinationPlaza = null;
      _routeResult = null;
    }
  }

  Future<void> _calculateFare() async {
    if (_originPlaza == null || _destinationPlaza == null) return;
    _loadUserBalances();

    try {
      final result = _tollService.calculateExitToExitFareSync(
        originPlazaId: _originPlaza!.id,
        destinationPlazaId: _destinationPlaza!.id,
        vehicleClass: _selectedVehicleClass,
        useSkyway: _useSkyway,
      );

      setState(() {
        _routeResult = result;
        _isCalculating = false;
        if (result.segments.isEmpty && _originPlaza!.id != _destinationPlaza!.id) {
          _routingError = 'No continuous expressway path found between these exits.';
        } else {
          _routingError = null;
        }
      });

      if (result.segments.isNotEmpty) {
        final corridors = result.segments.map((s) => s.expressway).toSet().toList();
        final trip = RecentTrip(
          id: '${_originPlaza!.id}_${_destinationPlaza!.id}_${DateTime.now().millisecondsSinceEpoch}',
          originId: _originPlaza!.id,
          originName: _originPlaza!.name,
          destinationId: _destinationPlaza!.id,
          destinationName: _destinationPlaza!.name,
          vehicleClass: _selectedVehicleClass,
          totalFare: result.totalFare,
          corridors: corridors,
          timestamp: DateTime.now(),
          isFavorite: false,
          useSkyway: _useSkyway,
        );
        await _cacheService.addRecentTrip(trip);
      }
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _routingError = 'Routing calculation failed: $e';
      });
    }
  }

  void _swapOriginDestination() {
    if (_originPlaza == null || _destinationPlaza == null) return;
    setState(() {
      final temp = _originPlaza;
      _originPlaza = _destinationPlaza;
      _destinationPlaza = temp;
    });
    _calculateFare();
  }

  Future<void> _pickOrigin(List<TollPlaza> plazas) async {
    final selected = await PlazaPickerSheet.show(
      context: context,
      title: 'Select Origin Exit',
      plazas: plazas,
      selectedPlazaId: _originPlaza?.id,
    );

    if (selected != null && mounted) {
      setState(() {
        _originPlaza = selected;
      });
      _calculateFare();
    }
  }

  Future<void> _pickDestination(List<TollPlaza> plazas) async {
    final selected = await PlazaPickerSheet.show(
      context: context,
      title: 'Select Destination Exit',
      plazas: plazas,
      selectedPlazaId: _destinationPlaza?.id,
    );

    if (selected != null && mounted) {
      setState(() {
        _destinationPlaza = selected;
      });
      _calculateFare();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      appBar: AeroTopBar(
        phrases: AeroTopBar.travelPhrases,
      ),
      body: StreamBuilder<List<TollPlaza>>(
        stream: _plazasStream,
        initialData: _initialPlazas,
        builder: (context, snapshot) {
          final plazas = snapshot.data ?? TollService.defaultPlazas;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            children: [
              // Hero Row: Mascot Alongside Trip Details Heading
              AeroHeroHeaderRow(
                title: 'Trip Details',
                subtitle: 'Search origin & destination exits across PH expressways',
                mascotSize: 84,
              ),

              const SizedBox(height: 16),

              // Exit-to-Exit Search & Route Selector Card
              _buildExitPickerCard(plazas),

              const SizedBox(height: 16),

              // Skyway Route Option Toggle (Elevated vs At-Grade SLEX)
              _buildSkywayOptionToggle(),

              const SizedBox(height: 16),

              // Vehicle Class Selector Chips
              _buildVehicleClassSelector(),

              const SizedBox(height: 16),

              // Calculate Fare Action Button
              _buildCalculateButton(),

              const SizedBox(height: 20),

              // Routing Error Notice
              if (_routingError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AeroColors.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AeroColors.errorRed.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AeroColors.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _routingError!,
                          style: const TextStyle(
                            color: AeroColors.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Calculated Fare Breakdown View with smooth entrance
              if (_routeResult != null && _routeResult!.segments.isNotEmpty) ...[
                AeroFadeSlideIn(
                  key: ValueKey<String>('${_originPlaza?.id}_${_destinationPlaza?.id}_$_selectedVehicleClass'),
                  child: _buildFareBreakdownView(_routeResult!),
                ),
              ] else if (_originPlaza?.id == _destinationPlaza?.id && _originPlaza != null) ...[
                _buildSameExitNotice(),
              ],

              const SizedBox(height: 16),

              // Secondary Quick Action Links
              _buildSecondaryLinks(),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET BUILDERS
  // ===========================================================================

  Widget _buildExitPickerCard(List<TollPlaza> plazas) {
    return Container(
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AeroColors.border),
        boxShadow: AeroGlow.subtleCardGlow,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Origin Picker Row
          AeroBouncyTap(
            scaleDown: 0.98,
            onTap: () => _pickOrigin(plazas),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AeroColors.successEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORIGIN EXIT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AeroColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _originPlaza != null
                              ? '${_originPlaza!.name} (${_originPlaza!.expressway})'
                              : 'Tap to select origin exit...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _originPlaza != null
                                ? AeroColors.textPrimary
                                : AeroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.search, size: 20, color: AeroColors.neonBlue),
                ],
              ),
            ),
          ),

          // Connector & Swap Button Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Container(
                  width: 2,
                  height: 24,
                  color: AeroColors.border,
                ),
                const Spacer(),
                AeroBouncyTap(
                  scaleDown: 0.90,
                  onTap: _swapOriginDestination,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AeroColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: AeroColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_vert, size: 16, color: AeroColors.neonBlue),
                        SizedBox(width: 4),
                        Text(
                          'Swap',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AeroColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // Destination Picker Row
          AeroBouncyTap(
            scaleDown: 0.98,
            onTap: () => _pickDestination(plazas),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AeroColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESTINATION EXIT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AeroColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _destinationPlaza != null
                              ? '${_destinationPlaza!.name} (${_destinationPlaza!.expressway})'
                              : 'Tap to select destination exit...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _destinationPlaza != null
                                ? AeroColors.textPrimary
                                : AeroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.search, size: 20, color: AeroColors.neonBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkywayOptionToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _useSkyway
              ? AeroColors.neonBlue.withValues(alpha: 0.35)
              : AeroColors.border,
        ),
        boxShadow: _useSkyway ? AeroGlow.subtleCardGlow : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _useSkyway
                  ? AeroColors.neonBlue.withValues(alpha: 0.15)
                  : AeroColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _useSkyway
                    ? AeroColors.neonBlue.withValues(alpha: 0.35)
                    : AeroColors.border,
              ),
            ),
            child: Icon(
              _useSkyway ? Icons.flight_takeoff : Icons.directions_car,
              color: _useSkyway ? AeroColors.neonBlue : AeroColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      _useSkyway ? 'Via Skyway (Elevated)' : 'SLEX At-Grade (Surface)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AeroColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _useSkyway
                            ? AeroColors.neonBlue.withValues(alpha: 0.15)
                            : AeroColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _useSkyway ? 'FASTER' : 'LOWER TOLL',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: _useSkyway
                              ? AeroColors.neonBlue
                              : AeroColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _useSkyway
                      ? 'Includes Skyway Stages 1–3 elevated tolls'
                      : 'Ground level route (avoids elevated Skyway tolls)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AeroColors.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: _useSkyway,
            activeTrackColor: AeroColors.neonBlue,
            onChanged: (val) {
              setState(() {
                _useSkyway = val;
              });
              _saveSkywayPreference(val);
              _calculateFare();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleClassSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VEHICLE CLASSIFICATION',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AeroColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildClassChip(1, 'Class 1', 'Cars, SUVs, 4x4, Vans'),
            const SizedBox(width: 8),
            _buildClassChip(2, 'Class 2', 'Buses, Light Trucks'),
            const SizedBox(width: 8),
            _buildClassChip(3, 'Class 3', 'Heavy Multi-Axle Trucks'),
          ],
        ),
      ],
    );
  }

  Widget _buildClassChip(int classNum, String title, String subtitle) {
    final isSelected = _selectedVehicleClass == classNum;

    return Expanded(
      child: AeroBouncyTap(
        scaleDown: 0.94,
        onTap: () {
          setState(() {
            _selectedVehicleClass = classNum;
          });
          _calculateFare();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AeroColors.neonBlue.withValues(alpha: 0.15)
                : AeroColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AeroColors.neonBlue : AeroColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AeroColors.neonBlue : AeroColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                classNum == 1 ? 'Cars / SUVs' : classNum == 2 ? 'Buses / Trucks' : 'Heavy Trucks',
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected ? AeroColors.primaryTint : AeroColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return AeroBouncyTap(
      scaleDown: 0.97,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isCalculating ? null : _calculateFare,
          icon: _isCalculating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.calculate, size: 20, color: Colors.white),
          label: Text(
            _isCalculating ? 'ROUTING PATH...' : 'CALCULATE FARE',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AeroColors.neonBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            shadowColor: AeroColors.neonBlue.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSameExitNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeroColors.border),
      ),
      child: Center(
        child: Text(
          'Origin and Destination exits are identical. Fare: ₱0.00',
          style: TextStyle(
            color: AeroColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFareBreakdownView(RouteResult result) {
    final fuelEstimate = result.calculateFuelEstimate(
      vehicleProfile: _selectedVehicleProfile,
      customPricePerLiter: _customFuelPrice,
      customEfficiencyKmL: _customFuelEfficiency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Total Trip Cost / Fare Hero Card
        _buildTotalTripCostCard(result, fuelEstimate),

        const SizedBox(height: 12),

        // 2. Vehicle & Fuel Estimator Settings Card
        _buildFuelSettingsCard(fuelEstimate),

        const SizedBox(height: 16),

        // 3. Per-Operator Subtotal Breakdown Cards
        Text(
          'RFID OPERATOR BREAKDOWN',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AeroColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            // Autosweep Subtotal Card
            Expanded(
              child: _buildOperatorCard(
                operatorName: 'Autosweep RFID',
                amount: result.fareByOperator['autosweep'] ?? 0.0,
                segmentCount: result.segmentsByOperator['autosweep']?.length ?? 0,
                isAutosweep: true,
                userBalance: _userAutosweepBalance,
              ),
            ),
            const SizedBox(width: 10),
            // Easytrip Subtotal Card
            Expanded(
              child: _buildOperatorCard(
                operatorName: 'Easytrip RFID',
                amount: result.fareByOperator['easytrip'] ?? 0.0,
                segmentCount: result.segmentsByOperator['easytrip']?.length ?? 0,
                isAutosweep: false,
                userBalance: _userEasytripBalance,
              ),
            ),
          ],
        ),

        // Low Balance Warning Banner if wallet is short
        if ((result.fareByOperator['autosweep'] ?? 0.0) > 0 &&
                (_userAutosweepBalance != null &&
                    _userAutosweepBalance! < (result.fareByOperator['autosweep'] ?? 0.0)) ||
            (result.fareByOperator['easytrip'] ?? 0.0) > 0 &&
                (_userEasytripBalance != null &&
                    _userEasytripBalance! < (result.fareByOperator['easytrip'] ?? 0.0))) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AeroColors.warningAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AeroColors.warningAmber.withValues(alpha: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 20, color: AeroColors.warningAmber),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOW RFID BALANCE WARNING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AeroColors.warningAmber,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (result.fareByOperator['autosweep'] ?? 0.0) > 0 &&
                                (_userAutosweepBalance != null &&
                                    _userAutosweepBalance! <
                                        (result.fareByOperator['autosweep'] ?? 0.0)) &&
                                (result.fareByOperator['easytrip'] ?? 0.0) > 0 &&
                                (_userEasytripBalance != null &&
                                    _userEasytripBalance! <
                                        (result.fareByOperator['easytrip'] ?? 0.0))
                            ? 'Both Autosweep (₱${_userAutosweepBalance?.toStringAsFixed(2)}) and Easytrip (₱${_userEasytripBalance?.toStringAsFixed(2)}) balances are below estimated tolls. Top up before entry!'
                            : (result.fareByOperator['autosweep'] ?? 0.0) > 0 &&
                                    (_userAutosweepBalance != null &&
                                        _userAutosweepBalance! <
                                            (result.fareByOperator['autosweep'] ?? 0.0))
                                ? 'Autosweep balance (₱${_userAutosweepBalance?.toStringAsFixed(2)}) is less than required toll (₱${(result.fareByOperator['autosweep'] ?? 0.0).toStringAsFixed(2)}). Top up before entering!'
                                : 'Easytrip balance (₱${_userEasytripBalance?.toStringAsFixed(2)}) is less than required toll (₱${(result.fareByOperator['easytrip'] ?? 0.0).toStringAsFixed(2)}). Top up before entering!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AeroColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // 4. Itemized Toll Charges & Route Segments Accordion List
        _buildTollChargesAndSegmentsList(result),

        const SizedBox(height: 16),

        // 5. Aero Pro-Tip Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AeroColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AeroColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: AeroColors.neonBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aero recalculates toll rates dynamically based on entry/exit gantries across all operators.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AeroColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 6. Report Discrepancy Button
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => ReportDialog.show(
              context,
              reportType: 'toll_fare',
              targetId: '${_originPlaza?.id}_to_${_destinationPlaza?.id}',
              targetName: '${_originPlaza?.name} → ${_destinationPlaza?.name}',
              contextData: {
                'origin': _originPlaza?.name,
                'destination': _destinationPlaza?.name,
                'vehicleClass': _selectedVehicleClass,
                'totalFare': result.totalFare,
                'fareByOperator': result.fareByOperator,
              },
            ),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 13, color: AeroColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Report fare discrepancy',
                    style: TextStyle(
                      fontSize: 11,
                      color: AeroColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTripCostCard(
      RouteResult result, FuelEstimate fuelEstimate) {
    final traversedExpressways =
        result.segments.map((s) => s.expressway).toSet().toList();

    final displayedCost = _fuelEstimatorEnabled
        ? fuelEstimate.totalTripCost
        : result.totalFare;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AeroColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AeroColors.border),
        boxShadow: AeroGlow.subtleCardGlow,
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Verification Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _fuelEstimatorEnabled
                      ? 'TOTAL ESTIMATED TRIP COST'
                      : 'ESTIMATED TOLL FARE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AeroColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildVerificationBadge(result),
            ],
          ),

          const SizedBox(height: 6),

          // Total Trip Cost Big Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₱${displayedCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _fuelEstimatorEnabled
                      ? AeroColors.neonBlue
                      : AeroColors.primaryTint,
                  letterSpacing: -0.5,
                ),
              ),
              if (_fuelEstimatorEnabled) ...[
                const SizedBox(width: 8),
                Text(
                  '(Toll + Fuel)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AeroColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // 3-Metric Itemized Breakdown Bar
          if (_fuelEstimatorEnabled) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AeroColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Toll Fare Item
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.toll_outlined,
                                    size: 13, color: AeroColors.neonBlue),
                                SizedBox(width: 4),
                                Text(
                                  'TOLL FARE',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AeroColors.textSecondary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₱${result.totalFare.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AeroColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AeroColors.border,
                      ),
                      // Fuel Cost Item
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_gas_station_outlined,
                                      size: 13,
                                      color: AeroColors.secondaryOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EST. FUEL',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AeroColors.textSecondary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₱${fuelEstimate.estimatedFuelCost.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AeroColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AeroColors.border,
                      ),
                      // Distance Item
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.route_outlined,
                                      size: 13,
                                      color: AeroColors.emeraldGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'DISTANCE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AeroColors.textSecondary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '~${result.totalDistanceKm.toStringAsFixed(0)} km',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AeroColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Visual Cost Proportion Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (fuelEstimate.tollSharePercentage * 10)
                                .round()
                                .clamp(1, 1000),
                            child: Container(color: AeroColors.neonBlue),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: (fuelEstimate.fuelSharePercentage * 10)
                                .round()
                                .clamp(1, 1000),
                            child: Container(color: AeroColors.secondaryOrange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toll: ${fuelEstimate.tollSharePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AeroColors.neonBlue,
                        ),
                      ),
                      Text(
                        'Fuel: ${fuelEstimate.fuelSharePercentage.toStringAsFixed(0)}% (~${fuelEstimate.litersNeeded.toStringAsFixed(1)}L)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AeroColors.secondaryOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Route Corridor Breadcrumb Chips + Skyway Indicator Badge
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 0; i < traversedExpressways.length; i++) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AeroColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AeroColors.border),
                  ),
                  child: Text(
                    traversedExpressways[i],
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AeroColors.textPrimary,
                    ),
                  ),
                ),
                if (i < traversedExpressways.length - 1)
                  Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.arrow_forward,
                        size: 12, color: AeroColors.textSecondary),
                  ),
              ],
              if (traversedExpressways.contains('SKYWAY') || traversedExpressways.contains('SLEX')) ...[
                const SizedBox(width: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: _useSkyway
                        ? AeroColors.neonBlue.withValues(alpha: 0.15)
                        : AeroColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _useSkyway
                          ? AeroColors.neonBlue.withValues(alpha: 0.35)
                          : AeroColors.emeraldGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _useSkyway ? Icons.flight_takeoff : Icons.directions_car,
                        size: 11,
                        color: _useSkyway ? AeroColors.neonBlue : AeroColors.emeraldGreen,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _useSkyway ? 'VIA SKYWAY' : 'AT-GRADE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _useSkyway ? AeroColors.neonBlue : AeroColors.emeraldGreen,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuelSettingsCard(FuelEstimate fuelEstimate) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AeroColors.border),
      ),
      child: Column(
        children: [
          // Header Bar (Expandable + Toggle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isFuelSettingsExpanded = !_isFuelSettingsExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AeroColors.secondaryOrange
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_gas_station,
                              size: 18,
                              color: AeroColors.secondaryOrange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gas & Fuel Estimator',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AeroColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_customFuelEfficiency.toStringAsFixed(1)} km/L • ₱${_customFuelPrice.toStringAsFixed(2)}/L',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AeroColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _isFuelSettingsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 22,
                            color: AeroColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _fuelEstimatorEnabled,
                    activeThumbColor: AeroColors.secondaryOrange,
                    onChanged: (val) {
                      setState(() {
                        _fuelEstimatorEnabled = val;
                      });
                      _saveFuelPreferences();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Expanded Content Area
          if (_isFuelSettingsExpanded) ...[
            Divider(height: 1, color: AeroColors.border),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Quick Presets
                  Text(
                    'CAR TYPE (AUTO-FILLS KM/L)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AeroColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSimplePresetButton(
                        label: 'Sedan (14 km/L)',
                        icon: Icons.directions_car,
                        profile: VehicleProfile.sedan,
                      ),
                      const SizedBox(width: 6),
                      _buildSimplePresetButton(
                        label: 'SUV (10 km/L)',
                        icon: Icons.airport_shuttle,
                        profile: VehicleProfile.suv,
                      ),
                      const SizedBox(width: 6),
                      _buildSimplePresetButton(
                        label: 'Van/Pickup (8 km/L)',
                        icon: Icons.local_shipping,
                        profile: VehicleProfile.pickup,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Direct Manual Input Numbers
                  Text(
                    'MANUAL INPUTS (EDIT ANYTIME)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AeroColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      // Efficiency Input (km/L)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KM / LITER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AeroColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _fuelEfficiencyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AeroColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                suffixText: ' km/L',
                                suffixStyle: TextStyle(
                                  color: AeroColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: AeroColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AeroColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AeroColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AeroColors.secondaryOrange,
                                      width: 1.5),
                                ),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setState(() {
                                    _customFuelEfficiency = parsed;
                                    _selectedVehicleProfile =
                                        VehicleProfile.custom;
                                  });
                                  _saveFuelPreferences();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Fuel Price Input (₱/L)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GAS PRICE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AeroColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _fuelPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AeroColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                prefixText: '₱ ',
                                prefixStyle: const TextStyle(
                                  color: AeroColors.secondaryOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                suffixText: ' /L',
                                suffixStyle: TextStyle(
                                  color: AeroColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: AeroColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AeroColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AeroColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AeroColors.secondaryOrange,
                                      width: 1.5),
                                ),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  setState(() {
                                    _customFuelPrice = parsed;
                                  });
                                  _saveFuelPreferences();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Friendly Helper Note
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: AeroColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Type your car\'s dashboard km/L and current gas pump price.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AeroColors.textSecondary.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimplePresetButton({
    required String label,
    required IconData icon,
    required VehicleProfile profile,
  }) {
    final isSelected = _selectedVehicleProfile == profile;

    return Expanded(
      child: AeroBouncyTap(
        scaleDown: 0.94,
        onTap: () {
          setState(() {
            _selectedVehicleProfile = profile;
            _fuelEstimatorEnabled = true;
            _customFuelEfficiency = profile.defaultEfficiencyKmL;
            _fuelEfficiencyController.text =
                _customFuelEfficiency.toStringAsFixed(1);
          });
          _saveFuelPreferences();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AeroColors.secondaryOrange.withValues(alpha: 0.15)
                : AeroColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AeroColors.secondaryOrange
                  : AeroColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AeroColors.secondaryOrange
                    : AeroColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label.split('(').first.trim(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AeroColors.secondaryOrange
                      : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${profile.defaultEfficiencyKmL.toStringAsFixed(0)} km/L',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AeroColors.secondaryOrange.withValues(alpha: 0.9)
                      : AeroColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorCard({
    required String operatorName,
    required double amount,
    required int segmentCount,
    required bool isAutosweep,
    double? userBalance,
  }) {
    final isShort = amount > 0 && userBalance != null && userBalance < amount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isShort
              ? AeroColors.warningAmber.withValues(alpha: 0.6)
              : amount > 0
                  ? (isAutosweep
                      ? AeroColors.successEmerald.withValues(alpha: 0.35)
                      : AeroColors.neonBlue.withValues(alpha: 0.35))
                  : AeroColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isAutosweep
                      ? AeroColors.successEmerald
                      : AeroColors.neonBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  operatorName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AeroColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: amount > 0
                  ? (isAutosweep ? AeroColors.successEmerald : AeroColors.neonBlue)
                  : AeroColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            segmentCount == 1 ? '1 segment' : '$segmentCount segments',
            style: TextStyle(
              fontSize: 10,
              color: AeroColors.textSecondary,
            ),
          ),
          if (userBalance != null && amount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isShort ? Icons.error_outline : Icons.check_circle_outline,
                  size: 11,
                  color: isShort ? AeroColors.warningAmber : AeroColors.successEmerald,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isShort
                        ? 'Wallet: ₱${userBalance.toStringAsFixed(0)} (Short)'
                        : 'Wallet: ₱${userBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isShort ? AeroColors.warningAmber : AeroColors.successEmerald,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isSegmentsExpanded = false;

  Widget _buildTollChargesAndSegmentsList(RouteResult result) {
    final charges = result.tollCharges;
    final segments = result.segments;

    return Container(
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AeroColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isSegmentsExpanded = !_isSegmentsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          charges.isNotEmpty
                              ? 'Itemized Toll Charges (${charges.length})'
                              : 'Traversed Segments (${segments.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          charges.isNotEmpty
                              ? 'Official TRB rates and road corridor breakdown'
                              : 'Tap to view physical road segments',
                          style: TextStyle(fontSize: 11, color: AeroColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isSegmentsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _isSegmentsExpanded ? AeroColors.neonBlue : AeroColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isSegmentsExpanded) ...[
            Divider(color: AeroColors.border, height: 1),

            // Warnings if any
            if (result.warnings.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: result.warnings.map((w) => Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AeroColors.warningAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AeroColors.warningAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: AeroColors.warningAmber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            w,
                            style: TextStyle(fontSize: 10.5, color: AeroColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              Divider(color: AeroColors.border, height: 1),
            ],

            // Itemized Toll Charges List
            if (charges.isNotEmpty) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: charges.length,
                separatorBuilder: (_, _) => Divider(
                  color: AeroColors.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final charge = charges[index];
                  final isAutosweep = charge.operator.toLowerCase() == 'autosweep';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isAutosweep
                                ? AeroColors.successEmerald.withValues(alpha: 0.15)
                                : AeroColors.neonBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isAutosweep
                                  ? AeroColors.successEmerald.withValues(alpha: 0.4)
                                  : AeroColors.neonBlue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            charge.expressway,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isAutosweep ? AeroColors.successEmerald : AeroColors.neonBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                charge.explanation,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AeroColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${charge.sourceName} • ${charge.operator.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AeroColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₱${charge.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AeroColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AeroColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 13, color: AeroColors.neonBlue),
                          SizedBox(width: 6),
                          Text(
                            'Toll estimate based on TRB rate matrices',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AeroColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rates last updated: ${result.ratesLastUpdated != null ? '${result.ratesLastUpdated!.month.toString().padLeft(2, '0')}/${result.ratesLastUpdated!.year}' : '08/2024'}\nActual toll may vary. Check official advisories.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AeroColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Fallback physical segments list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: segments.length,
                separatorBuilder: (_, _) => Divider(
                  color: AeroColors.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final segment = segments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AeroColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            segment.expressway,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AeroColors.primaryTint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${segment.entryPoint} → ${segment.exitPoint}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AeroColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${segment.effectiveDistanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 11,
                            color: AeroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(RouteResult result) {
    final dateStr = result.ratesLastUpdated != null
        ? '${result.ratesLastUpdated!.month.toString().padLeft(2, '0')}/${result.ratesLastUpdated!.year}'
        : '08/2024';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AeroColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 12, color: AeroColors.neonBlue),
          const SizedBox(width: 4),
          Text(
            'TRB Matrix ($dateStr)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AeroColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryLinks() {
    return Row(
      children: [
        Expanded(
          child: AeroBouncyTap(
            scaleDown: 0.96,
            onTap: () => Navigator.of(context).pushNamed('/checklist'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checklist, size: 18, color: AeroColors.neonBlue),
                  SizedBox(width: 6),
                  Text(
                    'Pre-Trip Checklist',
                    style: TextStyle(fontSize: 11.5, color: AeroColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AeroBouncyTap(
            scaleDown: 0.96,
            onTap: () => Navigator.of(context).pushNamed(
              '/route-briefing',
              arguments: 'sample_route_multi_operator',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 18, color: AeroColors.neonBlue),
                  SizedBox(width: 6),
                  Text(
                    'Route Briefing',
                    style: TextStyle(fontSize: 11.5, color: AeroColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
