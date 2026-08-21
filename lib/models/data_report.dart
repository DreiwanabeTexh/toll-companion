import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user-submitted data correction report.
///
/// Follows schema defined in data-model.md:
/// Collection: `dataReports` (Write-only for client devices)
class DataReport {
  final String? id;
  final String reportType; // "emergency_contact", "toll_fare", or "route"
  final String targetId; // ID of the contact or route
  final String targetName; // Human-readable name of agency or route
  final String issueDescription; // User's feedback
  final String appVersion; // e.g. "1.0.0+1"
  final Map<String, dynamic> contextData; // Additional context like fare, class, etc.
  final DateTime timestamp;

  const DataReport({
    this.id,
    required this.reportType,
    required this.targetId,
    required this.targetName,
    required this.issueDescription,
    this.appVersion = '1.0.0+1',
    this.contextData = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    final sanitizedContext = <String, String>{};
    final allowedKeys = {'displayNumber', 'coverageArea', 'origin', 'destination', 'vehicleClass', 'totalFare'};
    contextData.forEach((key, value) {
      if (allowedKeys.contains(key) && value != null) {
        sanitizedContext[key] = value.toString();
      }
    });

    return {
      'reportType': reportType,
      'targetId': targetId,
      'targetName': targetName,
      'issueDescription': issueDescription,
      'appVersion': appVersion,
      if (sanitizedContext.isNotEmpty) 'contextData': sanitizedContext,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory DataReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return DataReport(
      id: doc.id,
      reportType: data['reportType'] as String? ?? 'general',
      targetId: data['targetId'] as String? ?? '',
      targetName: data['targetName'] as String? ?? '',
      issueDescription: data['issueDescription'] as String? ?? '',
      appVersion: data['appVersion'] as String? ?? '1.0.0+1',
      contextData: Map<String, dynamic>.from(data['contextData'] as Map? ?? {}),
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
