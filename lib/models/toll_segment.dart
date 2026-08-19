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
  final String direction; // "northbound", "southbound", or "both"
  final bool isActive;
  final DateTime lastUpdated;
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
    this.direction = 'both',
    this.isActive = true,
    required this.lastUpdated,
    this.notes,
  });

  factory TollSegment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TollSegment(
      id: doc.id,
      expressway: data['expressway'] as String? ?? '',
      expresswayName: data['expresswayName'] as String? ?? '',
      operator: data['operator'] as String? ?? '',
      entryPoint: data['entryPoint'] as String? ?? '',
      exitPoint: data['exitPoint'] as String? ?? '',
      fareClass1: (data['fareClass1'] as num?)?.toDouble() ?? 0.0,
      fareClass2: (data['fareClass2'] as num?)?.toDouble() ?? 0.0,
      fareClass3: (data['fareClass3'] as num?)?.toDouble() ?? 0.0,
      direction: data['direction'] as String? ?? 'both',
      isActive: data['isActive'] as bool? ?? true,
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
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
      'direction': direction,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      if (notes != null) 'notes': notes,
    };
  }
}
