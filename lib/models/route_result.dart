import 'fuel_estimate.dart';
import 'route_calculation_debug.dart';
import 'toll_charge_breakdown.dart';
import 'toll_segment.dart';

/// Represents the calculated fare breakdown and physical path for a route.
///
/// Ensures fares are partitioned strictly per RFID operator (Autosweep vs Easytrip).
/// The total fare is always computed as the sum of per-operator subtotals.
class RouteResult {
  final List<String> orderedPlazaIds;
  final List<TollSegment> segments;
  final List<TollChargeBreakdown> tollCharges;
  final int vehicleClass; // 1, 2, or 3
  final Map<String, double> fareByOperator;
  final Map<String, List<TollSegment>> segmentsByOperator;
  final double totalFare;
  final List<String> warnings;
  final DateTime? ratesLastUpdated;
  DateTime? get latestVerificationDate => ratesLastUpdated;
  final RouteCalculationDebug? debugInfo;

  RouteResult({
    this.orderedPlazaIds = const [],
    required this.segments,
    this.tollCharges = const [],
    required this.vehicleClass,
    required this.fareByOperator,
    required this.segmentsByOperator,
    required this.totalFare,
    this.warnings = const [],
    DateTime? latestVerificationDate,
    DateTime? ratesLastUpdated,
    this.debugInfo,
  }) : ratesLastUpdated = ratesLastUpdated ?? latestVerificationDate;

  /// Total calculated physical route distance in kilometers.
  double get totalDistanceKm =>
      segments.fold(0.0, (sum, seg) => sum + seg.effectiveDistanceKm);

  /// Whether any of the toll charges on this route are unverified or stale.
  bool get hasUnverifiedCharges =>
      tollCharges.any((charge) => !charge.isVerified);

  /// Computes a comprehensive Fuel and Total Trip Cost estimate for this route.
  FuelEstimate calculateFuelEstimate({
    VehicleProfile vehicleProfile = VehicleProfile.sedan,
    double? customPricePerLiter,
    double? customEfficiencyKmL,
  }) {
    final price = customPricePerLiter != null && customPricePerLiter > 0
        ? customPricePerLiter
        : FuelDefaults.defaultPricePerLiter;

    final efficiency = customEfficiencyKmL != null && customEfficiencyKmL > 0
        ? customEfficiencyKmL
        : vehicleProfile.defaultEfficiencyKmL;

    return FuelEstimate(
      distanceKm: totalDistanceKm,
      fuelEfficiencyKmL: efficiency,
      fuelPricePerLiter: price,
      tollFare: totalFare,
      vehicleProfile: vehicleProfile,
    );
  }

  /// Factory constructor that groups charges and computes per-operator subtotals.
  factory RouteResult.calculate({
    required List<TollSegment> segments,
    List<TollChargeBreakdown>? tollCharges,
    List<String>? orderedPlazaIds,
    List<String>? warnings,
    int vehicleClass = 1,
    RouteCalculationDebug? debugInfo,
  }) {
    final Map<String, List<TollSegment>> segmentsByOperator = {};
    final Map<String, double> fareByOperator = {};
    DateTime? latestDate;
    final List<String> resolvedWarnings = [...?warnings];

    for (final segment in segments) {
      final operatorKey = segment.operator.toLowerCase().trim();
      segmentsByOperator.putIfAbsent(operatorKey, () => []).add(segment);
    }

    final charges = tollCharges ?? [];

    if (charges.isNotEmpty) {
      for (final charge in charges) {
        final operatorKey = charge.operator.toLowerCase().trim();
        fareByOperator[operatorKey] =
            (fareByOperator[operatorKey] ?? 0.0) + charge.amount;

        final updateDate = charge.ratesLastUpdated ?? charge.lastVerified;
        if (updateDate != null) {
          if (latestDate == null || updateDate.isAfter(latestDate)) {
            latestDate = updateDate;
          }
        }

        if (!charge.isVerified) {
          final unverifiedMsg =
              '${charge.expressway} fare (${charge.explanation}) is marked as ${charge.verificationStatus.name} and requires manual verification.';
          if (!resolvedWarnings.contains(unverifiedMsg)) {
            resolvedWarnings.add(unverifiedMsg);
          }
        }
      }
    } else {
      // Legacy fallback when no TollChargeBreakdown provided (for compatibility)
      for (final segment in segments) {
        final operatorKey = segment.operator.toLowerCase().trim();
        final fare = _getLegacyFareForClass(segment, vehicleClass);
        fareByOperator[operatorKey] = (fareByOperator[operatorKey] ?? 0.0) + fare;

        if (latestDate == null || segment.lastUpdated.isAfter(latestDate)) {
          latestDate = segment.lastUpdated;
        }
      }
    }

    // Total fare is strictly the sum of per-operator subtotals
    final totalFare = fareByOperator.values.fold(0.0, (sum, val) => sum + val);

    return RouteResult(
      orderedPlazaIds: orderedPlazaIds ?? [],
      segments: segments,
      tollCharges: charges,
      vehicleClass: vehicleClass,
      fareByOperator: fareByOperator,
      segmentsByOperator: segmentsByOperator,
      totalFare: totalFare,
      warnings: resolvedWarnings,
      ratesLastUpdated: latestDate,
      debugInfo: debugInfo,
    );
  }

  static double _getLegacyFareForClass(TollSegment segment, int vehicleClass) {
    // ignore: deprecated_member_use_from_same_package
    switch (vehicleClass) {
      case 2:
        return segment.fareClass2;
      case 3:
        return segment.fareClass3;
      case 1:
      default:
        return segment.fareClass1;
    }
  }

  /// Human-readable list of top-up advisories per operator
  List<String> get topUpAdvisories {
    final List<String> advisories = [];
    fareByOperator.forEach((operator, amount) {
      if (amount <= 0) return;
      final formattedName = operator == 'autosweep'
          ? 'Autosweep'
          : operator == 'easytrip'
              ? 'Easytrip'
              : operator.toUpperCase();
      advisories.add('Load at least ₱${amount.toStringAsFixed(2)} on $formattedName');
    });
    return advisories;
  }
}
