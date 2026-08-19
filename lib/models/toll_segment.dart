import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single toll segment between an entry and exit toll plaza.
///
/// Follows schema defined in data-model.md:
/// Collection: `tollSegments`
class TollSegment {
  final String id;
  final String expressway;
  final String expresswayName;
  final String operator; // "autosweep" or "easytrip"
  final String entryPoint;
  final String exitPoint;
  final double fareClass1;
  final double fareClass2;
  final double fareClass3;
  final double? distanceKm;
  final String direction; // "northbound", "southbound", or "both"
  final bool isActive;
  final DateTime lastUpdated;
  final DateTime? lastVerified; // Nullable trust field
  final String? notes;

  const TollSegment({
    required this.id,
    required this.expressway,
    required this.expresswayName,
    required this.operator,
    required this.entryPoint,
    required this.exitPoint,
    required this.fareClass1,
    required this.fareClass2,
    required this.fareClass3,
    this.distanceKm,
    this.direction = 'both',
    this.isActive = true,
    required this.lastUpdated,
    this.lastVerified,
    this.notes,
  });

  bool get isVerified => lastVerified != null;

  /// Returns explicit distance or fallback based on standard segment density (~6.5 km).
  double get effectiveDistanceKm {
    if (distanceKm != null && distanceKm! > 0) return distanceKm!;
    // Fallback: approximate based on Class 1 fare (roughly ₱3.50/km on PH expressways)
    if (fareClass1 > 0) {
      return (fareClass1 / 3.6).clamp(2.5, 45.0);
    }
    return 4.0;
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
