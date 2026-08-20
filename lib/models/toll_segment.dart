import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single directed road link between an entry and exit toll plaza.
///
/// Refactored to represent pure physical road topology, distance, and directionality.
/// Pricing is now determined by [TollChargeRule]s rather than summing individual road segments.
class TollSegment {
  final String id;
  final String expressway;
  final String expresswayName;
  final String operator; // "autosweep" or "easytrip"
  final String entryPoint;
  final String exitPoint;
  final double? distanceKm;
  final String direction; // "northbound", "southbound", or "both"
  final bool isActive;
  final DateTime lastUpdated;
  final DateTime? lastVerified;
  final String? notes;

  /// Legacy segment fares (deprecated). Maintained for Firestore migration compatibility.
  @Deprecated('Toll pricing is governed by TollChargeRule. Legacy segment fare fields are ignored for pricing.')
  final double fareClass1;
  @Deprecated('Toll pricing is governed by TollChargeRule. Legacy segment fare fields are ignored for pricing.')
  final double fareClass2;
  @Deprecated('Toll pricing is governed by TollChargeRule. Legacy segment fare fields are ignored for pricing.')
  final double fareClass3;

  const TollSegment({
    required this.id,
    required this.expressway,
    required this.expresswayName,
    required this.operator,
    required this.entryPoint,
    required this.exitPoint,
    this.fareClass1 = 0.0,
    this.fareClass2 = 0.0,
    this.fareClass3 = 0.0,
    this.distanceKm,
    this.direction = 'both',
    this.isActive = true,
    required this.lastUpdated,
    this.lastVerified,
    this.notes,
  });

  bool get isVerified => lastVerified != null;

  /// Returns known physical distance in kilometers, or safe default routing weight (5.0 km).
  double get effectiveDistanceKm {
    if (distanceKm != null && distanceKm! > 0) return distanceKm!;
    return 5.0; // Safe default physical routing weight
  }

  factory TollSegment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TollSegment.fromMap(doc.id, data);
  }

  factory TollSegment.fromMap(String id, Map<String, dynamic> data) {
    DateTime updatedDate = DateTime.now();
    if (data['lastUpdated'] is Timestamp) {
      updatedDate = (data['lastUpdated'] as Timestamp).toDate();
    } else if (data['lastUpdated'] is String) {
      updatedDate = DateTime.tryParse(data['lastUpdated'] as String) ?? DateTime.now();
    }

    DateTime? verifiedDate;
    if (data['lastVerified'] is Timestamp) {
      verifiedDate = (data['lastVerified'] as Timestamp).toDate();
    } else if (data['lastVerified'] is String) {
      verifiedDate = DateTime.tryParse(data['lastVerified'] as String);
    }

    return TollSegment(
      id: id,
      expressway: data['expressway'] as String? ?? '',
      expresswayName: data['expresswayName'] as String? ?? '',
      operator: data['operator'] as String? ?? '',
      entryPoint: data['entryPoint'] as String? ?? '',
      exitPoint: data['exitPoint'] as String? ?? '',
      fareClass1: (data['fareClass1'] as num?)?.toDouble() ?? 0.0,
      fareClass2: (data['fareClass2'] as num?)?.toDouble() ?? 0.0,
      fareClass3: (data['fareClass3'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      direction: data['direction'] as String? ?? 'both',
      isActive: data['isActive'] as bool? ?? true,
      lastUpdated: updatedDate,
      lastVerified: verifiedDate,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expressway': expressway,
      'expresswayName': expresswayName,
      'operator': operator,
      'entryPoint': entryPoint,
      'exitPoint': exitPoint,
      'fareClass1': fareClass1,
      'fareClass2': fareClass2,
      'fareClass3': fareClass3,
      if (distanceKm != null) 'distanceKm': distanceKm,
      'direction': direction,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastVerified':
          lastVerified != null ? Timestamp.fromDate(lastVerified!) : null,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expressway': expressway,
      'expresswayName': expresswayName,
      'operator': operator,
      'entryPoint': entryPoint,
      'exitPoint': exitPoint,
      'fareClass1': fareClass1,
      'fareClass2': fareClass2,
      'fareClass3': fareClass3,
      if (distanceKm != null) 'distanceKm': distanceKm,
      'direction': direction,
      'isActive': isActive,
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastVerified': lastVerified?.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  factory TollSegment.fromJson(Map<String, dynamic> json) {
    return TollSegment.fromMap(json['id'] as String? ?? '', json);
  }
}
