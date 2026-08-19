import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents practical guidance for driving lane positioning and toll gates.
class LaneTip {
  final String title;
  final String description;
  final String icon;

  const LaneTip({
    required this.title,
    required this.description,
    this.icon = 'navigation',
  });

  factory LaneTip.fromMap(Map<String, dynamic> map) {
    return LaneTip(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? 'navigation',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}

/// Represents a designated expressway service area / rest stop.
class RestStop {
  final String name;
  final String location;
  final String kilometer;
  final List<String> amenities;

  const RestStop({
    required this.name,
    required this.location,
    required this.kilometer,
    this.amenities = const [],
  });

  factory RestStop.fromMap(Map<String, dynamic> map) {
    return RestStop(
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      kilometer: map['kilometer'] as String? ?? '',
      amenities: (map['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'kilometer': kilometer,
      'amenities': amenities,
    };
  }
}

/// Represents common exit confusion or tricky fork guidance.
class ExitWarning {
  final String location;
  final String warning;
  final String tip;

  const ExitWarning({
    required this.location,
    required this.warning,
    required this.tip,
  });

  factory ExitWarning.fromMap(Map<String, dynamic> map) {
    return ExitWarning(
      location: map['location'] as String? ?? '',
      warning: map['warning'] as String? ?? '',
      tip: map['tip'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'warning': warning,
      'tip': tip,
    };
  }
}

/// Represents route-specific briefing content for Phase 2.
///
/// Follows schema defined in data-model.md:
/// Collection: `routeBriefings`
class RouteBriefing {
  final String id;
  final String routeId;
  final String routeName;
  final String generalAdvice;
  final List<LaneTip> laneTips;
  final List<RestStop> restStops;
  final List<ExitWarning> exitConfusions;
  final DateTime lastUpdated;
  final bool isActive;

  const RouteBriefing({
    required this.id,
    required this.routeId,
    required this.routeName,
    required this.generalAdvice,
    this.laneTips = const [],
    this.restStops = const [],
    this.exitConfusions = const [],
    required this.lastUpdated,
    this.isActive = true,
  });

  factory RouteBriefing.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return RouteBriefing(
      id: doc.id,
      routeId: data['routeId'] as String? ?? '',
      routeName: data['routeName'] as String? ?? '',
      generalAdvice: data['generalAdvice'] as String? ?? '',
      laneTips: (data['laneTips'] as List<dynamic>?)
              ?.map((e) => LaneTip.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      restStops: (data['restStops'] as List<dynamic>?)
              ?.map((e) => RestStop.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      exitConfusions: (data['exitConfusions'] as List<dynamic>?)
              ?.map((e) => ExitWarning.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'routeId': routeId,
      'routeName': routeName,
      'generalAdvice': generalAdvice,
      'laneTips': laneTips.map((e) => e.toMap()).toList(),
      'restStops': restStops.map((e) => e.toMap()).toList(),
      'exitConfusions': exitConfusions.map((e) => e.toMap()).toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
    };
  }
}
