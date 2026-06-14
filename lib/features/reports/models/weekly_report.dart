import 'daily_report.dart';

class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalCompleted;
  final int totalMissed;
  final int totalTasks;
  final double totalFocusHours;
  final double avgProductivityScore;
  final double completionRate;
  final List<DailyReport> dailyBreakdown;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalCompleted,
    required this.totalMissed,
    required this.totalTasks,
    required this.totalFocusHours,
    required this.avgProductivityScore,
    required this.completionRate,
    required this.dailyBreakdown,
  });

  factory WeeklyReport.empty(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalCompleted: 0,
      totalMissed: 0,
      totalTasks: 0,
      totalFocusHours: 0,
      avgProductivityScore: 0,
      completionRate: 0,
      dailyBreakdown: List.generate(
        7,
        (i) => DailyReport.empty(weekStart.add(Duration(days: i))),
      ),
    );
  }

  bool get hasData => dailyBreakdown.any((d) => d.hasData);

  int get bestDayIndex {
    if (dailyBreakdown.isEmpty) return 0;
    int best = 0;
    for (int i = 1; i < dailyBreakdown.length; i++) {
      if (dailyBreakdown[i].productivityScore >
          dailyBreakdown[best].productivityScore) {
        best = i;
      }
    }
    return best;
  }

  DailyReport? get bestDay {
    if (!hasData) return null;
    return dailyBreakdown[bestDayIndex];
  }

  String get focusTimeLabel {
    final totalMins = (totalFocusHours * 60).round();
    if (totalMins < 60) return '${totalMins}m';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
