import 'local_storage.dart';
import '../features/insights/models/insights_data.dart';

/// Aggregates data already stored locally (tasks + focus sessions) into
/// InsightsData. Never makes a network call — fully offline.
class LocalInsightsEngine {
  LocalInsightsEngine._();

  static InsightsData compute() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // ── Today's tasks ───────────────────────────────────────────────────────
    final tasks = LocalStorage.getTodayTasks()
        .whereType<Map<String, dynamic>>()
        .toList();

    final completedTasks =
        tasks.where((t) => t['isCompleted'] == true).length;

    final missedTasks = tasks.where((t) {
      if (t['isCompleted'] == true) return false;
      final raw = t['dueDate'] ?? t['startTime'];
      if (raw == null) return false;
      try {
        return DateTime.parse(raw as String).isBefore(now);
      } catch (_) {
        return false;
      }
    }).length;

    final totalTasks = tasks.length;
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

    // ── Focus sessions ───────────────────────────────────────────────────────
    final allSessions = LocalStorage.getFocusHistory()
        .whereType<Map<String, dynamic>>()
        .toList();

    // All-time average focus score (shown in Focus Score section)
    final avgFocusScore = allSessions.isEmpty
        ? 0.0
        : allSessions.fold<double>(
                0,
                (sum, s) =>
                    sum + ((s['focusScore'] as num?)?.toDouble() ?? 0)) /
            allSessions.length;

    // Today's sessions
    final todaySessions = allSessions.where((s) {
      try {
        return DateTime.parse(s['startedAt'] as String).isAfter(todayStart);
      } catch (_) {
        return false;
      }
    }).toList();

    final focusSessions = todaySessions.length;
    final totalFocusMinutes = todaySessions.fold<int>(
        0, (sum, s) => sum + ((s['actualMins'] as num?)?.toInt() ?? 0));

    final todayAvgFocus = todaySessions.isEmpty
        ? 0.0
        : todaySessions.fold<double>(
                0,
                (sum, s) =>
                    sum + ((s['focusScore'] as num?)?.toDouble() ?? 0)) /
            todaySessions.length;

    // ── Daily score ──────────────────────────────────────────────────────────
    // 50% task completion + 30% focus quality + 20% focus volume bonus
    final focusBonus = (focusSessions * 25.0).clamp(0.0, 100.0);
    final dailyScore =
        (0.5 * completionRate + 0.3 * todayAvgFocus + 0.2 * focusBonus)
            .clamp(0.0, 100.0);

    // ── Weekly breakdown (last 7 days) ───────────────────────────────────────
    final breakdown = _weeklyBreakdown(
      allSessions: allSessions,
      todayTasks: tasks,
      now: now,
      todayStart: todayStart,
      todayScore: dailyScore,
      todayCompleted: completedTasks,
    );

    final weeklyScore = breakdown.isEmpty
        ? dailyScore
        : breakdown.fold<double>(0, (s, d) => s + d.score) / breakdown.length;

    return InsightsData(
      completedTasks: completedTasks,
      missedTasks: missedTasks,
      focusSessions: focusSessions,
      completionRate: completionRate,
      dailyScore: dailyScore,
      weeklyScore: weeklyScore,
      weeklyBreakdown: breakdown,
      totalFocusMinutes: totalFocusMinutes,
      avgFocusScore: avgFocusScore,
    );
  }

  static List<DailyScore> _weeklyBreakdown({
    required List<Map<String, dynamic>> allSessions,
    required List<Map<String, dynamic>> todayTasks,
    required DateTime now,
    required DateTime todayStart,
    required double todayScore,
    required int todayCompleted,
  }) {
    return List.generate(7, (i) {
      final dayStart =
          todayStart.subtract(Duration(days: 6 - i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final isToday = i == 6;

      final daySessions = allSessions.where((s) {
        try {
          final dt = DateTime.parse(s['startedAt'] as String);
          return dt.isAfter(dayStart) && dt.isBefore(dayEnd);
        } catch (_) {
          return false;
        }
      }).toList();

      final dayFocusCount = daySessions.length;
      final dayAvgFocus = daySessions.isEmpty
          ? 0.0
          : daySessions.fold<double>(
                  0,
                  (sum, s) =>
                      sum + ((s['focusScore'] as num?)?.toDouble() ?? 0)) /
              daySessions.length;
      final dayFocusBonus = (dayFocusCount * 25.0).clamp(0.0, 100.0);

      final double score;
      final int completed;

      if (isToday) {
        score = todayScore;
        completed = todayCompleted;
      } else {
        // Past days: score from focus data only (no historical task cache)
        score = daySessions.isEmpty
            ? 0.0
            : (0.6 * dayAvgFocus + 0.4 * dayFocusBonus).clamp(0.0, 100.0);
        completed = 0;
      }

      return DailyScore(
        date: dayStart,
        score: score,
        focusSessions: dayFocusCount,
        completedTasks: completed,
      );
    });
  }

  /// Merges a server weekly response into an InsightsData computed locally.
  /// Falls back gracefully if the server payload shape differs.
  static InsightsData mergeServerWeekly(
    InsightsData local,
    Map<String, dynamic> weekly,
  ) {
    try {
      final rawDays = weekly['weekly'] as List?;
      final serverWeeklyScore =
          (weekly['weeklyScore'] as num?)?.toDouble();

      if (rawDays == null || rawDays.length < 7) {
        return serverWeeklyScore != null
            ? local.copyWith(weeklyScore: serverWeeklyScore)
            : local;
      }

      final breakdown = rawDays.map((d) {
        final map = d as Map<String, dynamic>;
        final date = DateTime.tryParse(map['date'] as String? ?? '') ??
            DateTime.now();
        return DailyScore(
          date: date,
          score: (map['score'] as num?)?.toDouble() ?? 0,
          focusSessions: (map['focusSessions'] as num?)?.toInt() ?? 0,
          completedTasks: (map['completedTasks'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      return local.copyWith(
        weeklyBreakdown: breakdown,
        weeklyScore:
            serverWeeklyScore ?? local.weeklyScore,
      );
    } catch (_) {
      return local;
    }
  }
}
