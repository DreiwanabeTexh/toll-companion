import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/report_service.dart';
import 'aero_snackbar.dart';

/// Lightweight modal dialog for reporting outdated or incorrect data.
///
/// Submits reports directly to the write-only `dataReports` Firestore collection.
class ReportDialog extends StatefulWidget {
  final String reportType; // "emergency_contact", "toll_fare", or "route"
  final String targetId;
  final String targetName;
  final Map<String, dynamic> contextData;
  final ReportService? reportService;

  const ReportDialog({
    super.key,
    required this.reportType,
    required this.targetId,
    required this.targetName,
    this.contextData = const {},
    this.reportService,
  });

  static Future<void> show(
    BuildContext context, {
    required String reportType,
    required String targetId,
    required String targetName,
    Map<String, dynamic> contextData = const {},
    ReportService? reportService,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reportType: reportType,
        targetId: targetId,
        targetName: targetName,
        contextData: contextData,
        reportService: reportService,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final service = widget.reportService ?? ReportService();
    await service.submitReport(
      reportType: widget.reportType,
      targetId: widget.targetId,
      targetName: widget.targetName,
      issueDescription: text,
      contextData: widget.contextData,
    );

    if (mounted) {
      Navigator.pop(context);
      AeroSnackBar.showSuccess(context, "Thanks, we'll review this.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AeroColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AeroColors.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AeroColors.warningAmber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag,
              color: AeroColors.warningAmber,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Report Incorrect Info',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AeroColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-attached Context Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AeroColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AeroColors.neonBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.targetName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AeroColors.primaryTint,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "What's outdated or incorrect?",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AeroColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textController,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: AeroColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Hotline changed, new fare adjustment, incorrect plaza...',
                hintStyle: TextStyle(fontSize: 12, color: AeroColors.textSecondary),
                filled: true,
                fillColor: AeroColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AeroColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AeroColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AeroColors.neonBlue),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AeroColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AeroColors.neonBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Submit Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
        ),
      ],
    );
  }
}
