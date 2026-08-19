import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a FAQ/guide entry for common on-road expressway situations.
///
/// Follows schema defined in data-model.md:
/// Collection: `guideEntries`
class GuideEntry {
  final String id;
  final String title;
  final String shortTitle;
  final String category; // e.g. "rfid", "breakdown", "navigation", "safety"
  final String content;
  final int sortOrder;
  final List<String> tags;
  final bool isActive;
  final DateTime lastUpdated;

  const GuideEntry({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.category,
    required this.content,
    this.sortOrder = 0,
    this.tags = const [],
    this.isActive = true,
    required this.lastUpdated,
  });

  factory GuideEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GuideEntry(
      id: doc.id,
      title: data['title'] as String? ?? '',
      shortTitle: data['shortTitle'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      content: data['content'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(data['tags'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      lastUpdated: data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'shortTitle': shortTitle,
      'category': category,
      'content': content,
      'sortOrder': sortOrder,
      'tags': tags,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
