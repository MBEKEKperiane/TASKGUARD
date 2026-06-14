import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';
import '../features/mood/models/mood_entry.dart';
import '../features/prioritization/models/prioritized_task.dart';

/// Offline-first task prioritization engine.
///
/// Scores each pending task across four dimensions and returns a ranked list
/// with human-readable recommendations. All signals are derived from local
/// storage — no network required.
class TaskPrioritizationEngine {
  TaskPrioritizationEngine._();

  // ── Dimension weights (must sum to 1.0) ────────────────────────────────────
  static const _wUrgency = 0.30;
  static const _wDeadline = 0.30;
  static const _wImportance = 0.25;
  static const _wPattern = 0.15;

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<List<PrioritizedTask>> rank(
      List<Map<String, dynamic>> tasks) async {
    final pending = tasks
        .where((t) => t['isCompleted'] != true)
        .toList();

    if (pending.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final moodRaw = prefs.getString('wellness_mood');
    final mood = moodRaw != null ? MoodTypeX.fromStorage(moodRaw) : null;

    final patterns = _buildUserPatterns(mood);
    final now = DateTime.now();

    final scored = pending.map((t) => _scoreTask(t, patterns, now)).toList();
    scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return scored
        .asMap()
        .entries
        .map((e) => e.value.copyWith(rank: e.key + 1))
        .toList();
  }

  // ── User pattern extraction ────────────────────────────────────────────────

  static _UserPatterns _buildUserPatterns(MoodType? mood) {
    final history = LocalStorage.getFocusHistory()
        .whereType<Map<String, dynamic>>()
        .toList();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Hour → session count (all time, capped at last 30 sessions for recency)
    final recent = history.take(30).toList();
    final hourCounts = <int, int>{};
    double totalFocusScore = 0;
    int todaySessions = 0;

    for (final s in recent) {
      try {
        final dt = DateTime.parse(s['startedAt'] as String);
        hourCounts[dt.hour] = (hourCounts[dt.hour] ?? 0) + 1;
        totalFocusScore += (s['focusScore'] as num?)?.toDouble() ?? 60;
        if (dt.isAfter(todayStart)) todaySessions++;
      } catch (_) {}
    }

    // Peak hours: any hour with above-average session count
    final avgCount = hourCounts.isEmpty
        ? 0.0
        : hourCounts.values.reduce((a, b) => a + b) / hourCounts.length;
    final peakHours = hourCounts.entries
        .where((e) => e.value >= avgCount)
        .map((e) => e.key)
        .toSet();

    final avgFocusQuality =
        recent.isEmpty ? 60.0 : totalFocusScore / recent.length;

    return _UserPatterns(
      peakHours: peakHours,
      avgFocusQuality: avgFocusQuality,
      todaySessionCount: todaySessions,
      currentHour: now.hour,
      mood: mood,
    );
  }

  // ── Single task scorer ─────────────────────────────────────────────────────

  static PrioritizedTask _scoreTask(
    Map<String, dynamic> task,
    _UserPatterns patterns,
    DateTime now,
  ) {
    final urgency = _scoreUrgency(task, now);
    final deadline = _scoreDeadline(task, now);
    final importance = _scoreImportance(task);
    final pattern = _scorePattern(task, patterns, now);

    final total = (_wUrgency * urgency +
            _wDeadline * deadline +
            _wImportance * importance +
            _wPattern * pattern)
        .clamp(0.0, 100.0);

    final reasons = _buildReasons(task, urgency, deadline, importance, pattern, now, patterns.mood);
    final recommendation = _buildRecommendation(task, reasons, total, now, patterns);

    return PrioritizedTask(
      task: task,
      rank: 0, // assigned after sort
      totalScore: double.parse(total.toStringAsFixed(1)),
      urgencyScore: double.parse(urgency.toStringAsFixed(1)),
      importanceScore: double.parse(importance.toStringAsFixed(1)),
      deadlineScore: double.parse(deadline.toStringAsFixed(1)),
      patternScore: double.parse(pattern.toStringAsFixed(1)),
      recommendation: recommendation,
      reasons: reasons,
    );
  }

  // ── Urgency scorer (0–100) ─────────────────────────────────────────────────
  // Based on explicit priority field + overdue penalty.

  static double _scoreUrgency(Map<String, dynamic> task, DateTime now) {
    final priority =
        (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
    double base = switch (priority) {
      'URGENT' => 100,
      'HIGH' => 75,
      'MEDIUM' => 45,
      _ => 20, // LOW
    };

    // Boost if overdue
    final raw = (task['dueDate'] ?? task['startTime']) as String?;
    if (raw != null) {
      try {
        if (DateTime.parse(raw).isBefore(now)) base = (base + 20).clamp(0, 100);
      } catch (_) {}
    }

    return base.toDouble();
  }

  // ── Deadline scorer (0–100) ────────────────────────────────────────────────
  // Exponentially favours tasks due sooner.

  static double _scoreDeadline(Map<String, dynamic> task, DateTime now) {
    final raw = (task['dueDate'] ?? task['startTime']) as String?;
    if (raw == null) return 10; // no deadline = low pressure

    try {
      final due = DateTime.parse(raw);
      if (due.isBefore(now)) return 100; // overdue

      final hours = due.difference(now).inMinutes / 60.0;
      if (hours < 1) return 95;
      if (hours < 3) return 85;
      if (hours < 6) return 70;
      if (hours < 12) return 55;
      if (hours < 24) return 40;
      if (hours < 48) return 25;
      if (hours < 168) return 15; // within 7 days
      return 8;
    } catch (_) {
      return 10;
    }
  }

  // ── Importance scorer (0–100) ──────────────────────────────────────────────
  // Combines complexity signals: subtasks, estimated duration, category.

  static double _scoreImportance(Map<String, dynamic> task) {
    final priority =
        (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
    double score = switch (priority) {
      'URGENT' => 55,
      'HIGH' => 44,
      'MEDIUM' => 28,
      _ => 14, // LOW
    };

    // Subtasks signal complexity
    final subtasks = task['subtasks'];
    if (subtasks is List) {
      score = (score + (subtasks.length * 8).clamp(0, 32)).clamp(0, 100);
    }

    // Long estimated duration = higher stakes
    final mins = (task['estimatedDuration'] as num?)?.toInt() ?? 0;
    if (mins >= 90) score = (score + 18).clamp(0, 100);
    else if (mins >= 45) score = (score + 10).clamp(0, 100);

    // Category boost for high-value domains
    final category = (task['category'] as String?)?.toLowerCase() ?? '';
    if (_isHighValueCategory(category)) {
      score = (score + 14).clamp(0, 100);
    }

    return score.toDouble();
  }

  static bool _isHighValueCategory(String c) =>
      c.contains('work') ||
      c.contains('study') ||
      c.contains('health') ||
      c.contains('career') ||
      c.contains('finance') ||
      c.contains('project');

  // ── Pattern scorer (0–100) ─────────────────────────────────────────────────
  // Rewards tasks that align with the user's proven productive hours and
  // current focus momentum.

  static double _scorePattern(
    Map<String, dynamic> task,
    _UserPatterns p,
    DateTime now,
  ) {
    double score = 50; // neutral baseline when no patterns exist

    if (p.peakHours.isEmpty) return score;

    // Bonus if the task is scheduled during a peak hour
    final raw = (task['startTime'] ?? task['dueDate']) as String?;
    if (raw != null) {
      try {
        final taskHour = DateTime.parse(raw).hour;
        if (p.peakHours.contains(taskHour)) score += 25;
      } catch (_) {}
    }

    // Bonus if user is currently in a peak hour (in-flow now)
    if (p.peakHours.contains(p.currentHour)) score += 15;

    // High-focus quality today → prioritise hard (HIGH/URGENT) tasks
    if (p.avgFocusQuality >= 70) {
      final priority =
          (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
      if (priority == 'URGENT' || priority == 'HIGH') score += 10;
    }

    // Momentum: several sessions already completed today
    if (p.todaySessionCount >= 2) score += 10;

    // Mood modifier — boosts tasks that match current energy level
    if (p.mood != null) {
      final priority = (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
      score += p.mood!.patternModifier(priority);
    }

    return score.clamp(0, 100).toDouble();
  }

  // ── Reason labels (shown as chips on the card) ─────────────────────────────

  static List<String> _buildReasons(
    Map<String, dynamic> task,
    double urgency,
    double deadline,
    double importance,
    double pattern,
    DateTime now,
    MoodType? mood,
  ) {
    final factors = <MapEntry<double, String>>[
      MapEntry(urgency * _wUrgency, _urgencyLabel(task, now)),
      MapEntry(deadline * _wDeadline, _deadlineLabel(task, now)),
      MapEntry(importance * _wImportance, _importanceLabel(task)),
      MapEntry(pattern * _wPattern, _patternLabel(pattern, mood)),
    ];

    factors.sort((a, b) => b.key.compareTo(a.key));
    return factors.take(3).map((e) => e.value).toList();
  }

  static String _urgencyLabel(Map<String, dynamic> task, DateTime now) {
    final priority =
        (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
    final raw = (task['dueDate'] ?? task['startTime']) as String?;
    bool overdue = false;
    if (raw != null) {
      try {
        overdue = DateTime.parse(raw).isBefore(now);
      } catch (_) {}
    }
    if (overdue) return 'Overdue';
    return switch (priority) {
      'URGENT' => 'Urgent',
      'HIGH' => 'High priority',
      'MEDIUM' => 'Medium priority',
      _ => 'Low priority',
    };
  }

  static String _deadlineLabel(Map<String, dynamic> task, DateTime now) {
    final raw = (task['dueDate'] ?? task['startTime']) as String?;
    if (raw == null) return 'No deadline';
    try {
      final due = DateTime.parse(raw);
      if (due.isBefore(now)) return 'Overdue';
      final mins = due.difference(now).inMinutes;
      if (mins < 60) return 'Due in ${mins}m';
      final hrs = (mins / 60).round();
      if (hrs < 24) return 'Due in ${hrs}h';
      return 'Due in ${(hrs / 24).round()}d';
    } catch (_) {
      return 'Has deadline';
    }
  }

  static String _importanceLabel(Map<String, dynamic> task) {
    final subtasks = task['subtasks'];
    final count = subtasks is List ? subtasks.length : 0;
    final mins = (task['estimatedDuration'] as num?)?.toInt() ?? 0;
    if (count >= 3) return '$count subtasks';
    if (mins >= 60) return '${mins}min task';
    final cat = (task['category'] as String?) ?? '';
    if (cat.isNotEmpty) return cat;
    return 'Important';
  }

  static String _patternLabel(double score, [MoodType? mood]) {
    if (mood == MoodType.motivated) return 'Motivated boost';
    if (mood == MoodType.stressed) return 'Stress-adjusted';
    if (mood == MoodType.tired) return 'Energy-adjusted';
    if (score >= 85) return 'Peak hour match';
    if (score >= 70) return 'In your flow';
    if (score >= 55) return 'Good timing';
    return 'Off-peak';
  }

  // ── Recommendation copy ────────────────────────────────────────────────────

  static String _buildRecommendation(
    Map<String, dynamic> task,
    List<String> reasons,
    double total,
    DateTime now,
    _UserPatterns patterns,
  ) {
    final priority =
        (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
    final raw = (task['dueDate'] ?? task['startTime']) as String?;
    bool overdue = false;
    Duration? timeLeft;

    if (raw != null) {
      try {
        final due = DateTime.parse(raw);
        overdue = due.isBefore(now);
        if (!overdue) timeLeft = due.difference(now);
      } catch (_) {}
    }

    if (overdue) {
      return 'This task is overdue. Complete it immediately to get back on track.';
    }

    if (timeLeft != null && timeLeft.inHours < 2) {
      final mins = timeLeft.inMinutes;
      return 'Due in ${mins}m — start this now to hit the deadline.';
    }

    if (timeLeft != null && timeLeft.inHours < 6) {
      return 'Deadline approaching in ${timeLeft.inHours}h. Block time for this soon.';
    }

    if (priority == 'URGENT') {
      return 'Marked urgent. Clear this before taking on anything else.';
    }

    // Mood-aware recommendations
    if (patterns.mood == MoodType.motivated &&
        (priority == 'HIGH' || priority == 'URGENT')) {
      return 'You\'re feeling motivated — ideal time to push hard on this one.';
    }
    if (patterns.mood == MoodType.stressed && priority == 'LOW') {
      return 'Feeling stressed? This is a lighter task — a good win to regain momentum.';
    }
    if (patterns.mood == MoodType.tired && priority == 'LOW') {
      return 'Low energy today — this low-priority task is a manageable starting point.';
    }
    if (patterns.mood == MoodType.happy) {
      return 'Great mood today. Use that positive energy to move this forward.';
    }

    if (patterns.peakHours.contains(patterns.currentHour) &&
        (priority == 'HIGH' || priority == 'URGENT')) {
      return 'You\'re in a peak focus hour. Tackle this high-priority task now.';
    }

    if (patterns.avgFocusQuality >= 70 && patterns.todaySessionCount >= 2) {
      return 'Your focus quality is strong today. A great time to work on this.';
    }

    if (priority == 'HIGH') {
      return 'High-priority task. Complete this before medium and low items.';
    }

    if (total >= 65) {
      return 'Strong overall score. Move this to the top of your queue.';
    }

    return 'Steady progress. Fit this in after your higher-priority tasks.';
  }
}

// ── Internal pattern data class ────────────────────────────────────────────────

class _UserPatterns {
  final Set<int> peakHours;
  final double avgFocusQuality;
  final int todaySessionCount;
  final int currentHour;
  final MoodType? mood;

  const _UserPatterns({
    required this.peakHours,
    required this.avgFocusQuality,
    required this.todaySessionCount,
    required this.currentHour,
    this.mood,
  });
}
