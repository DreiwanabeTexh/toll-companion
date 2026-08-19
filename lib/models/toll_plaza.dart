import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single toll plaza / exit point on a Philippine expressway.
///
/// Follows schema defined in data-model.md:
/// Collection: `tollPlazas`
class TollPlaza {
  final String id;
  final String name;
  final String expressway; // e.g. "STAR", "SLEX", "SKYWAY", "NLEX", "CALAX", etc.
  final String expresswayName; // e.g. "STAR Tollway", "South Luzon Expressway"
  final String operator; // "autosweep" or "easytrip"
  final int orderIndex; // Linear position along the expressway
  final bool isInterchange; // Whether this plaza connects directly to another expressway
  final List<String> connectsTo; // IDs of connecting interchange plazas
  final bool isActive;
  final String? code;

  const TollPlaza({
    required this.id,
    required this.name,
    required this.expressway,
    required this.expresswayName,
    required this.operator,
    this.orderIndex = 0,
    this.isInterchange = false,
    this.connectsTo = const [],
    this.isActive = true,
    this.code,
  });

  factory TollPlaza.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TollPlaza.fromMap(doc.id, data);
  }

  factory TollPlaza.fromMap(String id, Map<String, dynamic> data) {
    return TollPlaza(
      id: id,
      name: data['name'] as String? ?? '',
      expressway: data['expressway'] as String? ?? '',
      expresswayName: data['expresswayName'] as String? ?? '',
      operator: data['operator'] as String? ?? '',
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      isInterchange: data['isInterchange'] as bool? ?? false,
      connectsTo: (data['connectsTo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: data['isActive'] as bool? ?? true,
      code: data['code'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'expressway': expressway,
      'expresswayName': expresswayName,
      'operator': operator,
      'orderIndex': orderIndex,
      'isInterchange': isInterchange,
      'connectsTo': connectsTo,
      'isActive': isActive,
      if (code != null) 'code': code,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expressway': expressway,
      'expresswayName': expresswayName,
      'operator': operator,
      'orderIndex': orderIndex,
      'isInterchange': isInterchange,
      'connectsTo': connectsTo,
      'isActive': isActive,
      if (code != null) 'code': code,
    };
  }

  factory TollPlaza.fromJson(Map<String, dynamic> json) {
    return TollPlaza.fromMap(json['id'] as String? ?? '', json);
  }

  @override
  String toString() => '$name ($expressway)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TollPlaza && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
