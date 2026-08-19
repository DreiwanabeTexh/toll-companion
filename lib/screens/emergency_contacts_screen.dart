import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import '../services/contacts_service.dart';

/// Emergency Contacts screen displaying official Tier 1 agency hotlines.
///
/// Features tap-to-call dialer launching via url_launcher and prominent
/// trust-critical verification status indicators.
class EmergencyContactsScreen extends StatefulWidget {
  final ContactsService? contactsService;

  const EmergencyContactsScreen({super.key, this.contactsService});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late final ContactsService _contactsService;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _contactsService = widget.contactsService ?? ContactsService();
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
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _contactsService.getEmergencyContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0088FF)),
                  SizedBox(height: 16),
                  Text(
                    'Loading emergency contacts...',
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
                      'Couldn\'t load emergency contacts. Check your connection.\n${snapshot.error}',
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

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_disabled,
                        size: 64, color: Color(0xFF8A919F)),
                    const SizedBox(height: 16),
                    const Text(
                      'No emergency contacts available yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3E2E2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firestore collection "emergencyContacts" is currently empty.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A919F)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isSeeding
                          ? null
                          : () async {
                              setState(() => _isSeeding = true);
                              await _contactsService.seedPlaceholderDataIfEmpty();
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
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Top Trust Banner
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Color(0xFFFF5252), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tier 1 Official Hotlines Only • Verified expressway authorities and patrol dispatchers.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF8A80),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              for (final contact in contacts) ...[
                _buildContactCard(contact),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 12),

              // Bottom Disclaimer
              Center(
                child: Text(
                  'Tap any number to open your phone dialer without auto-dialing.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Agency Name & Short Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    contact.agencyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE3E2E2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF0088FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    contact.agencyShort,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0088FF),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Coverage Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.alt_route, size: 16, color: Color(0xFF8A919F)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    contact.coverageArea,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC0C6D6),
                    ),
                  ),
                ),
              ],
            ),

            if (contact.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                contact.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A919F),
                  height: 1.3,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Verification Badge (Prominent)
            _buildVerificationBadge(contact),

            const SizedBox(height: 14),

            // Call Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _makeCall(contact),
                icon: const Icon(Icons.call, size: 18),
                label: Text(
                  'Call ${contact.displayNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F), // Emergency Red
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(EmergencyContact contact) {
    if (contact.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF00CC88).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF00CC88).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, size: 14, color: Color(0xFF00CC88)),
            const SizedBox(width: 4),
            Text(
              'Verified: ${_formatDate(contact.lastVerified!)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00CC88),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA000).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFFFA000).withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 14, color: Color(0xFFFFA000)),
            SizedBox(width: 4),
            Text(
              '⚠️ Not yet verified • Placeholder for testing',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFA000),
              ),
            ),
          ],
        ),
      );
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
