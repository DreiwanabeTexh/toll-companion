import 'package:flutter/material.dart';
import '../models/guide_entry.dart';
import '../services/guide_service.dart';
import 'guide_detail_screen.dart';

/// Quick Guide screen displaying scannable list of expressway situations ("What do I do if...").
class QuickGuideScreen extends StatefulWidget {
  final GuideService? guideService;

  const QuickGuideScreen({super.key, this.guideService});

  @override
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen> {
  late final GuideService _guideService;
  String _selectedCategory = 'all';
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _guideService = widget.guideService ?? GuideService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Guide'),
      ),
      body: StreamBuilder<List<GuideEntry>>(
        stream: _guideService.getGuideEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0088FF)),
                  SizedBox(height: 16),
                  Text(
                    'Loading guide entries...',
                    style: TextStyle(color: Color(0xFF8A919F)),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFFF5252)),
                    const SizedBox(height: 16),
                    Text(
                      'Couldn\'t load guide entries. Check your connection.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE3E2E2)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allEntries = snapshot.data ?? [];

          if (allEntries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book,
                        size: 64, color: Color(0xFF8A919F)),
                    const SizedBox(height: 16),
                    const Text(
                      'No guide entries available yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3E2E2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firestore collection "guideEntries" is currently empty.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A919F)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isSeeding
                          ? null
                          : () async {
                              setState(() => _isSeeding = true);
                              await _guideService.seedPlaceholderDataIfEmpty();
                              if (mounted) {
                                setState(() => _isSeeding = false);
                              }
                            },
                      icon: _isSeeding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Seed Sample Placeholder Guides'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter by category
          final filteredEntries = _selectedCategory == 'all'
              ? allEntries
              : allEntries
                  .where((e) =>
                      e.category.toLowerCase() ==
                      _selectedCategory.toLowerCase())
                  .toList();

          return Column(
            children: [
              // Category filter chips bar
              Container(
                color: const Color(0xFF141414),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Topics'),
                      const SizedBox(width: 8),
                      _buildFilterChip('rfid', 'RFID'),
                      const SizedBox(width: 8),
                      _buildFilterChip('breakdown', 'Breakdown'),
                      const SizedBox(width: 8),
                      _buildFilterChip('navigation', 'Navigation'),
                      const SizedBox(width: 8),
                      _buildFilterChip('safety', 'Safety'),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFF2A2A2A)),

              // Entries List
              Expanded(
                child: filteredEntries.isEmpty
                    ? const Center(
                        child: Text(
                          'No guides found in this category.',
                          style: TextStyle(color: Color(0xFF8A919F)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _buildGuideCard(entry);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() {
          _selectedCategory = categoryKey;
        });
      },
      selectedColor: const Color(0xFF0088FF).withValues(alpha: 0.2),
      backgroundColor: const Color(0xFF1A1A1A),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF0088FF) : const Color(0xFF8A919F),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0088FF) : const Color(0xFF2A2A2A),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildGuideCard(GuideEntry entry) {
    final categoryColor = _getCategoryColor(entry.category);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideDetailScreen(entry: entry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _formatCategory(entry.category).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3E2E2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.shortTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A919F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF8A919F)),
            ],
          ),
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
        return 'RFID';
      case 'breakdown':
        return 'Breakdown';
      case 'navigation':
        return 'Navigation';
      case 'safety':
        return 'Safety';
      default:
        return category;
    }
  }
}
