import 'package:flutter/material.dart';

// ── Risk level ─────────────────────────────────────────────────────────────────

enum RiskLevel { onTrack, atRisk, critical, overdue }

extension RiskLevelX on RiskLevel {
  String get label => switch (this) {
        RiskLevel.onTrack => 'On Track',
        RiskLevel.atRisk => 'At Risk',
        RiskLevel.critical => 'Critical',
        RiskLevel.overdue => 'Overdue',
      };

  String get emoji => switch (this) {
        RiskLevel.onTrack => '✅',
        RiskLevel.atRisk => '⚠️',
        RiskLevel.critical => '🔴',
        RiskLevel.overdue => '❌',
      };

  Color get color => switch (this) {
        RiskLevel.onTrack => const Color(0xFF22C55E),
        RiskLevel.atRisk => const Color(0xFFF59E0B),
        RiskLevel.critical => const Color(0xFFF97316),
        RiskLevel.overdue => const Color(0xFFEF4444),
      };

  // Higher = needs more urgent attention
  int get sortWeight => switch (this) {
        RiskLevel.overdue => 4,
        RiskLevel.critical => 3,
        RiskLevel.atRisk => 2,
        RiskLevel.onTrack => 1,
      };

  String get headline => switch (this) {
        RiskLevel.onTrack => 'Likely on time',
        RiskLevel.atRisk => 'May be delayed',
        RiskLevel.critical => 'High risk of missing',
        RiskLevel.overdue => 'Past deadline',
      };
}

// ── Per-task prediction ────────────────────────────────────────────────────────

class DeadlinePrediction {
  final Map<String, dynamic> task;
  final RiskLevel riskLevel;
  final int riskScore; // 0–100 (100 = most at risk)
  final int confidence; // 0–100 %
  final List<String> reasons; // up to 4 explanatory bullets
  final double hoursUntilDue; // negative = overdue
  final double estimatedHoursNeeded;
  final double historicalCompletionRate; // 0.0–1.0
  final int historicalSampleSize;
  final DateTime? recommendStartBy; // when to start to stay safe

  const DeadlinePrediction({
    required this.task,
    required this.riskLevel,
    required this.riskScore,
    required this.confidence,
    required this.reasons,
    required this.hoursUntilDue,
    required this.estimatedHoursNeeded,
    required this.historicalCompletionRate,
    required this.historicalSampleSize,
    this.recommendStartBy,
  });

  String get taskTitle => (task['title'] ?? 'Untitled') as String;

  String get taskPriority =>
      ((task['priority'] ?? 'MEDIUM') as String).toUpperCase();

  String? get dueDateIso => task['dueDate'] as String?;
}

// ── Aggregate report ───────────────────────────────────────────────────────────

class DeadlineReport {
  final List<DeadlinePrediction> predictions;
  final DateTime generatedAt;
  final double overallCompletionRate; // 0.0–1.0
  final double avgDailyFocusHours;
  final int historicalSampleSize;

  const DeadlineReport({
    required this.predictions,
    required this.generatedAt,
    required this.overallCompletionRate,
    required this.avgDailyFocusHours,
    required this.historicalSampleSize,
  });

  // ── Computed counts ────────────────────────────────────────────────────────

  int get onTrackCount =>
      predictions.where((p) => p.riskLevel == RiskLevel.onTrack).length;
  int get atRiskCount =>
      predictions.where((p) => p.riskLevel == RiskLevel.atRisk).length;
  int get criticalCount =>
      predictions.where((p) => p.riskLevel == RiskLevel.critical).length;
  int get overdueCount =>
      predictions.where((p) => p.riskLevel == RiskLevel.overdue).length;

  int get warningCount => atRiskCount + criticalCount + overdueCount;

  bool get allClear => warningCount == 0;

  /// Worst risk level present in the report.
  RiskLevel get worstLevel {
    if (overdueCount > 0) return RiskLevel.overdue;
    if (criticalCount > 0) return RiskLevel.critical;
    if (atRiskCount > 0) return RiskLevel.atRisk;
    return RiskLevel.onTrack;
  }

  /// Sorted: worst risk first, then by hours-until-due ascending.
  List<DeadlinePrediction> get sorted {
    return [...predictions]..sort((a, b) {
        final byLevel = b.riskLevel.sortWeight.compareTo(a.riskLevel.sortWeight);
        if (byLevel != 0) return byLevel;
        return a.hoursUntilDue.compareTo(b.hoursUntilDue);
      });
  }

  /// Velocity label based on completion rate.
  String get velocityLabel {
    if (overallCompletionRate >= 0.80) return 'Excellent';
    if (overallCompletionRate >= 0.65) return 'Good';
    if (overallCompletionRate >= 0.45) return 'Moderate';
    return 'Needs Work';
  }

  Color get velocityColor {
    if (overallCompletionRate >= 0.80) return const Color(0xFF22C55E);
    if (overallCompletionRate >= 0.65) return const Color(0xFF3B82F6);
    if (overallCompletionRate >= 0.45) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
