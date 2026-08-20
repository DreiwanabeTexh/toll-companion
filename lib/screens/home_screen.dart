import 'package:flutter/material.dart';
import '../models/recent_trip.dart';
import '../services/cache_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import '../widgets/aero_mascot.dart';
import 'main_navigation_scaffold.dart';

/// Aero Home Screen — Driver Dashboard featuring local RFID balance tracking,
/// genuine calculation history, and dedicated animated hero mascot space.
class HomeScreen extends StatefulWidget {
  final CacheService? cacheService;

  const HomeScreen({super.key, this.cacheService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CacheService _cacheService;
  String _driverName = 'Driver';
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
    final savedName = await _cacheService.getDriverName();
    if (mounted) {
      setState(() {
        _driverName = (savedName != null && savedName.trim().isNotEmpty)
            ? savedName.trim()
            : 'Driver';
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
          side: BorderSide(color: AeroColors.border),
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
              Text(
                'Enter your current wallet balance:',
                style: TextStyle(fontSize: 13, color: AeroColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AeroColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AeroColors.neonBlue,
                  ),
                  filled: true,
                  fillColor: AeroColors.surfaceBase,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AeroColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AeroColors.neonBlue, width: 1.5),
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
              Text(
                'Tip: Balances are saved locally on your device for offline trip planning.',
                style: TextStyle(fontSize: 11, color: AeroColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AeroColors.textSecondary)),
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
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AeroColors.successEmerald,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$operatorName balance updated to ₱${newAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AeroColors.surfaceCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AeroColors.successEmerald.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      duration: const Duration(seconds: 3),
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
          side: BorderSide(color: AeroColors.border),
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
              Text(
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
            child: Text('Got it', style: TextStyle(color: AeroColors.neonBlue)),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AeroColors.neonBlue,
            ),
          ),
          Text(
            details,
            style: TextStyle(fontSize: 11, color: AeroColors.textSecondary),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
      appBar: AeroHomeAppBar(
        driverName: _driverName,
        onNameChanged: (newName) {
          if (mounted) {
            setState(() {
              _driverName = newName.trim().isNotEmpty ? newName.trim() : 'Driver';
            });
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AeroColors.neonBlue,
        backgroundColor: AeroColors.surfaceCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        Text(
                          'Expressway Radar Active',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
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

            const SizedBox(height: 16),

            // Pill-shaped Search Bar (rounded-full)
            AeroBouncyTap(
              scaleDown: 0.98,
              onTap: () {
                MainNavigationScaffold.switchTab(context, 1);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AeroColors.surfaceCard,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AeroColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AeroColors.outlineVariant, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search routes, tolls, interchanges...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AeroColors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: AeroColors.outlineVariant, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Toll Balances Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
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
                  child: Text(
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
            _buildBalanceCard(
              operatorName: 'Autosweep RFID',
              tag: 'AUTOSWEEP RFID',
              balance: _autosweepBalance,
            ),

            const SizedBox(height: 12),

            // 2. EasyTrip Card (Full Width)
            _buildBalanceCard(
              operatorName: 'EasyTrip RFID',
              tag: 'EASYTRIP RFID',
              balance: _easytripBalance,
            ),

            const SizedBox(height: 24),

            // Recent Routes Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
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
                  child: Text(
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

            // Recent Routes Container (Genuine History / Empty State)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recentTrips.isEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AeroColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AeroColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AeroColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                        border: Border.all(color: AeroColors.border),
                      ),
                      child: Icon(
                        Icons.alt_route,
                        size: 26,
                        color: AeroColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No routes calculated yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Calculate any exit-to-exit corridor fare in the Tolls tab to save your trip history here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AeroColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AeroColors.neonBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: () => MainNavigationScaffold.switchTab(context, 1),
                      icon: const Icon(Icons.calculate, size: 16),
                      label: const Text(
                        'Plan a Trip',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
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
    ),
  );
}

  Widget _buildBalanceCard({
    required String operatorName,
    required String tag,
    required double balance,
  }) {
    return Container(
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
              Text(
                tag,
                style: AeroTypography.labelCaps,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Electric Blue Balance Amount Display (Original Color)
          Text(
            '₱${balance.toStringAsFixed(2)}',
            style: AeroTypography.displayLg,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceStatus(balance),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button: Electric Blue text & icon, Electric Blue outline (Original Position & Color)
                  AeroBouncyTap(
                    scaleDown: 0.92,
                    onTap: () => _showEditBalanceDialog(operatorName, balance),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AeroColors.surfaceBase,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AeroColors.neonBlue,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 12, color: AeroColors.neonBlue),
                          SizedBox(width: 4),
                          Text(
                            'EDIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AeroColors.neonBlue,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Top Up Button: Electric Blue text, Electric Blue outline (Original Position & Color)
                  AeroBouncyTap(
                    scaleDown: 0.94,
                    onTap: () => _showTopUpDialog(context, operatorName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AeroColors.surfaceBase,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AeroColors.neonBlue,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        'TOP UP',
                        style: TextStyle(
                          fontSize: 11,
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
        ],
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
              useSkyway: trip.useSkyway,
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
                  child: Icon(
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
                        style: TextStyle(
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
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AeroColors.neonBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: trip.useSkyway
                                  ? AeroColors.neonBlue.withValues(alpha: 0.12)
                                  : AeroColors.emeraldGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              trip.useSkyway ? 'Skyway' : 'At-Grade',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: trip.useSkyway
                                    ? AeroColors.neonBlue
                                    : AeroColors.emeraldGreen,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.corridors.join(' · '),
                        style: TextStyle(
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
          Divider(height: 1, color: AeroColors.border),
      ],
    );
  }
}
