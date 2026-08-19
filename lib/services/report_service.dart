import '../models/data_report.dart';
import 'firestore_service.dart';

/// Service for submitting feedback and data discrepancy reports.
///
/// Writes exclusively to the write-only `dataReports` Firestore collection.
class ReportService {
  final FirestoreService _firestoreService;

  ReportService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Submits a feedback report to Firestore.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> submitReport({
    required String reportType,
    required String targetId,
    required String targetName,
    required String issueDescription,
    String appVersion = '1.0.0+1',
    Map<String, dynamic> contextData = const {},
  }) async {
    try {
      final report = DataReport(
        reportType: reportType,
        targetId: targetId,
        targetName: targetName,
        issueDescription: issueDescription,
        appVersion: appVersion,
        contextData: contextData,
        timestamp: DateTime.now(),
      );

      await _firestoreService.dataReportsRef.add(report);
      return true;
    } catch (_) {
      // In offline or testing mode where Firestore might be mocked/unavailable,
      // fail gracefully without crashing
      return false;
    }
  }
}
