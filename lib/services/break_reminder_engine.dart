import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';
import '../features/break_reminder/models/break_reminder_result.dart';
import '../features/mood/models/mood_entry.dart';

/// Detects long work sessions and generates friendly break reminders.
///
/// Thresholds are mood-aware — tired/stressed users get shorter intervals.
/// All signals are derived from local storage; no network call needed.
class BreakReminderEngine {
  BreakReminderEngine._();

  static const _kLastBreak = 'break_last_at';

  // ── Mood-based work interval thresholds (minutes) ─────────────────────────

  static int threshold(MoodType? mood) => switch (mood) {
        MoodType.tired => 40,
        MoodType.stressed => 50,
        MoodType.motivated => 80,
        MoodType.happy => 90,
        null => 90,
      };

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<BreakReminderResult> analyze() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Load current mood
    final moodRaw = prefs.getString('wellness_mood');
    final mood = moodRaw != null ? MoodTypeX.fromStorage(moodRaw) : null;
    final limit = threshold(mood);

    // Last break timestamp
    final lastBreakRaw = prefs.getString(_kLastBreak);
    DateTime? lastBreakAt;
    if (lastBreakRaw != null) {
      try {
        lastBreakAt = DateTime.parse(lastBreakRaw);
      } catch (_) {}
    }

    // Count focused minutes since the last break (or since today's midnight)
    final since = lastBreakAt ?? DateTime(now.year, now.month, now.day);
    final sessions = LocalStorage.getFocusHistory()
        .whereType<Map<String, dynamic>>()
        .where((s) {
          try {
            return DateTime.parse(s['startedAt'] as String).isAfter(since);
          } catch (_) {
            return false;
          }
        })
        .toList();

    final minutesWorked = sessions.fold<int>(
        0, (sum, s) => sum + ((s['actualMins'] as num?)?.toInt() ?? 0));

    final isBreakDue = minutesWorked >= limit;

    return BreakReminderResult(
      isBreakDue: isBreakDue,
      minutesWorked: minutesWorked,
      thresholdMins: limit,
      message: _message(isBreakDue, minutesWorked, limit, mood),
      subMessage: _subMessage(isBreakDue, minutesWorked, limit, mood),
      lastBreakAt: lastBreakAt,
      mood: mood,
    );
  }

  /// Call when the user takes a break. Resets the work clock.
  static Future<void> recordBreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastBreak, DateTime.now().toIso8601String());
  }

  // ── Message generation ─────────────────────────────────────────────────────

  static String _message(
      bool due, int worked, int limit, MoodType? mood) {
    if (!due) {
      final remaining = limit - worked;
      if (worked == 0) return 'No sessions recorded yet today.';
      return '${worked}m focused — next break in ${remaining}m.';
    }

    return switch (mood) {
      MoodType.tired =>
        'You\'re tired and have been working ${worked}m. Please step away.',
      MoodType.stressed =>
        'You\'ve worked ${worked}m while stressed. A break will help more than pushing on.',
      MoodType.motivated =>
        'Impressive ${worked}m session! Even peak performers need recovery time.',
      MoodType.happy =>
        'You\'ve been focused for ${worked}m. A quick break keeps the momentum going.',
      null =>
        'You\'ve been working for ${worked}m. Time to recharge.',
    };
  }

  static String _subMessage(
      bool due, int worked, int limit, MoodType? mood) {
    if (!due) {
      if (worked == 0) return 'Complete a focus session to start tracking.';
      return 'You\'re doing well — keep the pace.';
    }

    // Rotate through friendly suggestions
    final tips = [
      'Step outside for 5 minutes — sunlight resets your focus.',
      'Stretch your neck and shoulders. Two minutes makes a difference.',
      'Get a glass of water. Hydration sustains cognitive performance.',
      'Close your eyes and breathe deeply for 60 seconds.',
      'A short walk — even inside — clears mental fatigue.',
    ];
    // Deterministic tip based on minutes worked so it's stable across builds
    return tips[worked % tips.length];
  }
}
