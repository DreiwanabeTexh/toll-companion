import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the verification status of a toll pricing rule.
enum TollVerificationStatus {
  /// Verified with official TRB/operator publication, effective date, and verification within 180 days.
  verified,

  /// Valid official source exists, but verification is older than 180 days.
  stale,

  /// Source URL or document reference is missing.
  missingSource,

  /// Missing effective date, unverified matrix, or requires manual regulatory review.
  needsManualReview,
}

/// Represents an explicit toll pricing rule issued by the Toll Regulatory Board (TRB)
/// or expressway concessionaires (SMC / MPTC).
///
/// Supports:
/// - Closed-system Origin-Destination (OD) matrix fares (e.g. SLEX, STAR, CALAX, SCTEX, TPLEX)
/// - Open-system flat barrier charges (e.g. NLEX Open System, Skyway Stages 1-3 gantries, MCX, NAIAX)
/// - Fixed connector fees (e.g. NLEX Connector C3-Magsaysay, NAIAX Ramp)
class TollChargeRule {
  final String id;
  final String expressway; // e.g. "STAR", "SLEX", "SKYWAY", "NLEX", "CALAX", "SCTEX", "TPLEX"
  final String operator; // "autosweep" or "easytrip"
  final String collectionType; // "closedSystem", "openBarrier", "fixedConnector"
  final String direction; // "northbound", "southbound", or "both"
  final String? entryPlazaId; // For closed-system OD or connector entries
  final String? exitPlazaId; // For closed-system OD or connector exits
  final String? barrierPlazaId; // For open-system barrier points (e.g. "nlex_balintawak")
  final double fareClass1;
  final double fareClass2;
  final double fareClass3;
  final DateTime? effectiveFrom;
  final String sourceName; // e.g. "TRB Official STAR Tollway Toll Matrix"
  final String? sourceUrl; // Direct URL to TRB or concessionaire published rate sheet
  final DateTime? ratesLastUpdated;
  DateTime? get lastVerified => ratesLastUpdated;
  final TollVerificationStatus? manualStatus;
  final bool isActive;
  final String? notes;

  const TollChargeRule({
    required this.id,
    required this.expressway,
    required this.operator,
    required this.collectionType,
    this.direction = 'both',
    this.entryPlazaId,
    this.exitPlazaId,
    this.barrierPlazaId,
    required this.fareClass1,
    required this.fareClass2,
    required this.fareClass3,
    this.effectiveFrom,
    this.sourceName = 'TRB Official Toll Rate Matrix',
    this.sourceUrl,
    DateTime? lastVerified,
    DateTime? ratesLastUpdated,
    this.manualStatus,
    this.isActive = true,
    this.notes,
  }) : ratesLastUpdated = ratesLastUpdated ?? lastVerified ?? effectiveFrom;

  /// Evaluates verification status strictly based on real regulatory source availability.
  TollVerificationStatus get verificationStatus {
    if (manualStatus != null) {
      return manualStatus!;
    }
    if (sourceUrl == null || sourceUrl!.trim().isEmpty) {
      return TollVerificationStatus.missingSource;
    }
    if (ratesLastUpdated == null || effectiveFrom == null) {
      return TollVerificationStatus.needsManualReview;
    }
    final ageInDays = DateTime.now().difference(ratesLastUpdated!).inDays;
    if (ageInDays > 180) {
      return TollVerificationStatus.stale;
    }
    return TollVerificationStatus.verified;
  }

  /// Whether this rule is officially verified against current TRB publications.
  bool get isVerified => verificationStatus == TollVerificationStatus.verified;

  double getFareForClass(int vehicleClass) {
    switch (vehicleClass) {
      case 2:
        return fareClass2;
      case 3:
        return fareClass3;
      case 1:
      default:
        return fareClass1;
    }
  }

  factory TollChargeRule.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TollChargeRule.fromMap(doc.id, data);
  }

  factory TollChargeRule.fromMap(String id, Map<String, dynamic> data) {
    DateTime? effectiveDate;
    if (data['effectiveFrom'] is Timestamp) {
      effectiveDate = (data['effectiveFrom'] as Timestamp).toDate();
    } else if (data['effectiveFrom'] is String) {
      effectiveDate = DateTime.tryParse(data['effectiveFrom'] as String);
    }

    DateTime? updatedDate;
    final dateVal = data['ratesLastUpdated'] ?? data['lastVerified'];
    if (dateVal is Timestamp) {
      updatedDate = dateVal.toDate();
    } else if (dateVal is String) {
      updatedDate = DateTime.tryParse(dateVal);
    }

    return TollChargeRule(
      id: id,
      expressway: data['expressway'] as String? ?? '',
      operator: data['operator'] as String? ?? '',
      collectionType: data['collectionType'] as String? ?? 'closedSystem',
      direction: data['direction'] as String? ?? 'both',
      entryPlazaId: data['entryPlazaId'] as String?,
      exitPlazaId: data['exitPlazaId'] as String?,
      barrierPlazaId: data['barrierPlazaId'] as String?,
      fareClass1: (data['fareClass1'] as num?)?.toDouble() ?? 0.0,
      fareClass2: (data['fareClass2'] as num?)?.toDouble() ?? 0.0,
      fareClass3: (data['fareClass3'] as num?)?.toDouble() ?? 0.0,
      effectiveFrom: effectiveDate,
      sourceName: data['sourceName'] as String? ?? 'TRB Official Toll Rate Matrix',
      sourceUrl: data['sourceUrl'] as String?,
      ratesLastUpdated: updatedDate,
      isActive: data['isActive'] as bool? ?? true,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expressway': expressway,
      'operator': operator,
      'collectionType': collectionType,
      'direction': direction,
      if (entryPlazaId != null) 'entryPlazaId': entryPlazaId,
      if (exitPlazaId != null) 'exitPlazaId': exitPlazaId,
      if (barrierPlazaId != null) 'barrierPlazaId': barrierPlazaId,
      'fareClass1': fareClass1,
      'fareClass2': fareClass2,
      'fareClass3': fareClass3,
      if (effectiveFrom != null) 'effectiveFrom': Timestamp.fromDate(effectiveFrom!),
      'sourceName': sourceName,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (lastVerified != null) 'lastVerified': Timestamp.fromDate(lastVerified!),
      'isActive': isActive,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expressway': expressway,
      'operator': operator,
      'collectionType': collectionType,
      'direction': direction,
      if (entryPlazaId != null) 'entryPlazaId': entryPlazaId,
      if (exitPlazaId != null) 'exitPlazaId': exitPlazaId,
      if (barrierPlazaId != null) 'barrierPlazaId': barrierPlazaId,
      'fareClass1': fareClass1,
      'fareClass2': fareClass2,
      'fareClass3': fareClass3,
      if (effectiveFrom != null) 'effectiveFrom': effectiveFrom?.toIso8601String(),
      'sourceName': sourceName,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (lastVerified != null) 'lastVerified': lastVerified?.toIso8601String(),
      'isActive': isActive,
      if (notes != null) 'notes': notes,
    };
  }

  factory TollChargeRule.fromJson(Map<String, dynamic> json) {
    return TollChargeRule.fromMap(json['id'] as String? ?? '', json);
  }
}
