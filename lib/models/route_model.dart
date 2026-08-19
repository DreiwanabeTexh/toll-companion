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
  final bool isActive;

  const RouteModel({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.segmentIds,
    this.isActive = true,
  });

  factory RouteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RouteModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      origin: data['origin'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      segmentIds: List<String>.from(data['segmentIds'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'origin': origin,
      'destination': destination,
      'segmentIds': segmentIds,
      'isActive': isActive,
    };
  }
}
