import 'fuel_estimate.dart';
import 'toll_segment.dart';

/// Represents the calculated fare breakdown for a route.
///
/// Ensures fares are partitioned strictly per RFID operator (Autosweep vs Easytrip).
/// The total fare is always computed as the sum of per-operator subtotals.
class RouteResult {
  final List<TollSegment> segments;
  final int vehicleClass; // 1, 2, or 3
  final Map<String, double> fareByOperator;
  final Map<String, List<TollSegment>> segmentsByOperator;
  final double totalFare;
  final DateTime? latestVerificationDate;

  RouteResult({
    required this.segments,
    required this.vehicleClass,
    required this.fareByOperator,
    required this.segmentsByOperator,
    required this.totalFare,
    this.latestVerificationDate,
  });

  /// Total calculated route distance in kilometers.
  double get totalDistanceKm =>
      segments.fold(0.0, (sum, seg) => sum + seg.effectiveDistanceKm);

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

  /// Factory constructor that groups segments and computes per-operator subtotals.
  factory RouteResult.calculate({
    required List<TollSegment> segments,
    int vehicleClass = 1,
  }) {
    final Map<String, List<TollSegment>> segmentsByOperator = {};
    final Map<String, double> fareByOperator = {};
    DateTime? latestDate;

    for (final segment in segments) {
      final operatorKey = segment.operator.toLowerCase().trim();
      final fare = _getFareForClass(segment, vehicleClass);

      segmentsByOperator.putIfAbsent(operatorKey, () => []).add(segment);
      fareByOperator[operatorKey] = (fareByOperator[operatorKey] ?? 0.0) + fare;

      if (latestDate == null || segment.lastUpdated.isAfter(latestDate)) {
        latestDate = segment.lastUpdated;
      }
    }

    // Total fare is strictly the sum of per-operator subtotals
    final totalFare = fareByOperator.values.fold(0.0, (sum, val) => sum + val);

    return RouteResult(
      segments: segments,
      vehicleClass: vehicleClass,
      fareByOperator: fareByOperator,
      segmentsByOperator: segmentsByOperator,
      totalFare: totalFare,
      latestVerificationDate: latestDate,
    );
  }

  static double _getFareForClass(TollSegment segment, int vehicleClass) {
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
