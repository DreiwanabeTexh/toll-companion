import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a predefined or custom expressway route.
///
/// Follows schema defined in data-model.md:
/// Collection: `routes`
class RouteModel {
  final String id;
  final String name;
  final String origin;
  final String destination;
  final List<String> segmentIds;
  final DateTime? lastVerified; // Nullable trust field for fare & route verification
  final bool isActive;

  const RouteModel({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.segmentIds,
    this.lastVerified,
    this.isActive = true,
  });

  /// Whether this route has been verified against official TRB/operator data.
  bool get isVerified => lastVerified != null;

  factory RouteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RouteModel.fromMap(doc.id, data);
  }

  factory RouteModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? verifiedDate;
    if (data['lastVerified'] is Timestamp) {
      verifiedDate = (data['lastVerified'] as Timestamp).toDate();
    } else if (data['lastVerified'] is String) {
      verifiedDate = DateTime.tryParse(data['lastVerified'] as String);
    }

    return RouteModel(
      id: id,
      name: data['name'] as String? ?? '',
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      segmentIds: List<String>.from(data['segmentIds'] as List? ?? []),
      lastVerified: verifiedDate,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'origin': origin,
      'destination': destination,
      'segmentIds': segmentIds,
      'lastVerified':
          lastVerified != null ? Timestamp.fromDate(lastVerified!) : null,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'origin': origin,
      'destination': destination,
      'segmentIds': segmentIds,
      'lastVerified': lastVerified?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel.fromMap(json['id'] as String? ?? '', json);
  }
}
