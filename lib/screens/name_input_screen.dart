import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../theme.dart';
import '../widgets/aero_animations.dart';
import '../widgets/aero_mascot.dart';
import 'main_navigation_scaffold.dart';

/// Mandatory Driver Name Personalization Screen (First-Launch Only).
///
/// Features:
/// - Friendly heading & mascot avatar
/// - Clean text input with auto-focus, word capitalization, and character length limit
/// - Required validation: "Continue" button is strictly disabled until non-empty input is provided
/// - Saves `driver_name` and sets `onboarding_complete = true` in local storage
/// - Seamless transition to [MainNavigationScaffold]
class NameInputScreen extends StatefulWidget {
  final CacheService? cacheService;

  const NameInputScreen({super.key, this.cacheService});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  late final CacheService _cacheService;
  bool _isValidName = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cacheService = widget.cacheService ?? CacheService();

    _nameController.addListener(() {
      final isValid = _nameController.text.trim().isNotEmpty;
      if (isValid != _isValidName) {
        setState(() {
          _isValidName = isValid;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    await _cacheService.setDriverName(name);
    await _cacheService.setOnboardingComplete(true);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const MainNavigationScaffold(),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AeroColors.surfaceBase,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const AeroAvatar(size: 36, showBorder: false),
            const SizedBox(width: 10),
            Text(
              'Driver Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AeroColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Friendly Heading
              Text(
                'What should we call you?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AeroColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 10),

              // Explanatory Subtitle
              Text(
                'We\'ll use this to personalize your expressway dashboard and travel briefings.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AeroColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Name Input Field
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isValidName ? _submitName() : null,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AeroColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your name (e.g. Alex)',
                  hintStyle: TextStyle(
                    color: AeroColors.textSecondary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AeroColors.neonBlue,
                    size: 22,
                  ),
                  counterStyle: TextStyle(
                    color: AeroColors.textSecondary,
                    fontSize: 11,
                  ),
                  filled: true,
                  fillColor: AeroColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AeroColors.border,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AeroColors.neonBlue,
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Required "Continue" Button
              SizedBox(
                width: double.infinity,
                child: AeroBouncyTap(
                  scaleDown: _isValidName ? 0.97 : 1.0,
                  child: ElevatedButton(
                    onPressed: _isValidName && !_isSaving ? _submitName : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValidName
                          ? AeroColors.neonBlue
                          : AeroColors.surfaceContainerHighest,
                      foregroundColor: _isValidName
                          ? Colors.white
                          : AeroColors.textSecondary,
                      disabledBackgroundColor:
                          AeroColors.surfaceContainerLow.withValues(alpha: 0.8),
                      disabledForegroundColor:
                          AeroColors.textSecondary.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: _isValidName ? 4 : 0,
                      shadowColor: _isValidName
                          ? AeroColors.neonBlue.withValues(alpha: 0.5)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: _isValidName
                              ? AeroColors.neonBlue
                              : AeroColors.border,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
