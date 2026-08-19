import 'package:flutter/material.dart';
import '../models/recent_trip.dart';
import '../services/cache_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import '../widgets/aero_mascot.dart';
import 'main_navigation_scaffold.dart';

/// Aero Home Screen — Driver Dashboard featuring personalized RFID balance tracking,
/// dynamic recent calculations & favorites, and dedicated animated hero mascot space.
class HomeScreen extends StatefulWidget {
  final CacheService? cacheService;

  const HomeScreen({super.key, this.cacheService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CacheService _cacheService;
  double _autosweepBalance = 1250.0;
  double _easytripBalance = 840.50;
  List<RecentTrip> _recentTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cacheService = widget.cacheService ?? CacheService();
    _loadData();
  }

  Future<void> _loadData() async {
    final balances = await _cacheService.getRfidBalances();
    final trips = await _cacheService.getRecentTrips();
    if (mounted) {
      setState(() {
        _autosweepBalance = balances['autosweep'] ?? 1250.0;
        _easytripBalance = balances['easytrip'] ?? 840.50;
        _recentTrips = trips;
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditBalanceDialog(String operatorName, double currentBalance) async {
    final isAutosweep = operatorName.toLowerCase().contains('auto');
    final controller = TextEditingController(text: currentBalance.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AeroColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AeroColors.border),
        ),
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: isAutosweep ? AeroColors.neonBlue : AeroColors.successEmerald,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Update $operatorName Balance',
                style: AeroTypography.titleMd,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your current wallet balance:',
                style: TextStyle(fontSize: 13, color: AeroColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AeroColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AeroColors.neonBlue,
                  ),
                  filled: true,
                  fillColor: AeroColors.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AeroColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AeroColors.neonBlue, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter an amount';
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 0) return 'Please enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Tip: Balances are saved locally on your device for offline trip planning.',
                style: TextStyle(fontSize: 11, color: AeroColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AeroColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AeroColors.neonBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newAmount = double.parse(controller.text.trim());
                if (isAutosweep) {
                  _autosweepBalance = newAmount;
                } else {
                  _easytripBalance = newAmount;
                }
                await _cacheService.saveRfidBalances(
                  autosweep: _autosweepBalance,
                  easytrip: _easytripBalance,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$operatorName balance updated to ₱${newAmount.toStringAsFixed(2)}'),
                      backgroundColor: AeroColors.surfaceCard,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Balance'),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, String operatorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AeroColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AeroColors.border),
        ),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: operatorName.toLowerCase().contains('auto')
                  ? AeroColors.neonBlue
                  : AeroColors.successEmerald,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$operatorName Top-Up Guide',
                style: AeroTypography.titleMd,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Official Reload Channels:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AeroColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildChannelItem('📱 Mobile Wallets', 'GCash, Maya, ShopeePay'),
              _buildChannelItem('🏪 Convenience Stores', '7-Eleven CLIQQ, Ministop/Uncle John\'s'),
              _buildChannelItem('⛽ Expressway Stations', 'Petron, Shell, Caltex service kiosks'),
              _buildChannelItem('🏦 Online Banking', 'BPI, BDO, UnionBank, Metrobank'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AeroColors.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AeroColors.warningAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Note: Allow 5-15 minutes for balance crediting before approaching toll gates.',
                  style: TextStyle(fontSize: 11, color: AeroColors.warningAmber),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static Widget _buildChannelItem(String title, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AeroColors.neonBlue,
            ),
          ),
          Text(
            details,
            style: const TextStyle(fontSize: 11, color: AeroColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStatus(double balance) {
    Color color;
    String label;

    if (balance >= 200.0) {
      color = AeroColors.successEmerald;
      label = 'Active';
    } else if (balance > 0) {
      color = AeroColors.warningAmber;
      label = 'Low Balance';
    } else {
      color = AeroColors.errorRed;
      label = 'Depleted';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(String tripId) async {
    await _cacheService.toggleFavoriteTrip(tripId);
    final updated = await _cacheService.getRecentTrips();
    if (mounted) {
      setState(() {
        _recentTrips = updated;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24 && now.day == timestamp.day) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final min = timestamp.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$min';
    } else if (diff.inHours < 48) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final min = timestamp.minute.toString().padLeft(2, '0');
      return 'Yesterday, $hour:$min';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      appBar: const AeroHomeAppBar(
        driverName: 'Driver',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dedicated Mascot Hero Card on Home Dashboard
            Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AeroColors.neonBlue.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AeroColors.neonBlue.withValues(alpha: 0.12),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  const AeroAnimatedHeroMascot(
                    size: 114,
                    showGlow: false,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AeroColors.successEmerald,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'AERO CO-PILOT READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AeroColors.successEmerald,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Expressway Radar Active',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track toll balances, estimate corridor fares, and access 24/7 highway dispatch.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AeroColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Pill-shaped Search Bar (rounded-full)
            Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AeroColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AeroColors.outlineVariant, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(
                        fontSize: 14,
                        color: AeroColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search routes, tolls, interchanges...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AeroColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) {
                        MainNavigationScaffold.switchTab(context, 1);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Balances Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: AeroColors.neonBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toll Balances',
                      style: AeroTypography.titleMd,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AeroColors.neonBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AeroColors.neonBlue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'LOCAL TRACKING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AeroColors.neonBlue,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 1. Autosweep Card (Full Width)
            Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AeroColors.border),
                boxShadow: AeroGlow.subtleCardGlow,
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AUTOSWEEP RFID',
                        style: AeroTypography.labelCaps,
                      ),
                      AeroBouncyTap(
                        scaleDown: 0.92,
                        onTap: () => _showEditBalanceDialog('Autosweep RFID', _autosweepBalance),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AeroColors.neonBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 13, color: AeroColors.neonBlue),
                              SizedBox(width: 4),
                              Text(
                                'EDIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AeroColors.neonBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${_autosweepBalance.toStringAsFixed(2)}',
                    style: AeroTypography.displayLg,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceStatus(_autosweepBalance),
                      AeroBouncyTap(
                        scaleDown: 0.94,
                        onTap: () => _showTopUpDialog(context, 'Autosweep RFID'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AeroColors.neonBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TOP UP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AeroColors.neonBlue,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. EasyTrip Card (Full Width)
            Container(
              decoration: BoxDecoration(
                color: AeroColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AeroColors.border),
                boxShadow: AeroGlow.subtleCardGlow,
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EASYTRIP RFID',
                        style: AeroTypography.labelCaps,
                      ),
                      AeroBouncyTap(
                        scaleDown: 0.92,
                        onTap: () => _showEditBalanceDialog('EasyTrip RFID', _easytripBalance),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AeroColors.neonBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 13, color: AeroColors.neonBlue),
                              SizedBox(width: 4),
                              Text(
                                'EDIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AeroColors.neonBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${_easytripBalance.toStringAsFixed(2)}',
                    style: AeroTypography.displayLg,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceStatus(_easytripBalance),
                      AeroBouncyTap(
                        scaleDown: 0.94,
                        onTap: () => _showTopUpDialog(context, 'EasyTrip RFID'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AeroColors.neonBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TOP UP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AeroColors.neonBlue,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Routes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.route,
                      color: AeroColors.neonBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Routes',
                      style: AeroTypography.titleMd,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    MainNavigationScaffold.switchTab(context, 1);
                  },
                  child: const Text(
                    'Calculate New',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AeroColors.neonBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Recent Routes Container
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recentTrips.isEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AeroColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AeroColors.border),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.alt_route, size: 36, color: AeroColors.textSecondary),
                    const SizedBox(height: 10),
                    const Text(
                      'No calculated routes yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Calculate any exit-to-exit corridor fare in the Tolls tab to save your trip history here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AeroColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AeroColors.neonBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => MainNavigationScaffold.switchTab(context, 1),
                      icon: const Icon(Icons.calculate, size: 16),
                      label: const Text('Plan a Trip'),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AeroColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AeroColors.border),
                  boxShadow: AeroGlow.subtleCardGlow,
                ),
                child: Column(
                  children: List.generate(_recentTrips.length, (index) {
                    final trip = _recentTrips[index];
                    final showDivider = index < _recentTrips.length - 1;
                    return _buildRecentTripTile(trip, showDivider);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTripTile(RecentTrip trip, bool showDivider) {
    return Column(
      children: [
        AeroBouncyTap(
          scaleDown: 0.98,
          onTap: () {
            MainNavigationScaffold.switchTabWithRoute(
              context,
              originId: trip.originId,
              destinationId: trip.destinationId,
              vehicleClass: trip.vehicleClass,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Route Direction Icon Circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AeroColors.surfaceBase,
                    shape: BoxShape.circle,
                    border: Border.all(color: AeroColors.border),
                  ),
                  child: const Icon(
                    Icons.directions,
                    size: 20,
                    color: AeroColors.neonBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${trip.originName} → ${trip.destinationName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AeroColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _formatTimestamp(trip.timestamp),
                              style: AeroTypography.bodySm,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AeroColors.surfaceBase,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Class ${trip.vehicleClass}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AeroColors.neonBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₱${trip.totalFare.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.corridors.join(' · '),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AeroColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    trip.isFavorite ? Icons.star : Icons.star_border,
                    color: trip.isFavorite ? AeroColors.warningAmber : AeroColors.outlineVariant,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(trip.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AeroColors.border),
      ],
    );
  }
}

