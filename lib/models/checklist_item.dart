import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pre-trip readiness check item for Phase 2.
///
/// Follows schema defined in data-model.md:
/// Collection: `checklistItems`
class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String category; // 'rfid', 'vehicle', 'documents', 'emergency'
  final String? operator; // 'autosweep', 'easytrip', or null
  final int sortOrder;
  final bool isActive;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.operator,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ChecklistItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChecklistItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      operator: data['operator'] as String?,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'operator': operator,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
