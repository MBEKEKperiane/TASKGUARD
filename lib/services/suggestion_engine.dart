import 'package:flutter/material.dart';
import '../features/mood/models/mood_entry.dart';

/// A context-aware AI focus suggestion derived from task data, time of day,
/// productivity score, and overload level — no network call required.
class FocusSuggestion {
  final String cardTitle;
  final String description;

  /// Recommended focus block length in minutes (always a multiple of 5, 15–90).
  final int durationMins;

  /// The title of the selected task, forwarded to [FocusTimerScreen].
  final String? taskTitle;
  final IconData icon;

  const FocusSuggestion({
    required this.cardTitle,
    required this.description,
    required this.durationMins,
    required this.icon,
    this.taskTitle,
  });
}

/// Pure, synchronous engine — safe to call in a build getter.
class SuggestionEngine {
  // Lower rank = higher priority.
  static const _rank = {'URGENT': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};

  // Base focus duration per priority when no estimated duration is available.
  static const _baseMins = {'URGENT': 50, 'HIGH': 45, 'MEDIUM': 25, 'LOW': 20};

  // Peak productivity windows (hour-of-day, 24-h).
  static bool _isPeak(int hour) =>
      (hour >= 8 && hour < 11) || (hour >= 13 && hour < 16);

  /// Generates a [FocusSuggestion] from the current app state.
  ///
  /// [pendingTasks]  – tasks where isCompleted != true, straight from the cache.
  /// [hour]          – current hour (0–23), e.g. DateTime.now().hour.
  /// [scoreData]     – productivity score map, e.g. {'score': 72}.
  /// [overloadData]  – overload map, e.g. {'level': 'HIGH', 'message': '...'}.
  static FocusSuggestion generate({
    required List<Map<String, dynamic>> pendingTasks,
    required int hour,
    Map<String, dynamic>? scoreData,
    Map<String, dynamic>? overloadData,
    MoodType? mood,
  }) {
    final top = _pickTop(pendingTasks);
    final duration = _duration(top, hour, scoreData, overloadData, mood);

    return FocusSuggestion(
      cardTitle: _title(top, mood),
      description: _description(top, duration, hour, overloadData, mood),
      durationMins: duration,
      taskTitle: top?['title'] as String?,
      icon: _icon(top, overloadData, mood),
    );
  }

  // ── Task selection ────────────────────────────────────────────────────────

  static Map<String, dynamic>? _pickTop(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return null;

    final now = DateTime.now();
    final sorted = List<Map<String, dynamic>>.from(tasks)
      ..sort((a, b) {
        final ra = _rank[a['priority'] ?? 'MEDIUM'] ?? 2;
        final rb = _rank[b['priority'] ?? 'MEDIUM'] ?? 2;
        if (ra != rb) return ra.compareTo(rb);

        // Break priority ties by deadline proximity.
        final da = _due(a['dueDate']);
        final db = _due(b['dueDate']);
        if (da != null && db != null) return da.compareTo(db);
        if (da != null) return -1; // task with deadline wins
        if (db != null) return 1;
        return 0;
      });

    // If the top task is due in > 24 h and there's an overdue one, prefer it.
    final overdue = sorted.where((t) {
      final d = _due(t['dueDate']);
      return d != null && d.isBefore(now);
    }).toList();
    if (overdue.isNotEmpty) return overdue.first;

    return sorted.first;
  }

  // ── Duration computation ─────────────────────────────────────────────────

  static int _duration(
    Map<String, dynamic>? task,
    int hour,
    Map<String, dynamic>? scoreData,
    Map<String, dynamic>? overloadData,
    MoodType? mood,
  ) {
    // 1. Seed from task's estimatedDuration (minutes) or priority default.
    double mins;
    final estimated = task?['estimatedDuration'];
    if (estimated is int && estimated > 0) {
      mins = estimated.toDouble();
    } else if (estimated is num && estimated > 0) {
      mins = estimated.toDouble();
    } else {
      final priority = task?['priority'] as String? ?? 'MEDIUM';
      mins = (_baseMins[priority] ?? 25).toDouble();
    }

    // 2. Time-of-day modifier: off-peak hours reduce session length by 20 %.
    if (!_isPeak(hour)) mins *= 0.8;

    // 3. Mood multiplier — Motivated extends, Tired/Stressed shorten.
    if (mood != null) mins *= mood.durationMultiplier;

    // 4. Low productivity score (<40) signals fatigue — trim another 20 %.
    final score = (scoreData?['score'] as num?)?.toDouble() ?? 100;
    if (score < 40) mins *= 0.8;

    // 5. High overload caps the session at 25 min to prevent burnout.
    final level = overloadData?['level'] as String? ?? 'LOW';
    if (level == 'HIGH') mins = mins.clamp(0, 25);

    // 6. Mood hard cap overrides overload cap when more restrictive.
    final cap = mood?.sessionCap;
    if (cap != null) mins = mins.clamp(0, cap.toDouble());

    // 7. Round to the nearest 5, clamp to [15, 90].
    return (((mins / 5).round() * 5).clamp(15, 90)).toInt();
  }

  // ── Card text ─────────────────────────────────────────────────────────────

  static String _title(Map<String, dynamic>? task, MoodType? mood) {
    if (mood == MoodType.tired) return 'Light Focus Block';
    if (mood == MoodType.stressed) return 'Calm Progress Block';
    if (task == null) return 'Free Focus Session';
    switch (task['priority'] as String? ?? 'MEDIUM') {
      case 'URGENT':
        return 'Urgent: Act Now';
      case 'HIGH':
        return mood == MoodType.motivated
            ? 'You\'re in the zone — go'
            : 'Priority Focus Block';
      default:
        return mood == MoodType.motivated ? 'Deep Work — Full Send' : 'Deep Work Block';
    }
  }

  static String _description(
    Map<String, dynamic>? task,
    int durationMins,
    int hour,
    Map<String, dynamic>? overloadData,
    MoodType? mood,
  ) {
    if (task == null) {
      return 'No pending tasks — use this block to get ahead or plan tomorrow.';
    }

    final title = task['title'] as String? ?? 'your task';
    final priority = task['priority'] as String? ?? 'MEDIUM';
    final dueDate = _due(task['dueDate']);
    final now = DateTime.now();

    // ── Mood-first copy (overrides time/overload copy) ────────────────────
    if (mood == MoodType.tired) {
      return 'Energy is low — a short $durationMins-minute block on "$title" is enough. Rest after.';
    }
    if (mood == MoodType.stressed) {
      return 'Feeling overwhelmed? Break it down: just $durationMins minutes on "$title". One step at a time.';
    }
    if (mood == MoodType.motivated) {
      return 'You\'re fired up — use this $durationMins-minute block to make serious progress on "$title".';
    }

    // ── Deadline urgency ──────────────────────────────────────────────────
    if (dueDate != null) {
      final hoursLeft = dueDate.difference(now).inHours;
      if (dueDate.isAfter(now) && hoursLeft < 3) {
        return '"$title" is due in under ${hoursLeft == 0 ? 'an hour' : '$hoursLeft h'}.'
            ' Start your $durationMins-minute sprint now to finish on time.';
      }
      final isDueToday = dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
      if (isDueToday && (priority == 'URGENT' || priority == 'HIGH')) {
        return '"$title" must be completed today.'
            ' Lock in $durationMins focused minutes.';
      }
      if (dueDate.isBefore(now)) {
        return '"$title" is overdue. A $durationMins-minute block will help you catch up.';
      }
    }

    // ── Overload guard ────────────────────────────────────────────────────
    final level = overloadData?['level'] as String? ?? 'LOW';
    if (level == 'HIGH') {
      return 'You\'ve been working hard. A $durationMins-minute sprint on'
          ' "$title" keeps momentum without burning out.';
    }

    // ── Time-of-day patterns ──────────────────────────────────────────────
    if (hour >= 8 && hour < 11) {
      return 'Morning focus peak — ideal for "$title".'
          ' Block $durationMins minutes for deep work.';
    }
    if (hour >= 13 && hour < 16) {
      return 'Post-lunch productivity window. Tackle "$title"'
          ' in $durationMins focused minutes.';
    }
    if (hour >= 17) {
      return 'A $durationMins-minute session on "$title" to finish the day strong.';
    }

    return 'TaskGuard recommends $durationMins focused minutes on "$title".';
  }

  static IconData _icon(
    Map<String, dynamic>? task,
    Map<String, dynamic>? overloadData,
    MoodType? mood,
  ) {
    if (mood == MoodType.tired) return Icons.bedtime_outlined;
    if (mood == MoodType.stressed) return Icons.self_improvement_rounded;
    if (mood == MoodType.motivated) return Icons.local_fire_department_rounded;
    final level = overloadData?['level'] as String? ?? 'LOW';
    if (level == 'HIGH') return Icons.favorite_outline_rounded;
    switch (task?['priority'] as String? ?? '') {
      case 'URGENT':
        return Icons.priority_high_rounded;
      case 'HIGH':
        return Icons.bolt_rounded;
      default:
        return Icons.auto_awesome;
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static DateTime? _due(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw as String).toLocal();
    } catch (_) {
      return null;
    }
  }
}
