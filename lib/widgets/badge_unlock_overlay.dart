import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/gamification/models/gamification_models.dart';

class BadgeUnlockOverlay {
  /// Shows the badge unlock celebration. Awaitable — resolves when dismissed.
  static Future<void> show(BuildContext context, BadgeDef badge) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'badge_unlock',
      barrierColor: Colors.black.withValues(alpha: 0.70),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, anim, _) =>
          _BadgeUnlockDialog(badge: badge),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeIn,
        );
        return ScaleTransition(
          scale: Tween(begin: 0.65, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
    );
  }
}

class _BadgeUnlockDialog extends StatefulWidget {
  final BadgeDef badge;
  const _BadgeUnlockDialog({required this.badge});

  @override
  State<_BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<_BadgeUnlockDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    // Auto-dismiss after 4 s so users with fast workflows aren't blocked.
    _autoClose = Timer(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final rarity = badge.rarity;
    final rarityColor = rarity.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: rarityColor.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.30),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header label
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: rarity.gradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🎉  Achievement Unlocked!',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3),
              ),
            ),
            const SizedBox(height: 24),

            // Glowing emoji with pulse animation
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      rarityColor.withValues(alpha: 0.25),
                      rarityColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    badge.emoji,
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Badge name
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // XP reward + rarity row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (badge.xpReward > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: rarityColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '+${badge.xpReward} XP',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: rarityColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: rarity.gradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rarity.label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dismiss button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: rarityColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Awesome! Keep going',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
