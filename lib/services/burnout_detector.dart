import 'package:shared_preferences/shared_preferences.dart';
import 'health_engine.dart';
import 'local_storage.dart';
import '../features/burnout/models/burnout_result.dart';
import '../features/mood/models/mood_entry.dart';

/// Fully offline burnout risk analyser.
/// Aggregates seven signals from local storage and SharedPreferences,
/// weights them, and returns a [BurnoutResult] with warnings and
/// low-priority task rescheduling suggestions.
class BurnoutDetector {
  BurnoutDetector._();

  // ── Signal weights (must sum to 1.0) ───────────────────────────────────────
  static const _wTasks = 0.18;
  static const _wDeadlines = 0.17;
  static const _wMissed = 0.15;
  static const _wMood = 0.16;
  static const _wSleep = 0.16;
  static const _wWorkHours = 0.12;
  static const _wStrength = 0.06;

  static Future<BurnoutResult> analyze() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // ── 1. Wellness signals ────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final moodRaw = prefs.getString('wellness_mood') ?? MoodType.happy.storageKey;
    final mood = MoodTypeX.fromStorage(moodRaw);
    final strength = prefs.getString('wellness_strength') ?? 'Beginner';

    // Prefer today's HealthEngine check-in (precise double from slider);
    // fall back to the profile-screen integer when no check-in exists yet.
    final healthEntry = HealthEngine.todayEntry();
    final sleepHours = healthEntry?.sleepHours ??
        (prefs.getInt('wellness_sleep') ?? 7).toDouble();

    // ── 2. Task signals (LocalStorage) ────────────────────────────────────
    final tasks = LocalStorage.getTodayTasks()
        .whereType<Map<String, dynamic>>()
        .toList();

    final totalTasks = tasks.length;

    final missedTasks = tasks.where((t) {
      if (t['isCompleted'] == true) return false;
      final raw = (t['dueDate'] ?? t['startTime']) as String?;
      if (raw == null) return false;
      try {
        return DateTime.parse(raw).isBefore(now);
      } catch (_) {
        return false;
      }
    }).length;

    // Tasks due within the next 2 hours (urgent deadlines)
    final urgentTasks = tasks.where((t) {
      if (t['isCompleted'] == true) return false;
      final raw = (t['dueDate'] ?? t['startTime']) as String?;
      if (raw == null) return false;
      try {
        final due = DateTime.parse(raw);
        return due.isAfter(now) &&
            due.isBefore(now.add(const Duration(hours: 2)));
      } catch (_) {
        return false;
      }
    }).length;

    // ── 3. Working hours signal (focus sessions today) ─────────────────────
    final allSessions = LocalStorage.getFocusHistory()
        .whereType<Map<String, dynamic>>()
        .toList();
    final todayMins = allSessions.where((s) {
      try {
        return DateTime.parse(s['startedAt'] as String).isAfter(todayStart);
      } catch (_) {
        return false;
      }
    }).fold<int>(
        0, (sum, s) => sum + ((s['actualMins'] as num?)?.toInt() ?? 0));
    final workingHours = todayMins / 60.0;

    // ── 4. Score each signal (0–100) ───────────────────────────────────────
    final taskScore = _scoreTaskLoad(totalTasks);
    final deadlineScore = _scoreDeadlines(urgentTasks);
    final missedScore = _scoreMissed(missedTasks);
    final moodScore = _scoreMood(mood);
    final sleepScore = _scoreSleep(sleepHours);
    final workScore = _scoreWorkHours(workingHours);
    final strengthScore = _scoreStrength(strength);

    // ── 5. Weighted risk total ─────────────────────────────────────────────
    final risk = (_wTasks * taskScore +
            _wDeadlines * deadlineScore +
            _wMissed * missedScore +
            _wMood * moodScore +
            _wSleep * sleepScore +
            _wWorkHours * workScore +
            _wStrength * strengthScore)
        .round()
        .clamp(0, 100);

    final level = risk >= 75
        ? BurnoutLevel.critical
        : risk >= 55
            ? BurnoutLevel.high
            : risk >= 30
                ? BurnoutLevel.moderate
                : BurnoutLevel.low;

    // ── 6. Specific warning messages ───────────────────────────────────────
    final warnings = <String>[];

    if (mood == MoodType.stressed) {
      warnings.add(
          'You\'re feeling stressed — high cognitive load degrades decision quality. Protect your mental space.');
    } else if (mood == MoodType.tired) {
      warnings.add(
          'You\'re feeling tired — rest is a performance strategy, not a weakness.');
    }
    if (sleepHours < 6) {
      warnings.add(
          'Only ${sleepHours.toStringAsFixed(1)}h of sleep last night. Poor sleep increases error rates by up to 40%.');
    } else if (sleepHours < 7) {
      warnings.add(
          '${sleepHours.toStringAsFixed(1)}h of sleep is below the recommended 7–9h for sustained focus.');
    }
    if (missedTasks > 1) {
      warnings.add(
          '$missedTasks missed deadlines detected — your task load may be exceeding capacity.');
    } else if (missedTasks == 1) {
      warnings.add('A missed deadline was detected. Review your schedule.');
    }
    if (totalTasks > 9) {
      warnings.add(
          '$totalTasks tasks scheduled today. Research shows performance drops beyond 7 concurrent tasks.');
    } else if (totalTasks > 6) {
      warnings.add(
          '$totalTasks tasks today is a heavy load. Consider what can wait.');
    }
    if (urgentTasks > 0) {
      warnings.add(
          '$urgentTasks task${urgentTasks > 1 ? "s" : ""} due in the next 2 hours — protect your focus window.');
    }
    if (workingHours >= 7) {
      warnings.add(
          '${workingHours.toStringAsFixed(1)}h focused work today. Cognitive fatigue sets in after 6h.');
    } else if (workingHours >= 5) {
      warnings.add(
          '${workingHours.toStringAsFixed(1)}h of focus work today — schedule a proper break soon.');
    }

    // ── 7. Rescheduling suggestions ────────────────────────────────────────
    final suggestions = _buildSuggestions(tasks, level, now);

    return BurnoutResult(
      level: level,
      score: risk,
      warnings: warnings,
      rescheduleSuggestions: suggestions,
      headline: _headline(level),
      advice: _advice(level, mood, sleepHours, workingHours),
    );
  }

  // ── Signal scorers ─────────────────────────────────────────────────────────

  static int _scoreTaskLoad(int count) {
    if (count >= 12) return 100;
    if (count >= 9) return 80;
    if (count >= 6) return 55;
    if (count >= 4) return 30;
    return 0;
  }

  static int _scoreDeadlines(int urgent) {
    if (urgent >= 4) return 100;
    if (urgent >= 3) return 80;
    if (urgent >= 2) return 60;
    if (urgent >= 1) return 35;
    return 0;
  }

  static int _scoreMissed(int missed) {
    if (missed >= 4) return 100;
    if (missed >= 3) return 80;
    if (missed >= 2) return 60;
    if (missed >= 1) return 35;
    return 0;
  }

  static int _scoreMood(MoodType mood) => mood.burnoutScore;

  static int _scoreSleep(double hours) {
    if (hours <= 4) return 100;
    if (hours <= 5) return 80;
    if (hours <= 6) return 55;
    if (hours <= 7) return 25;
    return 0;
  }

  static int _scoreWorkHours(double hours) {
    if (hours >= 9) return 100;
    if (hours >= 7) return 75;
    if (hours >= 5) return 45;
    if (hours >= 3) return 20;
    return 0;
  }

  // Beginner = more susceptible to burnout; Elite = more resilient
  static int _scoreStrength(String strength) => switch (strength) {
        'Beginner' => 55,
        'Intermediate' => 35,
        'Advanced' => 15,
        _ => 0, // Elite
      };

  // ── Rescheduling suggestions ───────────────────────────────────────────────

  static List<RescheduleSuggestion> _buildSuggestions(
    List<Map<String, dynamic>> tasks,
    BurnoutLevel level,
    DateTime now,
  ) {
    if (level == BurnoutLevel.low) return [];

    final suggestions = <RescheduleSuggestion>[];
    final urgentThreshold = now.add(const Duration(hours: 4));

    for (final t in tasks) {
      if (t['isCompleted'] == true) continue;
      final priority = (t['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
      final id = t['id'] as String?;
      final title = t['title'] as String? ?? 'Untitled';
      final rawDue = (t['dueDate'] ?? t['startTime']) as String?;
      if (id == null) continue;

      // Check if due within urgent threshold
      bool isImminent = false;
      if (rawDue != null) {
        try {
          isImminent = DateTime.parse(rawDue).isBefore(urgentThreshold);
        } catch (_) {}
      }
      if (isImminent) continue; // Never suggest deferring imminent tasks

      if (priority == 'LOW') {
        suggestions.add(RescheduleSuggestion(
          taskId: id,
          taskTitle: title,
          priority: priority,
          dueDate: rawDue,
          reason: 'Low priority — safely deferred to tomorrow',
        ));
      } else if (priority == 'MEDIUM' &&
          level.index >= BurnoutLevel.high.index) {
        suggestions.add(RescheduleSuggestion(
          taskId: id,
          taskTitle: title,
          priority: priority,
          dueDate: rawDue,
          reason: 'Not urgent — defer to protect your energy today',
        ));
      }
    }

    return suggestions.take(5).toList(); // cap at 5 suggestions
  }

  // ── Headline and advice copy ───────────────────────────────────────────────

  static String _headline(BurnoutLevel level) => switch (level) {
        BurnoutLevel.critical =>
          'Please take a break — your mental health is at stake.',
        BurnoutLevel.high =>
          'You\'re showing signs of burnout. Ease the pressure now.',
        BurnoutLevel.moderate =>
          'Your load is building up. A few adjustments can help.',
        BurnoutLevel.low => 'You\'re in a healthy balance. Keep it up.',
      };

  static String _advice(
    BurnoutLevel level,
    MoodType mood,
    double sleepHours,
    double workingHours,
  ) {
    if (level == BurnoutLevel.critical) {
      return 'Step away from your screen for at least 20 minutes right now. Hydrate, breathe, and return with a clearer mind. Your tasks will still be there.';
    }
    if (mood == MoodType.stressed) {
      return 'When stressed, break work into small 15-minute blocks. Each completion builds momentum and reduces the sense of overwhelm.';
    }
    if (mood == MoodType.tired) {
      return 'A 20-minute rest or a short walk outside can restore focus more effectively than pushing through fatigue.';
    }
    if (sleepHours < 6) {
      return 'Prioritise sleep tonight — even one good night dramatically improves decision-making, mood, and focus quality.';
    }
    if (workingHours >= 5) {
      return 'You\'ve been in deep work for a long stretch. Schedule a real 15-minute break before your next session.';
    }
    return 'Schedule short breaks every 90 minutes. Your brain needs recovery time to sustain high performance throughout the day.';
  }
}
