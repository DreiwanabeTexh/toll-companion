import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../models/route_model.dart';
import '../services/checklist_service.dart';
import '../theme.dart';

/// Pre-Trip Checklist screen (Phase 2).
///
/// Features an in-session toggleable checklist loosely connected
/// to the user's selected route, with category grouping and progress tracking.
class ChecklistScreen extends StatefulWidget {
  final ChecklistService? checklistService;
  final RouteModel? route;
  final Set<String>? involvedOperators;

  const ChecklistScreen({
    super.key,
    this.checklistService,
    this.route,
    this.involvedOperators,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late final ChecklistService _checklistService;
  late final Stream<List<ChecklistItem>> _checklistStream;
  final Set<String> _checkedItemIds = {};
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _checklistService = widget.checklistService ?? ChecklistService();
    _checklistStream = _checklistService.getChecklistItems();
  }

  void _toggleItem(String id) {
    setState(() {
      if (_checkedItemIds.contains(id)) {
        _checkedItemIds.remove(id);
      } else {
        _checkedItemIds.add(id);
      }
    });
  }

  void _resetChecklist() {
    setState(() {
      _checkedItemIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if arguments were passed via named route
    final routeArg =
        widget.route ?? (ModalRoute.of(context)?.settings.arguments as RouteModel?);

    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AeroColors.surfaceBase,
        title: Text(
          'Pre-Trip Checklist',
          style: TextStyle(color: AeroColors.textPrimary),
        ),
        iconTheme: IconThemeData(color: AeroColors.textPrimary),
        actions: [
          if (_checkedItemIds.isNotEmpty)
            TextButton.icon(
              onPressed: _resetChecklist,
              icon: Icon(Icons.restart_alt, size: 18, color: AeroColors.neonBlue),
              label: Text('Reset', style: TextStyle(color: AeroColors.neonBlue)),
            ),
        ],
      ),
      body: StreamBuilder<List<ChecklistItem>>(
        stream: _checklistStream,
        initialData: ChecklistService.defaultChecklistItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AeroColors.neonBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Loading checklist items...',
                    style: TextStyle(color: AeroColors.textSecondary),
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
                    const Icon(Icons.error_outline, size: 48, color: AeroColors.errorRed),
                    const SizedBox(height: 16),
                    Text(
                      'Couldn\'t load checklist. Check your connection.\n${snapshot.error}',
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
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist_rtl, size: 64, color: AeroColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No checklist items available yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Firestore collection "checklistItems" is currently empty.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AeroColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isSeeding
                          ? null
                          : () async {
                              setState(() => _isSeeding = true);
                              await _checklistService.seedPlaceholderDataIfEmpty();
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
                      label: const Text('Seed Sample Checklist Items'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalItems = items.length;
          final completedCount =
              items.where((item) => _checkedItemIds.contains(item.id)).length;
          final progress = totalItems > 0 ? completedCount / totalItems : 0.0;
          final isAllDone = totalItems > 0 && completedCount == totalItems;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Route Connection Banner (if route was selected)
              if (routeArg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AeroColors.neonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AeroColors.neonBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alt_route, color: AeroColors.neonBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRIP CONTEXT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AeroColors.neonBlue,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              routeArg.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AeroColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Progress Overview Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRIP READINESS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AeroColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount of $totalItems Ready',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AeroColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAllDone
                                ? AeroColors.successEmerald.withValues(alpha: 0.15)
                                : AeroColors.warningAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAllDone
                                  ? AeroColors.successEmerald.withValues(alpha: 0.4)
                                  : AeroColors.warningAmber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAllDone
                                    ? Icons.check_circle
                                    : Icons.pending_actions,
                                size: 14,
                                color: isAllDone
                                    ? AeroColors.successEmerald
                                    : AeroColors.warningAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAllDone ? 'Ready to Drive' : 'In Progress',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAllDone
                                      ? AeroColors.successEmerald
                                      : AeroColors.warningAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AeroColors.surfaceContainerLow,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAllDone
                              ? AeroColors.successEmerald
                              : AeroColors.neonBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Grouped Checklist Items
              _buildCategoryGroup(
                title: 'RFID & TOLL WALLETS',
                icon: Icons.account_balance_wallet,
                items: items.where((i) => i.category == 'rfid').toList(),
              ),

              _buildCategoryGroup(
                title: 'VEHICLE ROADWORTHINESS',
                icon: Icons.directions_car,
                items: items.where((i) => i.category == 'vehicle').toList(),
              ),

              _buildCategoryGroup(
                title: 'DRIVER & VEHICLE DOCUMENTS',
                icon: Icons.badge,
                items: items.where((i) => i.category == 'documents').toList(),
              ),

              _buildCategoryGroup(
                title: 'EMERGENCY & SAFETY GEAR',
                icon: Icons.emergency,
                items: items.where((i) => i.category == 'emergency').toList(),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Checklist state is saved locally for this active session.',
                  style: TextStyle(fontSize: 12, color: AeroColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroup({
    required String title,
    required IconData icon,
    required List<ChecklistItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AeroColors.neonBlue),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AeroColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => _buildChecklistCard(item)),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(ChecklistItem item) {
    final isChecked = _checkedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AeroColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked
              ? AeroColors.successEmerald.withValues(alpha: 0.4)
              : AeroColors.border,
          width: 1,
        ),
        boxShadow: AeroGlow.subtleCardGlow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleItem(item.id),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Checkbox
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isChecked
                      ? AeroColors.successEmerald
                      : AeroColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked
                        ? AeroColors.successEmerald
                        : AeroColors.border,
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isChecked
                                  ? AeroColors.textSecondary
                                  : AeroColors.textPrimary,
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (item.operator != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.operator == 'autosweep'
                                  ? AeroColors.successEmerald.withValues(alpha: 0.15)
                                  : AeroColors.neonBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: item.operator == 'autosweep'
                                    ? AeroColors.successEmerald.withValues(alpha: 0.4)
                                    : AeroColors.neonBlue.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              item.operator == 'autosweep'
                                  ? 'AUTOSWEEP'
                                  : 'EASYTRIP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: item.operator == 'autosweep'
                                    ? AeroColors.successEmerald
                                    : AeroColors.neonBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isChecked
                            ? AeroColors.textMuted
                            : AeroColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
