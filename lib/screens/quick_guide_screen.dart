import 'package:flutter/material.dart';
import '../models/guide_entry.dart';
import '../services/guide_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import '../widgets/aero_mascot.dart';
import '../widgets/aero_offline_banner.dart';
import '../widgets/aero_snackbar.dart';
import 'guide_detail_screen.dart';
import 'main_navigation_scaffold.dart';

/// Aero Quick Guide Screen featuring a dedicated animated hero mascot alongside the heading.
class QuickGuideScreen extends StatefulWidget {
  final GuideService? guideService;
  final bool isTab;

  const QuickGuideScreen({
    super.key,
    this.guideService,
    this.isTab = false,
  });

  @override
  State<QuickGuideScreen> createState() => _QuickGuideScreenState();
}

class _QuickGuideScreenState extends State<QuickGuideScreen> {
  late final GuideService _guideService;
  late final Stream<List<GuideEntry>> _guideStream;
  List<GuideEntry>? _initialEntries;
  bool _isSeeding = false;

  // Track expanded accordion categories (first item active by default)
  final Set<String> _expandedCategories = {'rfid'};

  @override
  void initState() {
    super.initState();
    _guideService = widget.guideService ?? GuideService();
    _guideStream = _guideService.getGuideEntries();
    _loadInitialCache();
  }

  Future<void> _loadInitialCache() async {
    final cached = await _guideService.getCachedGuideEntries();
    if (mounted) {
      setState(() {
        _initialEntries = cached;
      });
    }
  }

  void _toggleCategory(String categoryKey) {
    setState(() {
      if (_expandedCategories.contains(categoryKey)) {
        _expandedCategories.remove(categoryKey);
      } else {
        // Single expansion matching reference behavior
        _expandedCategories.clear();
        _expandedCategories.add(categoryKey);
      }
    });
  }

  void _showCategoryTopicsSheet(
    BuildContext context,
    _CategoryGroup cat,
    List<GuideEntry> entries,
  ) {
    if (entries.isEmpty) {
      AeroSnackBar.showInfo(context, 'No FAQs currently filed under ${cat.title}.');
      return;
    }

    if (entries.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GuideDetailScreen(entry: entries.first),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AeroColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AeroColors.border),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AeroAvatar(size: 36, showBorder: false),
                  const SizedBox(width: 10),
                  Text(
                    '${cat.title} — FAQ Topics',
                    style: AeroTypography.titleMd,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final entry in entries) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.article_outlined,
                      color: AeroColors.neonBlue, size: 20),
                  title: Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AeroColors.textPrimary,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: AeroColors.textSecondary),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailScreen(entry: entry),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: AeroColors.border),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      // Tier 1 Header with clean no-ring avatar and rotating speech bubble
      appBar: AeroTopBar(
        phrases: AeroTopBar.guidePhrases,
      ),
      body: StreamBuilder<List<GuideEntry>>(
        stream: _guideStream,
        initialData: _initialEntries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AeroColors.neonBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading guide entries...',
                    style: TextStyle(color: AeroColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            // Offline fallback
            return FutureBuilder<List<GuideEntry>?>(
              future: _guideService.getCachedGuideEntries(),
              builder: (context, cacheSnapshot) {
                final cachedEntries = cacheSnapshot.data;
                if (cachedEntries != null && cachedEntries.isNotEmpty) {
                  return _buildGuideContent(cachedEntries, isOffline: true);
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AeroColors.errorRed),
                        const SizedBox(height: 16),
                        Text(
                          'Couldn\'t load guide entries. Check your connection.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AeroColors.textPrimary),
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
              },
            );
          }

          final allEntries = snapshot.data ?? [];

          if (allEntries.isEmpty) {
            // Check offline cache if Firestore returned empty
            return FutureBuilder<List<GuideEntry>?>(
              future: _guideService.getCachedGuideEntries(),
              builder: (context, cacheSnapshot) {
                final cachedEntries = cacheSnapshot.data;
                if (cachedEntries != null && cachedEntries.isNotEmpty) {
                  return _buildGuideContent(cachedEntries, isOffline: true);
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book,
                            size: 64, color: AeroColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No guide entries available yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Firestore collection "guideEntries" is currently empty.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AeroColors.textSecondary),
                        ),
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
              },
            );
          }

          return _buildGuideContent(allEntries, isOffline: false);
        },
      ),
    );
  }

  Widget _buildGuideContent(List<GuideEntry> allEntries, {required bool isOffline}) {
    // Categories with topic-specific icons and accent colors
    final categories = [
      _CategoryGroup(
        key: 'rfid',
        title: 'RFID & Tolls',
        description:
            'Transponder issues, toll zone discrepancies, and account linking.',
        icon: Icons.contactless_rounded,
        color: AeroColors.neonBlue,
      ),
      const _CategoryGroup(
        key: 'breakdown',
        title: 'Vehicle Status & Breakdown',
        description:
            'Battery optimization, tire pressure alerts, and emergency towing.',
        icon: Icons.car_repair_rounded,
        color: AeroColors.warningAmber,
      ),
      const _CategoryGroup(
        key: 'navigation',
        title: 'Expressway Navigation',
        description:
            'Interchange splits, missed exits, and speed limit rules.',
        icon: Icons.alt_route_rounded,
        color: Color(0xFF60A5FA),
      ),
      const _CategoryGroup(
        key: 'safety',
        title: 'Road Safety Protocols',
        description:
            'Severe weather, breakdown lane parking, and hazard protocols.',
        icon: Icons.shield_rounded,
        color: AeroColors.successEmerald,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dedicated Hero Space: Large Mascot Illustration alongside Page Heading
          AeroHeroHeaderRow(
            title: 'Quick Guide',
            subtitle:
                'Select a category for troubleshooting and assistance.',
            mascotSize: 108,
          ),

          const SizedBox(height: 16),

          if (isOffline)
            const AeroOfflineBanner(
              message: 'Offline — showing saved troubleshooting guides',
            ),

          // Expandable Accordion List
          for (final cat in categories) ...[
            _buildAccordionCategory(cat, allEntries),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // Need Human Assistance Card
          _buildContactSupportCard(context),
        ],
      ),
    );
  }

  Widget _buildAccordionCategory(
    _CategoryGroup cat,
    List<GuideEntry> allEntries,
  ) {
    final isExpanded = _expandedCategories.contains(cat.key);
    final categoryEntries = allEntries
        .where((e) => e.category.toLowerCase() == cat.key.toLowerCase())
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isExpanded
            ? AeroColors.surfaceContainerLow
            : AeroColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? cat.color.withValues(alpha: 0.45)
              : AeroColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: cat.color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : AeroGlow.subtleCardGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accordion Header Button
          AeroBouncyTap(
            scaleDown: 0.98,
            onTap: () => _toggleCategory(cat.key),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Topic-specific Category Icon Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        cat.icon,
                        size: 22,
                        color: cat.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      cat.title,
                      style: AeroTypography.titleMd,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded
                        ? cat.color
                        : AeroColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content Area
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 74.0,
                right: 16.0,
                bottom: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.description,
                    style: AeroTypography.bodySm,
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons: Troubleshoot & View FAQ with tactile bounce
                  Row(
                    children: [
                      AeroBouncyTap(
                        scaleDown: 0.94,
                        child: ElevatedButton(
                          onPressed: () {
                            if (categoryEntries.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GuideDetailScreen(
                                    entry: categoryEntries.first,
                                  ),
                                ),
                              );
                            } else {
                              AeroSnackBar.showInfo(
                                context,
                                'No troubleshooting entry available for ${cat.title}.',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AeroColors.surfaceContainer,
                            foregroundColor: AeroColors.textPrimary,
                            side: BorderSide(
                              color: AeroColors.outlineVariant,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Troubleshoot',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AeroBouncyTap(
                        scaleDown: 0.94,
                        child: TextButton(
                          onPressed: () => _showCategoryTopicsSheet(
                            context,
                            cat,
                            categoryEntries,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AeroColors.neonBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View FAQ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AeroColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AeroColors.border,
        ),
        boxShadow: AeroGlow.subtleCardGlow,
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: AeroColors.neonBlue,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Need human assistance?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AeroColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Connect directly to official 24/7 expressway patrol dispatchers and support teams.',
            style: TextStyle(
              fontSize: 12,
              color: AeroColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: AeroBouncyTap(
              scaleDown: 0.97,
              child: OutlinedButton.icon(
                onPressed: () {
                  MainNavigationScaffold.switchTab(context, 2);
                },
                icon: const Icon(Icons.phone, size: 16),
                label: const Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AeroColors.neonBlue,
                  side: BorderSide(color: AeroColors.neonBlue, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _CategoryGroup({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
