import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';
import '../models/route_model.dart';
import '../models/toll_plaza.dart';
import '../models/toll_segment.dart';
import '../models/toll_charge_rule.dart';
import '../models/guide_entry.dart';
import '../models/recent_trip.dart';

/// Local offline storage service powered by SharedPreferences.
///
/// Provides instant offline resilience without external authentication or cloud sync:
/// - Emergency contacts (so hotlines are available even in zero-signal deadzones)
/// - Toll Plazas & segments for exit-to-exit routing
/// - Toll Charge Rules for accurate offline TRB fare calculations
/// - Routes & toll segments for cached fare lookups
/// - Quick Guide troubleshooting content
/// - Last calculated route and fare
/// - User RFID balances and recent route history & favorites
class CacheService {
  static const String _keyEmergencyContacts = 'aero_cached_emergency_contacts';
  static const String _keyPlazas = 'aero_cached_plazas';
  static const String _keyTollRules = 'aero_cached_toll_rules';
  static const String _keyRoutes = 'aero_cached_routes';
  static const String _keyRouteSegmentsPrefix = 'aero_cached_segments_';
  static const String _keyGuideEntries = 'aero_cached_guide_entries';
  static const String _keyLastTrip = 'aero_cached_last_trip';
  static const String _keyAutosweepBalance = 'aero_balance_autosweep';
  static const String _keyEasytripBalance = 'aero_balance_easytrip';
  static const String _keyRecentTrips = 'aero_recent_trips';
  static const String _keyFuelPrice = 'aero_fuel_price';
  static const String _keyFuelEfficiency = 'aero_fuel_efficiency';
  static const String _keyVehicleProfile = 'aero_vehicle_profile';
  static const String _keyFuelEstimatorEnabled = 'aero_fuel_estimator_enabled';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyDriverName = 'driver_name';
  static const String _keyUseSkyway = 'aero_use_skyway';
  static const String _keyThemeMode = 'aero_theme_mode';

  final SharedPreferences? _customPrefs;

  CacheService({SharedPreferences? prefs}) : _customPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _customPrefs ?? await SharedPreferences.getInstance();
  }

  // --- Emergency Contacts ---

  Future<void> saveEmergencyContacts(List<EmergencyContact> contacts) async {
    final prefs = await _getPrefs();
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await prefs.setString(_keyEmergencyContacts, jsonEncode(jsonList));
  }

  Future<List<EmergencyContact>?> getEmergencyContacts() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyEmergencyContacts);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => EmergencyContact.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Toll Plazas ---

  Future<void> savePlazas(List<TollPlaza> plazas) async {
    final prefs = await _getPrefs();
    final jsonList = plazas.map((p) => p.toJson()).toList();
    await prefs.setString(_keyPlazas, jsonEncode(jsonList));
  }

  Future<List<TollPlaza>?> getPlazas() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyPlazas);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => TollPlaza.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Toll Charge Rules ---

  Future<void> saveTollRules(List<TollChargeRule> rules) async {
    final prefs = await _getPrefs();
    final jsonList = rules.map((r) => r.toJson()).toList();
    await prefs.setString(_keyTollRules, jsonEncode(jsonList));
  }

  Future<List<TollChargeRule>?> getTollRules() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyTollRules);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => TollChargeRule.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Routes ---

  Future<void> saveRoutes(List<RouteModel> routes) async {
    final prefs = await _getPrefs();
    final jsonList = routes.map((r) => r.toJson()).toList();
    await prefs.setString(_keyRoutes, jsonEncode(jsonList));
  }

  Future<List<RouteModel>?> getRoutes() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyRoutes);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => RouteModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Toll Segments per Route ---

  Future<void> saveRouteSegments(String routeId, List<TollSegment> segments) async {
    final prefs = await _getPrefs();
    final jsonList = segments.map((s) => s.toJson()).toList();
    await prefs.setString('$_keyRouteSegmentsPrefix$routeId', jsonEncode(jsonList));
  }

  Future<List<TollSegment>?> getRouteSegments(String routeId) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString('$_keyRouteSegmentsPrefix$routeId');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => TollSegment.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Guide Entries ---

  Future<void> saveGuideEntries(List<GuideEntry> entries) async {
    final prefs = await _getPrefs();
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_keyGuideEntries, jsonEncode(jsonList));
  }

  Future<List<GuideEntry>?> getGuideEntries() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyGuideEntries);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => GuideEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // --- Last Trip & Fare Calculation ---

  Future<void> saveLastTripCalculation({
    required String routeId,
    required int vehicleClass,
    required double totalFare,
    required Map<String, double> fareByOperator,
  }) async {
    final prefs = await _getPrefs();
    final data = {
      'routeId': routeId,
      'vehicleClass': vehicleClass,
      'totalFare': totalFare,
      'fareByOperator': fareByOperator,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_keyLastTrip, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getLastTripCalculation() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyLastTrip);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // --- RFID Balances (Offline Personalization) ---

  Future<Map<String, double>> getRfidBalances() async {
    try {
      final prefs = await _getPrefs();
      final autosweep = prefs.getDouble(_keyAutosweepBalance) ?? 1250.0;
      final easytrip = prefs.getDouble(_keyEasytripBalance) ?? 840.50;
      return {'autosweep': autosweep, 'easytrip': easytrip};
    } catch (_) {
      return {'autosweep': 1250.0, 'easytrip': 840.50};
    }
  }

  Future<void> saveRfidBalances({
    required double autosweep,
    required double easytrip,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyAutosweepBalance, autosweep);
    await prefs.setDouble(_keyEasytripBalance, easytrip);
  }

  // --- Recent Routes & Favorites ---

  Future<List<RecentTrip>> getRecentTrips() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyRecentTrips);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => RecentTrip.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentTrips(List<RecentTrip> trips) async {
    final prefs = await _getPrefs();
    final jsonList = trips.map((t) => t.toJson()).toList();
    await prefs.setString(_keyRecentTrips, jsonEncode(jsonList));
  }

  Future<void> addRecentTrip(RecentTrip trip) async {
    final trips = await getRecentTrips();
    // Remove identical pair if already present to put it at front
    trips.removeWhere(
      (t) => t.originId == trip.originId && t.destinationId == trip.destinationId,
    );
    trips.insert(0, trip);
    // Keep max 10 trips
    final trimmed = trips.take(10).toList();
    await saveRecentTrips(trimmed);
  }

  Future<void> toggleFavoriteTrip(String tripId) async {
    final trips = await getRecentTrips();
    final index = trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      trips[index] = trips[index].copyWith(isFavorite: !trips[index].isFavorite);
      await saveRecentTrips(trips);
    }
  }

  // --- Fuel Preferences ---

  Future<void> saveFuelPreferences({
    required double fuelPrice,
    required double fuelEfficiency,
    required String vehicleProfile,
    required bool isEnabled,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_keyFuelPrice, fuelPrice);
    await prefs.setDouble(_keyFuelEfficiency, fuelEfficiency);
    await prefs.setString(_keyVehicleProfile, vehicleProfile);
    await prefs.setBool(_keyFuelEstimatorEnabled, isEnabled);
  }

  Future<Map<String, dynamic>> getFuelPreferences() async {
    final prefs = await _getPrefs();
    return {
      'fuelPrice': prefs.getDouble(_keyFuelPrice) ?? 65.00,
      'fuelEfficiency': prefs.getDouble(_keyFuelEfficiency) ?? 12.0,
      'vehicleProfile': prefs.getString(_keyVehicleProfile) ?? 'custom',
      'isEnabled': prefs.getBool(_keyFuelEstimatorEnabled) ?? true,
    };
  }

  // --- Skyway Preference ---

  Future<void> saveUseSkyway(bool useSkyway) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyUseSkyway, useSkyway);
  }

  Future<bool> getUseSkyway() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyUseSkyway) ?? true;
  }

  // --- First-Run Onboarding & Driver Personalization ---

  Future<bool> isOnboardingComplete() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyOnboardingComplete, complete);
  }

  Future<String?> getDriverName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyDriverName);
  }

  Future<void> setDriverName(String name) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyDriverName, name.trim());
  }

  Future<String> getThemeMode() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyThemeMode) ?? 'dark';
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyThemeMode, mode);
  }

  /// Clears ALL stored local state (onboarding flag, driver name, cached reference data,
  /// recent trips, fuel preferences, and custom balances) to reset app to fresh install state.
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}

