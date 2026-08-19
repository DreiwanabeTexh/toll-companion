import 'package:flutter/material.dart';
import '../theme.dart';

/// Unobtrusive banner indicating that the screen is displaying locally cached/offline data.
class AeroOfflineBanner extends StatelessWidget {
  final String message;

  const AeroOfflineBanner({
    super.key,
    this.message = 'Offline — showing saved data',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AeroColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AeroColors.warningAmber.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off,
            size: 16,
            color: AeroColors.warningAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AeroColors.warningAmber,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
