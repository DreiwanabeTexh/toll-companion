import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import '../services/contacts_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import '../widgets/aero_mascot.dart';
import '../widgets/aero_offline_banner.dart';
import '../widgets/report_dialog.dart';

/// Aero Emergency Contacts Screen featuring a dedicated animated hero mascot alongside the heading.
class EmergencyContactsScreen extends StatefulWidget {
  final ContactsService? contactsService;
  final bool isTab;

  const EmergencyContactsScreen({
    super.key,
    this.contactsService,
    this.isTab = false,
  });

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final ContactsService _contactsService;
  late final Stream<List<EmergencyContact>> _contactsStream;
  List<EmergencyContact>? _initialContacts;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _contactsService = widget.contactsService ?? ContactsService();
    _initialContacts = ContactsService.defaultContacts;
    _contactsStream = _contactsService.getEmergencyContacts();
    _loadInitialCache();
  }

  Future<void> _loadInitialCache() async {
    final cached = await _contactsService.getCachedEmergencyContacts();
    if (mounted) {
      setState(() {
        _initialContacts = cached;
      });
    }
    // Sync verified contacts to Firestore in background
    _contactsService.seedPlaceholderDataIfEmpty().catchError((_) {});
  }

  Future<void> _makeCall(EmergencyContact contact) async {
    final uri = Uri.parse(contact.telUri);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open dialer for ${contact.displayNumber}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialer error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      // Tier 1 Header with clean no-ring avatar and rotating speech bubble
      appBar: AeroTopBar(
        phrases: AeroTopBar.emergencyPhrases,
      ),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _contactsStream,
        initialData: _initialContacts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AeroColors.neonBlue),
                  SizedBox(height: 16),
                  Text(
                    'Loading emergency contacts...',
                    style: TextStyle(color: AeroColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            // Attempt offline fallback from local cache
            return FutureBuilder<List<EmergencyContact>?>(
              future: _contactsService.getCachedEmergencyContacts(),
              builder: (context, cacheSnapshot) {
                final cachedContacts = cacheSnapshot.data;
                if (cachedContacts != null && cachedContacts.isNotEmpty) {
                  return _buildContactsList(cachedContacts, isOffline: true);
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
                          'Couldn\'t load emergency contacts. Check your connection.\n${snapshot.error}',
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

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            // Check cache if Firestore returned empty
            return FutureBuilder<List<EmergencyContact>?>(
              future: _contactsService.getCachedEmergencyContacts(),
              builder: (context, cacheSnapshot) {
                final cachedContacts = cacheSnapshot.data;
                if (cachedContacts != null && cachedContacts.isNotEmpty) {
                  return _buildContactsList(cachedContacts, isOffline: true);
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contact_phone,
                            size: 64, color: AeroColors.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No emergency contacts available yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AeroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Firestore collection "emergencyContacts" is currently empty.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AeroColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isSeeding
                              ? null
                              : () async {
                                  setState(() => _isSeeding = true);
                                  await _contactsService
                                      .seedPlaceholderDataIfEmpty();
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
                          label: const Text('Seed Sample Tier 1 Hotlines'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return _buildContactsList(contacts, isOffline: false);
        },
      ),
    );
  }

  Widget _buildContactsList(List<EmergencyContact> contacts, {required bool isOffline}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Dedicated Hero Space: Large Mascot Illustration alongside Page Heading
        AeroHeroHeaderRow(
          title: 'Emergency',
          subtitle: 'Verified Highway Patrol & Assist',
          mascotSize: 84,
        ),

        const SizedBox(height: 16),

        if (isOffline)
          const AeroOfflineBanner(
            message: 'Offline — showing saved emergency contacts',
          ),

        for (final contact in contacts) ...[
          _buildContactCard(contact),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 8),

        // Bottom Disclaimer
        Center(
          child: Text(
            'Tap "CALL NOW" to launch your device dialer without auto-dialing.',
            style: TextStyle(fontSize: 11, color: AeroColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
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
          // Top Row: Agency Name & Verification Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.agencyName,
                      style: AeroTypography.titleMd,
                    ),
                    if (contact.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.description,
                        style: AeroTypography.bodySm,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildVerificationBadge(contact),
            ],
          ),

          const SizedBox(height: 12),

          // Hotline Number Display
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: AeroColors.neonBlue),
              const SizedBox(width: 6),
              Text(
                contact.displayNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AeroColors.neonBlue,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Coverage Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.map, size: 15, color: AeroColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  contact.coverageArea,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AeroColors.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 24/7 Response Tag + Report Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: AeroColors.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    '24/7 Rapid Response Dispatch',
                    style: TextStyle(
                      fontSize: 11,
                      color: AeroColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Report Discrepancy Action Button
              AeroBouncyTap(
                scaleDown: 0.92,
                onTap: () => ReportDialog.show(
                  context,
                  reportType: 'emergency_contact',
                  targetId: contact.id,
                  targetName: contact.agencyName,
                  contextData: {
                    'displayNumber': contact.displayNumber,
                    'coverageArea': contact.coverageArea,
                  },
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, size: 12, color: AeroColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Report info',
                        style: TextStyle(fontSize: 11, color: AeroColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Call Now Button (56px) with tactile bounce
          AeroBouncyTap(
            scaleDown: 0.96,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(contact),
                icon: const Icon(Icons.call, size: 20, color: Colors.white),
                label: const Text(
                  'CALL NOW',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeroColors.neonBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 6,
                  shadowColor: AeroColors.neonBlue.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(EmergencyContact contact) {
    if (contact.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AeroColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AeroColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 13, color: AeroColors.neonBlue),
            const SizedBox(width: 4),
            Text(
              'VERIFIED ${_formatDate(contact.lastVerified!)}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AeroColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AeroColors.warningAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: AeroColors.warningAmber.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 13, color: AeroColors.warningAmber),
          SizedBox(width: 4),
          Text(
            'NOT YET VERIFIED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AeroColors.warningAmber,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return '$month/$year';
  }
}
