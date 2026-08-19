/// 3 Senior-Friendly Car Quick Presets for Philippine Drivers.
enum VehicleProfile {
  sedan(
    label: 'Sedan / Hatch',
    shortLabel: 'Sedan (14 km/L)',
    defaultEfficiencyKmL: 14.0,
    iconName: 'directions_car',
  ),
  suv(
    label: 'SUV / AUV',
    shortLabel: 'SUV (10 km/L)',
    defaultEfficiencyKmL: 10.0,
    iconName: 'airport_shuttle',
  ),
  pickup(
    label: 'Van / Pickup',
    shortLabel: 'Van/Pickup (8 km/L)',
    defaultEfficiencyKmL: 8.0,
    iconName: 'local_shipping',
  ),
  custom(
    label: 'Custom',
    shortLabel: 'Custom',
    defaultEfficiencyKmL: 12.0,
    iconName: 'tune',
  );

  final String label;
  final String shortLabel;
  final double defaultEfficiencyKmL;
  final String iconName;

  const VehicleProfile({
    required this.label,
    required this.shortLabel,
    required this.defaultEfficiencyKmL,
    required this.iconName,
  });

  static VehicleProfile fromString(String? key) {
    if (key == null) return VehicleProfile.sedan;
    return VehicleProfile.values.firstWhere(
      (v) => v.name.toLowerCase() == key.toLowerCase(),
      orElse: () => VehicleProfile.sedan,
    );
  }
}

/// Baseline Philippine fuel pricing constant.
class FuelDefaults {
  static const double defaultPricePerLiter = 65.00; // Standard PH baseline
  static const double defaultEfficiencyKmL = 12.0;  // Balanced average
}

/// Calculated fuel and total trip cost estimation.
class FuelEstimate {
  final double distanceKm;
  final double fuelEfficiencyKmL;
  final double fuelPricePerLiter;
  final double tollFare;
  final VehicleProfile vehicleProfile;

  const FuelEstimate({
    required this.distanceKm,
    required this.fuelEfficiencyKmL,
    required this.fuelPricePerLiter,
    required this.tollFare,
    this.vehicleProfile = VehicleProfile.sedan,
  });

  /// Total liters of fuel required for the trip.
  double get litersNeeded =>
      fuelEfficiencyKmL > 0 ? distanceKm / fuelEfficiencyKmL : 0.0;

  /// Estimated total cost of fuel in PHP.
  double get estimatedFuelCost => litersNeeded * fuelPricePerLiter;

  /// Combined total trip cost (Expressway Tolls + Estimated Fuel).
  double get totalTripCost => tollFare + estimatedFuelCost;

  /// Percentage of total trip cost accounted for by tolls.
  double get tollSharePercentage =>
      totalTripCost > 0 ? (tollFare / totalTripCost) * 100 : 0.0;

  /// Percentage of total trip cost accounted for by fuel.
  double get fuelSharePercentage =>
      totalTripCost > 0 ? (estimatedFuelCost / totalTripCost) * 100 : 0.0;
}
