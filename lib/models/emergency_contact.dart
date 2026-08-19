import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an official expressway emergency contact hotline (Tier 1 only).
///
/// Follows schema defined in data-model.md:
/// Collection: `emergencyContacts`
class EmergencyContact {
  final String id;
  final String agencyName;
  final String agencyShort;
  final String coverageArea;
  final String phoneNumber; // E.164 format for tel: URI
  final String displayNumber; // Human-readable display format
  final String description;
  final DateTime? lastVerified; // Nullable trust field displayed prominently in UI
  final int sortOrder;
  final bool isActive;

  const EmergencyContact({
    required this.id,
    required this.agencyName,
    required this.agencyShort,
    required this.coverageArea,
    required this.phoneNumber,
    required this.displayNumber,
    required this.description,
    this.lastVerified,
    this.sortOrder = 0,
    this.isActive = true,
  });

  /// Whether this contact has been verified against official sources.
  bool get isVerified => lastVerified != null;

  factory EmergencyContact.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EmergencyContact.fromMap(doc.id, data);
  }

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> data) {
    DateTime? verifiedDate;
    if (data['lastVerified'] is Timestamp) {
      verifiedDate = (data['lastVerified'] as Timestamp).toDate();
    } else if (data['lastVerified'] is String) {
      verifiedDate = DateTime.tryParse(data['lastVerified'] as String);
    }

    return EmergencyContact(
      id: id,
      agencyName: data['agencyName'] as String? ?? '',
      agencyShort: data['agencyShort'] as String? ?? '',
      coverageArea: data['coverageArea'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      displayNumber: data['displayNumber'] as String? ?? '',
      description: data['description'] as String? ?? '',
      lastVerified: verifiedDate,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agencyName': agencyName,
      'agencyShort': agencyShort,
      'coverageArea': coverageArea,
      'phoneNumber': phoneNumber,
      'displayNumber': displayNumber,
      'description': description,
      'lastVerified':
          lastVerified != null ? Timestamp.fromDate(lastVerified!) : null,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agencyName': agencyName,
      'agencyShort': agencyShort,
      'coverageArea': coverageArea,
      'phoneNumber': phoneNumber,
      'displayNumber': displayNumber,
      'description': description,
      'lastVerified': lastVerified?.toIso8601String(),
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact.fromMap(json['id'] as String? ?? '', json);
  }

  /// Returns tel: URI string for url_launcher
  String get telUri => 'tel:$phoneNumber';
}
