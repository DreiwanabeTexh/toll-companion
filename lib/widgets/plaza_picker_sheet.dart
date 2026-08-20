import 'package:flutter/material.dart';
import '../models/toll_plaza.dart';
import '../theme.dart';

/// Modal bottom sheet for searching and selecting expressway exits / toll plazas.
///
/// Features:
/// - Live instant search across plaza names, expressway codes, and operators
/// - Quick-filter chips for each expressway network (ALL, SLEX, NLEX, STAR, SKYWAY, etc.)
/// - Dark Nocturnal Command styling with Electric Blue accents and operator badges
class PlazaPickerSheet extends StatefulWidget {
  final String title;
  final List<TollPlaza> plazas;
  final String? selectedPlazaId;

  const PlazaPickerSheet({
    super.key,
    required this.title,
    required this.plazas,
    this.selectedPlazaId,
  });

  static Future<TollPlaza?> show({
    required BuildContext context,
    required String title,
    required List<TollPlaza> plazas,
    String? selectedPlazaId,
  }) {
    return showModalBottomSheet<TollPlaza>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlazaPickerSheet(
        title: title,
        plazas: plazas,
        selectedPlazaId: selectedPlazaId,
      ),
    );
  }

  @override
  State<PlazaPickerSheet> createState() => _PlazaPickerSheetState();
}

class _PlazaPickerSheetState extends State<PlazaPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedExpresswayFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _expresswayFilters {
    final Set<String> expressways = {'ALL'};
    for (final p in widget.plazas) {
      if (p.expressway.isNotEmpty) {
        expressways.add(p.expressway);
      }
    }
    return expressways.toList();
  }

  List<TollPlaza> get _filteredPlazas {
    return widget.plazas.where((plaza) {
      // 1. Expressway filter
      if (_selectedExpresswayFilter != 'ALL' &&
          plaza.expressway != _selectedExpresswayFilter) {
        return false;
      }

      // 2. Text search filter
      if (_searchQuery.isNotEmpty) {
        final nameMatches = plaza.name.toLowerCase().contains(_searchQuery);
        final expresswayMatches =
            plaza.expresswayName.toLowerCase().contains(_searchQuery) ||
                plaza.expressway.toLowerCase().contains(_searchQuery);
        final operatorMatches =
            plaza.operator.toLowerCase().contains(_searchQuery);
        return nameMatches || expresswayMatches || operatorMatches;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.85,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: AeroColors.surfaceBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AeroColors.border, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AeroColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AeroTypography.titleMd.copyWith(fontSize: 18),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AeroColors.textSecondary),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AeroColors.border),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: TextStyle(
                  color: AeroColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search exit name, expressway (e.g. SLEX, Lipa)...',
                  hintStyle: TextStyle(
                    color: AeroColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AeroColors.neonBlue,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: AeroColors.textSecondary, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _expresswayFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _expresswayFilters[index];
                final isSelected = filter == _selectedExpresswayFilter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AeroColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AeroColors.neonBlue,
                  backgroundColor: AeroColors.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                    side: BorderSide(
                      color: isSelected
                          ? AeroColors.neonBlue
                          : AeroColors.border,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedExpresswayFilter = filter;
                      });
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Plaza List
          Expanded(
            child: _filteredPlazas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: AeroColors.textSecondary,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No expressway exits found',
                            style: AeroTypography.titleMd
                                .copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching by another exit name or expressway.',
                            style: TextStyle(
                              color: AeroColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _filteredPlazas.length,
                    separatorBuilder: (_, _) => Divider(
                      color: AeroColors.border,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final plaza = _filteredPlazas[index];
                      final isSelected =
                          plaza.id == widget.selectedPlazaId;
                      final isAutosweep =
                          plaza.operator.toLowerCase() == 'autosweep';

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(plaza),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 8.0),
                          child: Row(
                            children: [
                              // Pin Indicator
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AeroColors.neonBlue.withValues(alpha: 0.15)
                                      : AeroColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AeroColors.neonBlue
                                        : AeroColors.border,
                                  ),
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check
                                      : Icons.place_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? AeroColors.neonBlue
                                      : AeroColors.textSecondary,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Name & Expressway
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plaza.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AeroColors.neonBlue
                                            : AeroColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            plaza.expresswayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AeroColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        if (plaza.isInterchange) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AeroColors
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'INTERCHANGE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AeroColors.primaryTint,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Operator Tag Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAutosweep
                                      ? AeroColors.successEmerald.withValues(alpha: 0.15)
                                      : AeroColors.neonBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isAutosweep
                                        ? AeroColors.successEmerald
                                            .withValues(alpha: 0.4)
                                        : AeroColors.neonBlue
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  isAutosweep ? 'AUTOSWEEP' : 'EASYTRIP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isAutosweep
                                        ? AeroColors.successEmerald
                                        : AeroColors.neonBlue,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
