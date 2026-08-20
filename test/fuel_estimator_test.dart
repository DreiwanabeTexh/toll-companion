import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toll_companion/models/fuel_estimate.dart';
import 'package:toll_companion/models/route_result.dart';
import 'package:toll_companion/models/toll_segment.dart';
import 'package:toll_companion/services/cache_service.dart';
import 'package:toll_companion/services/toll_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FuelEstimate Math and Model Tests', () {
    test('Calculates fuel liters, costs, and total trip cost accurately', () {
      const estimate = FuelEstimate(
        distanceKm: 140.0,
        fuelEfficiencyKmL: 14.0, // 10 Liters
        fuelPricePerLiter: 65.0, // ₱650.00 Fuel
        tollFare: 400.0, // ₱400.00 Toll
        vehicleProfile: VehicleProfile.sedan,
      );

      expect(estimate.litersNeeded, closeTo(10.0, 0.001));
      expect(estimate.estimatedFuelCost, closeTo(650.0, 0.001));
      expect(estimate.totalTripCost, closeTo(1050.0, 0.001));
      expect(estimate.tollSharePercentage, closeTo(38.095, 0.01));
      expect(estimate.fuelSharePercentage, closeTo(61.904, 0.01));
    });

    test('Handles zero distance and zero efficiency gracefully', () {
      const zeroDistance = FuelEstimate(
        distanceKm: 0.0,
        fuelEfficiencyKmL: 14.0,
        fuelPricePerLiter: 65.0,
        tollFare: 0.0,
      );
      expect(zeroDistance.litersNeeded, equals(0.0));
      expect(zeroDistance.estimatedFuelCost, equals(0.0));
      expect(zeroDistance.totalTripCost, equals(0.0));
      expect(zeroDistance.tollSharePercentage, equals(0.0));

      const zeroEfficiency = FuelEstimate(
        distanceKm: 100.0,
        fuelEfficiencyKmL: 0.0,
        fuelPricePerLiter: 65.0,
        tollFare: 100.0,
      );
      expect(zeroEfficiency.litersNeeded, equals(0.0));
      expect(zeroEfficiency.estimatedFuelCost, equals(0.0));
      expect(zeroEfficiency.totalTripCost, equals(100.0));
    });

    test('VehicleProfile fromString and helper resolution', () {
      expect(VehicleProfile.fromString('sedan'), equals(VehicleProfile.sedan));
      expect(VehicleProfile.fromString('suv'), equals(VehicleProfile.suv));
      expect(VehicleProfile.fromString('pickup'), equals(VehicleProfile.pickup));
      expect(VehicleProfile.fromString('custom'), equals(VehicleProfile.custom));
      expect(VehicleProfile.fromString('unknown'), equals(VehicleProfile.sedan));

      expect(VehicleProfile.sedan.defaultEfficiencyKmL, equals(14.0));
      expect(VehicleProfile.suv.defaultEfficiencyKmL, equals(10.0));
      expect(VehicleProfile.pickup.defaultEfficiencyKmL, equals(8.0));
      expect(VehicleProfile.custom.defaultEfficiencyKmL, equals(12.0));
    });
  });

  group('RouteResult Fuel Estimation Integration', () {
    test('calculateFuelEstimate derives totalDistanceKm from segments', () {
      final tollService = TollService();
      // Calculate Batangas to Lipa
      final result = tollService.calculateExitToExitFareSync(
        originPlazaId: 'star_batangas',
        destinationPlazaId: 'star_lipa',
        vehicleClass: 1,
      );

      expect(result.segments.length, equals(2));
      expect(result.totalFare, equals(57.0));
      expect(result.totalDistanceKm, greaterThan(15.0));

      final fuelEstimate = result.calculateFuelEstimate(
        vehicleProfile: VehicleProfile.sedan,
      );

      expect(fuelEstimate.distanceKm, equals(result.totalDistanceKm));
      expect(fuelEstimate.tollFare, equals(57.0));
      expect(fuelEstimate.estimatedFuelCost, greaterThan(0.0));
      expect(fuelEstimate.totalTripCost, equals(fuelEstimate.tollFare + fuelEstimate.estimatedFuelCost));
    });

    test('calculateFuelEstimate respects custom overrides', () {
      final seg = TollSegment(
        id: 'test_seg',
        expressway: 'SLEX',
        expresswayName: 'SLEX',
        operator: 'autosweep',
        entryPoint: 'slex_alabang',
        exitPoint: 'slex_calamba',
        fareClass1: 154.0,
        fareClass2: 308.0,
        fareClass3: 462.0,
        distanceKm: 30.0,
        lastUpdated: DateTime.now(),
      );

      final routeResult = RouteResult.calculate(segments: [seg], vehicleClass: 1);
      expect(routeResult.totalDistanceKm, equals(30.0));

      final customEstimate = routeResult.calculateFuelEstimate(
        customPricePerLiter: 50.0,
        customEfficiencyKmL: 10.0,
      );

      // 30 km / 10 km/L = 3 Liters * ₱50 = ₱150.00
      expect(customEstimate.litersNeeded, closeTo(3.0, 0.001));
      expect(customEstimate.estimatedFuelCost, closeTo(150.0, 0.001));
      // ₱154.00 Toll + ₱150.00 Fuel = ₱304.00 Total Trip Cost
      expect(customEstimate.totalTripCost, closeTo(304.0, 0.001));
    });
  });

  group('CacheService Fuel Preferences Persistence', () {
    test('Saves and retrieves fuel preferences offline with senior-friendly defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cache = CacheService(prefs: prefs);

      // Default preferences
      final defaults = await cache.getFuelPreferences();
      expect(defaults['fuelPrice'], equals(FuelDefaults.defaultPricePerLiter));
      expect(defaults['fuelEfficiency'], equals(FuelDefaults.defaultEfficiencyKmL));
      expect(defaults['vehicleProfile'], equals('custom'));
      expect(defaults['isEnabled'], isTrue);

      // Save custom preferences
      await cache.saveFuelPreferences(
        fuelPrice: 58.50,
        fuelEfficiency: 9.5,
        vehicleProfile: 'suv',
        isEnabled: true,
      );

      final updated = await cache.getFuelPreferences();
      expect(updated['fuelPrice'], equals(58.50));
      expect(updated['fuelEfficiency'], equals(9.5));
      expect(updated['vehicleProfile'], equals('suv'));
      expect(updated['isEnabled'], isTrue);
    });
  });
}
