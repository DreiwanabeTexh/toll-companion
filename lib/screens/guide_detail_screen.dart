import 'package:flutter/material.dart';
import '../models/guide_entry.dart';
import '../theme.dart';

/// Detail screen displaying full guidance content for a specific expressway situation.
class GuideDetailScreen extends StatelessWidget {
  final GuideEntry? entry;
  final String? entryId;

  const GuideDetailScreen({
    super.key,
    this.entry,
    this.entryId,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveEntry = entry ??
        (ModalRoute.of(context)?.settings.arguments is GuideEntry
            ? ModalRoute.of(context)!.settings.arguments as GuideEntry
            : null);

    if (effectiveEntry == null) {
      return Scaffold(
        backgroundColor: AeroColors.surfaceBase,
        appBar: AppBar(
          backgroundColor: AeroColors.surfaceBase,
          title: Text(
            'Guide Details',
            style: TextStyle(color: AeroColors.textPrimary),
          ),
          iconTheme: IconThemeData(color: AeroColors.textPrimary),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.help_outline, size: 64, color: AeroColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No Guide Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AeroColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entryId != null
                      ? 'Guide entry "$entryId" could not be loaded.'
                      : 'Please select a guide topic from the Quick Guide list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AeroColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Quick Guide'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final categoryColor = _getCategoryColor(effectiveEntry.category);

    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AeroColors.surfaceBase,
        elevation: 0,
        title: Text(
          effectiveEntry.shortTitle,
          style: TextStyle(color: AeroColors.textPrimary),
        ),
        iconTheme: IconThemeData(color: AeroColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Badge & Title Card
            Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AeroColors.border),
                boxShadow: AeroGlow.subtleCardGlow,
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _formatCategory(effectiveEntry.category).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    effectiveEntry.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AeroColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Guidance Content Card
            Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AeroColors.border),
                boxShadow: AeroGlow.subtleCardGlow,
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions,
                        size: 20,
                        color: AeroColors.neonBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended Actions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AeroColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20, color: AeroColors.border),
                  Text(
                    effectiveEntry.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: AeroColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Tags Section (if any)
            if (effectiveEntry.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: effectiveEntry.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AeroColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AeroColors.border),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          color: AeroColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Data freshness note
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule,
                      size: 13, color: AeroColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Updated: ${_formatDate(effectiveEntry.lastUpdated)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AeroColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'rfid':
        return AeroColors.warningAmber;
      case 'breakdown':
        return AeroColors.errorRed;
      case 'navigation':
        return AeroColors.neonBlue;
      case 'safety':
        return AeroColors.successEmerald;
      default:
        return AeroColors.neonBlue;
    }
  }

  String _formatCategory(String category) {
    switch (category.toLowerCase()) {
      case 'rfid':
        return 'RFID Issue';
      case 'breakdown':
        return 'Vehicle Breakdown';
      case 'navigation':
        return 'Navigation';
      case 'safety':
        return 'Road Safety';
      default:
        return category;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}
