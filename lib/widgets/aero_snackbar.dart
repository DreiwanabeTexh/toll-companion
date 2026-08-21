import 'package:flutter/material.dart';
import '../theme.dart';

/// Theme-aware, high-contrast SnackBar utility for Aero.
///
/// Guarantees AAA contrast ratios in both Light Mode (Solar Lumina) and Dark Mode (Nocturnal Command).
class AeroSnackBar {
  /// Shows a success snackbar with an emerald check icon and high-contrast white text.
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final bgColor = AeroColors.isLight ? const Color(0xFF1E293B) : const Color(0xFF1F2020);
    final borderColor = AeroColors.successEmerald.withValues(alpha: 0.5);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: AeroColors.successEmerald,
                onPressed: action.onPressed,
              )
            : null,
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AeroColors.successEmerald,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows an error snackbar with a red alert icon and high-contrast white text.
  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final bgColor = AeroColors.isLight ? const Color(0xFF1E293B) : const Color(0xFF1F2020);
    final borderColor = AeroColors.errorRed.withValues(alpha: 0.6);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: AeroColors.errorRed,
                onPressed: action.onPressed,
              )
            : null,
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AeroColors.errorRed,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows an info snackbar with a neon blue info icon and high-contrast white text.
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final bgColor = AeroColors.isLight ? const Color(0xFF1E293B) : const Color(0xFF1F2020);
    final borderColor = AeroColors.neonBlue.withValues(alpha: 0.5);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 6,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: AeroColors.neonBlue,
                onPressed: action.onPressed,
              )
            : null,
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AeroColors.neonBlue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
