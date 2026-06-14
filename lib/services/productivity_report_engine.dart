import 'local_storage.dart';
import '../features/reports/models/daily_report.dart';
import '../features/reports/models/weekly_report.dart';

class ProductivityReportEngine {
  ProductivityReportEngine._();

  // ── Public API ──────────────────────────────────────────────────────────────

  static Future<DailyReport> generateDaily(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final now = DateTime.now();
    final isToday = dayStart.year == now.year &&
        dayStart.month == now.month &&
        dayStart.day == now.day;

    // ── Tasks ────────────────────────────────────────────────────────────────
    final allTasks = isToday
        ? LocalStorage.getTodayTasks().whereType<Map<String, dynamic>>().toList()
        : LocalStorage.getAllTasks()
            .whereType<Map<String, dynamic>>()
            .where((t) => _taskBelongsToDay(t, dayStart, dayEnd))
            .toList();

    final completedTasks =
        allTasks.where((t) => t['isCompleted'] == true).length;
    final missedTasks = allTasks.where((t) {
      if (t['isCompleted'] == true) return false;
      final raw = (t['dueDate'] ?? t['startTime']) as String?;
      if (raw == null) return false;
      try {
        final due = DateTime.parse(raw);
        return due.isBefore(isToday ? now : dayEnd);
      } catch (_) {
        return false;
      }
    }).length;
    final totalTasks = allTasks.length;
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

    // ── Focus sessions ───────────────────────────────────────────────────────
    final allSessions = LocalStorage.getFocusHistory()
        .whereType<Map<String, dynamic>>()
        .toList();
    final daySessions = allSessions.where((s) {
      try {
        final dt = DateTime.parse(s['startedAt'] as String);
        return dt.isAfter(dayStart) && dt.isBefore(dayEnd);
      } catch (_) {
        return false;
      }
    }).toList();

    final focusSessions = daySessions.length;
    final totalFocusMinutes = daySessions.fold<double>(
        0, (sum, s) => sum + ((s['actualMins'] as num?)?.toDouble() ?? 0));
    final avgFocusScore = daySessions.isEmpty
        ? 0.0
        : daySessions.fold<double>(
                0,
                (sum, s) =>
                    sum + ((s['focusScore'] as num?)?.toDouble() ?? 0)) /
            daySessions.length;

    // ── Score ────────────────────────────────────────────────────────────────
    final focusBonus = (focusSessions * 25.0).clamp(0.0, 100.0);
    final double score;
    if (isToday) {
      score = (0.5 * completionRate + 0.3 * avgFocusScore + 0.2 * focusBonus)
          .clamp(0.0, 100.0);
    } else if (totalTasks > 0) {
      score = (0.5 * completionRate + 0.3 * avgFocusScore + 0.2 * focusBonus)
          .clamp(0.0, 100.0);
    } else {
      // Past day with no cached task data — focus only
      score = daySessions.isEmpty
          ? 0.0
          : (0.6 * avgFocusScore + 0.4 * focusBonus).clamp(0.0, 100.0);
    }

    return DailyReport(
      date: dayStart,
      completedTasks: completedTasks,
      missedTasks: missedTasks,
      totalTasks: totalTasks,
      focusHours: totalFocusMinutes / 60,
      productivityScore: score,
      completionRate: completionRate,
      avgFocusScore: avgFocusScore,
      focusSessions: focusSessions,
    );
  }

  static Future<WeeklyReport> generateWeekly(DateTime weekStart) async {
    final normalised =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = normalised.add(const Duration(days: 7));

    final days = await Future.wait(
      List.generate(
          7, (i) => generateDaily(normalised.add(Duration(days: i)))),
    );

    final totalCompleted = days.fold(0, (s, d) => s + d.completedTasks);
    final totalMissed = days.fold(0, (s, d) => s + d.missedTasks);
    final totalTasks = days.fold(0, (s, d) => s + d.totalTasks);
    final totalFocusHours = days.fold(0.0, (s, d) => s + d.focusHours);
    final completionRate =
        totalTasks > 0 ? (totalCompleted / totalTasks * 100) : 0.0;

    final activeDays = days.where((d) => d.hasData).toList();
    final avgScore = activeDays.isEmpty
        ? 0.0
        : activeDays.fold(0.0, (s, d) => s + d.productivityScore) /
            activeDays.length;

    return WeeklyReport(
      weekStart: normalised,
      weekEnd: weekEnd.subtract(const Duration(days: 1)),
      totalCompleted: totalCompleted,
      totalMissed: totalMissed,
      totalTasks: totalTasks,
      totalFocusHours: totalFocusHours,
      avgProductivityScore: avgScore,
      completionRate: completionRate,
      dailyBreakdown: days,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static bool _taskBelongsToDay(
      Map<String, dynamic> task, DateTime dayStart, DateTime dayEnd) {
    for (final key in ['startTime', 'dueDate', 'createdAt']) {
      final raw = task[key] as String?;
      if (raw == null) continue;
      try {
        final dt = DateTime.parse(raw);
        if (dt.isAfter(dayStart) && dt.isBefore(dayEnd)) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Returns the Monday of the week containing [date].
  static DateTime weekStartFor(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}
