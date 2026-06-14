import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/break_reminder/models/break_reminder_result.dart';
import '../features/mood/models/mood_entry.dart';
import '../services/local_notification_service.dart';
import '../theme/app_colors.dart';

class BreakReminderBanner extends StatelessWidget {
  final BreakReminderResult result;

  /// Called when the user taps "Take a break now".
  final VoidCallback onBreakTaken;

  /// Called when the user taps "Remind in 15m" (after notification is scheduled).
  final VoidCallback onSnoozed;

  const BreakReminderBanner({
    super.key,
    required this.result,
    required this.onBreakTaken,
    required this.onSnoozed,
  });

  @override
  Widget build(BuildContext context) {
    final mood = result.mood;
    final accent = _accentColor(mood);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Icon(_icon(mood), color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Break time',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent),
                    ),
                    Text(
                      '${result.minutesWorked}m worked · ${result.thresholdMins}m interval',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: context.colText2),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.progressFraction,
              minHeight: 5,
              backgroundColor: context.colDivider,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),

          const SizedBox(height: 12),

          // ── Message ──────────────────────────────────────────────────────
          Text(
            result.message,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colText1,
                height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            result.subMessage,
            style: GoogleFonts.inter(
                fontSize: 12, color: context.colText2, height: 1.4),
          ),

          const SizedBox(height: 14),

          // ── Actions ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await LocalNotificationService.cancelBreakReminder();
                    onBreakTaken();
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Take a break now',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final fireAt =
                        DateTime.now().add(const Duration(minutes: 15));
                    await LocalNotificationService.scheduleBreakReminder(
                      fireAt,
                      mood: result.mood,
                    );
                    onSnoozed();
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colDivider),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Remind in 15m',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colText2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _accentColor(MoodType? mood) => switch (mood) {
        MoodType.tired => const Color(0xFF64748B),
        MoodType.stressed => const Color(0xFFF97316),
        MoodType.motivated => AppColors.primary,
        MoodType.happy => const Color(0xFF22C55E),
        null => AppColors.primary,
      };

  IconData _icon(MoodType? mood) => switch (mood) {
        MoodType.tired => Icons.bedtime_outlined,
        MoodType.stressed => Icons.self_improvement_rounded,
        MoodType.motivated => Icons.local_fire_department_rounded,
        _ => Icons.coffee_outlined,
      };
}
