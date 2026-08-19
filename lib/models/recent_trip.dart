/// Model representing a recently calculated or favorited exit-to-exit trip.
class RecentTrip {
  final String id;
  final String originId;
  final String originName;
  final String destinationId;
  final String destinationName;
  final int vehicleClass;
  final double totalFare;
  final List<String> corridors;
  final DateTime timestamp;
  final bool isFavorite;

  const RecentTrip({
    required this.id,
    required this.originId,
    required this.originName,
    required this.destinationId,
    required this.destinationName,
    required this.vehicleClass,
    required this.totalFare,
    required this.corridors,
    required this.timestamp,
    this.isFavorite = false,
  });

  RecentTrip copyWith({
    String? id,
    String? originId,
    String? originName,
    String? destinationId,
    String? destinationName,
    int? vehicleClass,
    double? totalFare,
    List<String>? corridors,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return RecentTrip(
      id: id ?? this.id,
      originId: originId ?? this.originId,
      originName: originName ?? this.originName,
      destinationId: destinationId ?? this.destinationId,
      destinationName: destinationName ?? this.destinationName,
      vehicleClass: vehicleClass ?? this.vehicleClass,
      totalFare: totalFare ?? this.totalFare,
      corridors: corridors ?? this.corridors,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originId': originId,
      'originName': originName,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'vehicleClass': vehicleClass,
      'totalFare': totalFare,
      'corridors': corridors,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory RecentTrip.fromJson(Map<String, dynamic> json) {
    return RecentTrip(
      id: json['id'] as String? ?? '',
      originId: json['originId'] as String? ?? '',
      originName: json['originName'] as String? ?? '',
      destinationId: json['destinationId'] as String? ?? '',
      destinationName: json['destinationName'] as String? ?? '',
      vehicleClass: json['vehicleClass'] as int? ?? 1,
      totalFare: (json['totalFare'] as num?)?.toDouble() ?? 0.0,
      corridors: (json['corridors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
