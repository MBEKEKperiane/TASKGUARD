import '../features/deadline/models/deadline_models.dart';
import '../features/health/models/health_models.dart';
import 'health_engine.dart';
import 'local_storage.dart';

// ── Internal accumulator ───────────────────────────────────────────────────────

class _PriorityStats {
  int total = 0;
  int completed = 0;

  void record(bool wasCompleted) {
    total++;
    if (wasCompleted) completed++;
  }

  double get rate => total == 0 ? 0.65 : completed / total;
}

class _HistoricalData {
  final Map<String, _PriorityStats> byPriority;
  final double overallRate;
  final int sampleSize;

  const _HistoricalData({
    required this.byPriority,
    required this.overallRate,
    required this.sampleSize,
  });

  double rateFor(String priority) =>
      byPriority[priority.toUpperCase()]?.rate ?? 0.65;

  int sampleFor(String priority) =>
      byPriority[priority.toUpperCase()]?.total ?? 0;
}

// ════════════════════════════════════════════════════════════════════════════════
// DeadlinePredictor — fully offline, pure LocalStorage + HealthEngine
// ════════════════════════════════════════════════════════════════════════════════

class DeadlinePredictor {
  DeadlinePredictor._();

  /// Entry point. Returns a [DeadlineReport] covering all pending tasks
  /// that have a due date set.
  static DeadlineReport analyze() {
    final allTasks = LocalStorage.getAllTasks();
    final health = HealthEngine.todayEntry();
    final focusHistory = LocalStorage.getFocusHistory();

    final history = _buildHistorical(allTasks);
    final avgFocusHours = _avgDailyFocusHours(focusHistory);

    final pending = allTasks
        .where((t) =>
            t['isCompleted'] != true &&
            (t['dueDate'] as String? ?? '').isNotEmpty)
        .toList();

    final predictions = pending
        .map((t) => _predict(t, history, health, avgFocusHours))
        .whereType<DeadlinePrediction>()
        .toList();

    return DeadlineReport(
      predictions: predictions,
      generatedAt: DateTime.now(),
      overallCompletionRate: history.overallRate,
      avgDailyFocusHours: avgFocusHours,
      historicalSampleSize: history.sampleSize,
    );
  }

  // ── Historical data ────────────────────────────────────────────────────────

  static _HistoricalData _buildHistorical(List<Map<String, dynamic>> allTasks) {
    final now = DateTime.now();
    final past = allTasks.where((t) {
      final raw = t['dueDate'] as String?;
      if (raw == null || raw.isEmpty) return false;
      final due = DateTime.tryParse(raw);
      return due != null && due.isBefore(now);
    }).toList();

    final byPriority = <String, _PriorityStats>{};
    for (final t in past) {
      final p = ((t['priority'] ?? 'MEDIUM') as String).toUpperCase();
      (byPriority[p] ??= _PriorityStats()).record(t['isCompleted'] == true);
    }

    final completedCount = past.where((t) => t['isCompleted'] == true).length;
    final overallRate =
        past.isEmpty ? 0.65 : completedCount / past.length;

    return _HistoricalData(
      byPriority: byPriority,
      overallRate: overallRate,
      sampleSize: past.length,
    );
  }

  // ── Focus velocity ─────────────────────────────────────────────────────────

  static double _avgDailyFocusHours(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0;
    final now = DateTime.now();
    double totalMins = 0;
    int days = 0;

    for (int d = 0; d < 7; d++) {
      final day = now.subtract(Duration(days: d));
      final dayKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      double dayMins = 0;
      for (final s in sessions) {
        final raw = s['startedAt'] as String?;
        if (raw == null) continue;
        if (raw.startsWith(dayKey)) {
          dayMins += ((s['actualMins'] as num?) ?? 0).toDouble();
        }
      }
      if (dayMins > 0) {
        totalMins += dayMins;
        days++;
      }
    }
    if (days == 0) return 0;
    return (totalMins / days) / 60.0;
  }

  // ── Core prediction ────────────────────────────────────────────────────────

  static DeadlinePrediction? _predict(
    Map<String, dynamic> task,
    _HistoricalData history,
    HealthEntry? health,
    double avgDailyFocusHours,
  ) {
    final dueStr = task['dueDate'] as String?;
    if (dueStr == null || dueStr.isEmpty) return null;

    final DateTime dueDate;
    try {
      dueDate = DateTime.parse(dueStr);
    } catch (_) {
      return null;
    }

    final now = DateTime.now();
    final hoursUntilDue = dueDate.difference(now).inMinutes / 60.0;
    final isOverdue = hoursUntilDue < 0;

    final priority = ((task['priority'] ?? 'MEDIUM') as String).toUpperCase();
    final estimatedHours = _estimatedHours(task);

    // ── Historical ──────────────────────────────────────────────────────────
    final completionRate = history.rateFor(priority);
    final sampleSize = history.sampleFor(priority);

    // ── Energy factor ───────────────────────────────────────────────────────
    // Low energy → user works slower → effective hours shrink
    final energyFactor = health != null ? (health.energyLevel / 5.0) : 0.70;

    // Effective remaining hours adjusted for energy capacity
    final effectiveHours =
        isOverdue ? hoursUntilDue : hoursUntilDue * energyFactor;

    // ── Time pressure (0–1) ─────────────────────────────────────────────────
    final timePressure = _timePressure(effectiveHours, estimatedHours, isOverdue);

    // ── Risk score (0–1) ───────────────────────────────────────────────────
    // Time pressure is the dominant signal (55%), history (35%), energy (10%)
    final riskScore =
        (timePressure * 0.55 + (1.0 - completionRate) * 0.35 + (1.0 - energyFactor) * 0.10)
            .clamp(0.0, 1.0);

    // ── Risk level ──────────────────────────────────────────────────────────
    final RiskLevel riskLevel;
    if (isOverdue) {
      riskLevel = RiskLevel.overdue;
    } else if (riskScore >= 0.70) {
      riskLevel = RiskLevel.critical;
    } else if (riskScore >= 0.40) {
      riskLevel = RiskLevel.atRisk;
    } else {
      riskLevel = RiskLevel.onTrack;
    }

    // ── Confidence ──────────────────────────────────────────────────────────
    int confidence = 40;
    if (sampleSize >= 3) confidence += 15;
    if (sampleSize >= 8) confidence += 15;
    if (task['estimatedDuration'] != null) confidence += 20;
    if (health != null) confidence += 5;
    confidence = confidence.clamp(30, 100);

    // ── Reasons ─────────────────────────────────────────────────────────────
    final reasons = _buildReasons(
      hoursUntilDue: hoursUntilDue,
      estimatedHours: estimatedHours,
      completionRate: completionRate,
      sampleSize: sampleSize,
      priority: priority,
      health: health,
      energyFactor: energyFactor,
      subtaskCount: (task['subtasks'] as List?)?.length ?? 0,
      avgDailyFocusHours: avgDailyFocusHours,
    );

    // ── Recommend start-by ──────────────────────────────────────────────────
    DateTime? recommendStartBy;
    if (!isOverdue && riskLevel != RiskLevel.onTrack) {
      final bufferMultiplier =
          riskLevel == RiskLevel.critical ? 1.35 : 1.15;
      final startInHours =
          hoursUntilDue - (estimatedHours * bufferMultiplier);
      if (startInHours >= 0.25) {
        // At least 15 min from now
        recommendStartBy =
            now.add(Duration(minutes: (startInHours * 60).round()));
      } else if (startInHours >= 0) {
        recommendStartBy = now; // Start immediately
      }
    }

    return DeadlinePrediction(
      task: task,
      riskLevel: riskLevel,
      riskScore: (riskScore * 100).round(),
      confidence: confidence,
      reasons: reasons,
      hoursUntilDue: hoursUntilDue,
      estimatedHoursNeeded: estimatedHours,
      historicalCompletionRate: completionRate,
      historicalSampleSize: sampleSize,
      recommendStartBy: recommendStartBy,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _estimatedHours(Map<String, dynamic> task) {
    final est = task['estimatedDuration'];
    final baseMins = est != null
        ? (est as num).toDouble()
        : _defaultMins(((task['priority'] ?? 'MEDIUM') as String).toUpperCase());

    // Subtask complexity multiplier
    final subtasks = (task['subtasks'] as List?) ?? [];
    final multiplier = subtasks.isEmpty ? 1.0 : (1.0 + subtasks.length * 0.18).clamp(1.0, 3.0);

    return (baseMins * multiplier) / 60.0;
  }

  static double _defaultMins(String priority) => switch (priority) {
        'URGENT' => 90,
        'HIGH' => 60,
        'MEDIUM' => 45,
        _ => 30,
      };

  static double _timePressure(
      double effectiveHours, double estimatedHours, bool isOverdue) {
    if (isOverdue) return 1.0;
    if (estimatedHours <= 0) return 0.10;
    final ratio = effectiveHours / estimatedHours;
    if (ratio <= 0.0) return 1.00;
    if (ratio <= 0.40) return 0.93;
    if (ratio <= 0.70) return 0.82;
    if (ratio <= 1.10) return 0.65;
    if (ratio <= 1.80) return 0.42;
    if (ratio <= 3.00) return 0.18;
    return 0.05;
  }

  static List<String> _buildReasons({
    required double hoursUntilDue,
    required double estimatedHours,
    required double completionRate,
    required int sampleSize,
    required String priority,
    required HealthEntry? health,
    required double energyFactor,
    required int subtaskCount,
    required double avgDailyFocusHours,
  }) {
    final reasons = <String>[];

    // 1. Time vs estimate
    if (hoursUntilDue < 0) {
      final over = (-hoursUntilDue);
      reasons.add(over < 24
          ? '${over.toStringAsFixed(1)}h past the due date'
          : '${(over / 24).round()}d past the due date');
    } else {
      final remStr = _fmtHours(hoursUntilDue);
      final estStr = _fmtHours(estimatedHours);
      final buffer = hoursUntilDue - estimatedHours;
      if (buffer < 0) {
        reasons.add(
            '$remStr remaining · needs $estStr · ${_fmtHours(-buffer)} short');
      } else {
        reasons.add(
            '$remStr remaining · est. $estStr needed · ${_fmtHours(buffer)} buffer');
      }
    }

    // 2. Historical completion rate
    if (sampleSize > 0) {
      final rate = (completionRate * 100).round();
      final prioLabel = _prioLabel(priority);
      reasons.add(
          '$rate% on-time rate for $prioLabel tasks ($sampleSize past)');
    } else {
      reasons.add('No history for $priority tasks — using a neutral estimate');
    }

    // 3. Energy impact
    if (health != null) {
      if (health.energyLevel <= 2) {
        final slowdown = ((1 - energyFactor) * 100).round();
        reasons.add(
            'Low energy (${health.energyLevel}/5) reduces capacity by ~$slowdown%');
      } else if (health.energyLevel >= 4) {
        reasons
            .add('High energy (${health.energyLevel}/5) — peak efficiency today');
      }
    }

    // 4. Subtask or focus velocity
    if (subtaskCount >= 3) {
      reasons.add('$subtaskCount subtasks add significant complexity');
    } else if (avgDailyFocusHours > 0) {
      reasons.add(
          '${avgDailyFocusHours.toStringAsFixed(1)}h avg daily focus this week');
    }

    return reasons.take(4).toList();
  }

  static String _fmtHours(double h) {
    if (h < 0) {
      return _fmtHours(-h);
    }
    if (h < 1) return '${(h * 60).round()}m';
    if (h < 24) {
      final whole = h.floor();
      final mins = ((h - whole) * 60).round();
      return mins > 0 ? '${whole}h ${mins}m' : '${whole}h';
    }
    final days = (h / 24).floor();
    final rem = (h - days * 24).round();
    return rem > 0 ? '${days}d ${rem}h' : '${days}d';
  }

  static String _prioLabel(String priority) => switch (priority) {
        'URGENT' => 'urgent',
        'HIGH' => 'high-priority',
        'LOW' => 'low-priority',
        _ => 'medium-priority',
      };
}
