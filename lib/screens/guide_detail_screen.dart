import 'package:flutter/material.dart';
import '../models/guide_entry.dart';

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
        appBar: AppBar(
          title: const Text('Guide Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline, size: 64, color: Color(0xFF8A919F)),
                const SizedBox(height: 16),
                const Text(
                  'No Guide Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE3E2E2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entryId != null
                      ? 'Guide entry "$entryId" could not be loaded.'
                      : 'Please select a guide topic from the Quick Guide list.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF8A919F)),
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
      appBar: AppBar(
        title: Text(effectiveEntry.shortTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Badge & Title Card
            Card(
              child: Padding(
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3E2E2),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Guidance Content Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.directions,
                          size: 20,
                          color: Color(0xFF0088FF),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recommended Actions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE3E2E2),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFF2A2A2A)),
                    Text(
                      effectiveEntry.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE3E2E2),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
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
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A919F),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Data freshness & disclaimer note
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Color(0xFF8A919F)),
                      const SizedBox(width: 4),
                      Text(
                        'Updated: ${_formatDate(effectiveEntry.lastUpdated)} • // TODO(data): Placeholder guidance',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8A919F)),
                      ),
                    ],
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
        return const Color(0xFFFFA000); // Amber
      case 'breakdown':
        return const Color(0xFFFF5252); // Red
      case 'navigation':
        return const Color(0xFF0088FF); // Blue
      case 'safety':
        return const Color(0xFF00CC88); // Green
      default:
        return const Color(0xFF0088FF);
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
