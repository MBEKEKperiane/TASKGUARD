class DailyScore {
  final DateTime date;
  final double score; // 0–100
  final int focusSessions;
  final int completedTasks;

  const DailyScore({
    required this.date,
    required this.score,
    required this.focusSessions,
    required this.completedTasks,
  });
}

class InsightsData {
  final int completedTasks;
  final int missedTasks;
  final int focusSessions;
  final double completionRate; // 0–100
  final double dailyScore;     // 0–100
  final double weeklyScore;    // 0–100
  final List<DailyScore> weeklyBreakdown; // 7 entries, index 0 = 6 days ago
  final int totalFocusMinutes;
  final double avgFocusScore; // 0–100, across all stored sessions
  final bool isLoading;

  const InsightsData({
    required this.completedTasks,
    required this.missedTasks,
    required this.focusSessions,
    required this.completionRate,
    required this.dailyScore,
    required this.weeklyScore,
    required this.weeklyBreakdown,
    required this.totalFocusMinutes,
    required this.avgFocusScore,
    this.isLoading = false,
  });

  static const loading = InsightsData(
    completedTasks: 0,
    missedTasks: 0,
    focusSessions: 0,
    completionRate: 0,
    dailyScore: 0,
    weeklyScore: 0,
    weeklyBreakdown: [],
    totalFocusMinutes: 0,
    avgFocusScore: 0,
    isLoading: true,
  );

  static const empty = InsightsData(
    completedTasks: 0,
    missedTasks: 0,
    focusSessions: 0,
    completionRate: 0,
    dailyScore: 0,
    weeklyScore: 0,
    weeklyBreakdown: [],
    totalFocusMinutes: 0,
    avgFocusScore: 0,
  );

  InsightsData copyWith({
    int? completedTasks,
    int? missedTasks,
    int? focusSessions,
    double? completionRate,
    double? dailyScore,
    double? weeklyScore,
    List<DailyScore>? weeklyBreakdown,
    int? totalFocusMinutes,
    double? avgFocusScore,
    bool? isLoading,
  }) {
    return InsightsData(
      completedTasks: completedTasks ?? this.completedTasks,
      missedTasks: missedTasks ?? this.missedTasks,
      focusSessions: focusSessions ?? this.focusSessions,
      completionRate: completionRate ?? this.completionRate,
      dailyScore: dailyScore ?? this.dailyScore,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      weeklyBreakdown: weeklyBreakdown ?? this.weeklyBreakdown,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      avgFocusScore: avgFocusScore ?? this.avgFocusScore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
