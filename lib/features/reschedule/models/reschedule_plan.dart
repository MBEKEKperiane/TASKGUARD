import 'package:flutter/material.dart';
import '../../../features/burnout/models/burnout_result.dart';
import '../../../features/mood/models/mood_entry.dart';
import '../../../features/schedule/models/schedule_block.dart';

enum OverdueSeverity { mild, moderate, critical }

extension OverdueSeverityX on OverdueSeverity {
  Color get color => switch (this) {
        OverdueSeverity.mild => const Color(0xFFF59E0B),
        OverdueSeverity.moderate => const Color(0xFFF97316),
        OverdueSeverity.critical => const Color(0xFFDC2626),
      };

  String get label => switch (this) {
        OverdueSeverity.mild => 'Mild',
        OverdueSeverity.moderate => 'Moderate',
        OverdueSeverity.critical => 'Critical',
      };
}

class OverdueTaskInfo {
  final Map<String, dynamic> task;
  final Duration overdueBy;
  final OverdueSeverity severity;

  const OverdueTaskInfo({
    required this.task,
    required this.overdueBy,
    required this.severity,
  });

  String get id => task['id'] as String? ?? '';
  String get title => task['title'] as String? ?? 'Untitled';
  String get priority =>
      (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
  int get estimatedDuration =>
      (task['estimatedDuration'] as num?)?.toInt() ?? 30;

  String get overdueByLabel {
    final h = overdueBy.inHours;
    final d = overdueBy.inDays;
    if (d >= 1) return '${d}d overdue';
    if (h >= 1) return '${h}h overdue';
    return '${overdueBy.inMinutes}m overdue';
  }
}

class TimeSlot {
  final DateTime start;
  final DateTime end;
  final String reason;
  final double fitScore;

  const TimeSlot({
    required this.start,
    required this.end,
    required this.reason,
    required this.fitScore,
  });

  int get durationMins => end.difference(start).inMinutes;

  String get timeRange {
    String fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    }
    return '${fmt(start)} – ${fmt(end)}';
  }
}

class TaskRescheduleSuggestion {
  final OverdueTaskInfo overdueTask;
  final List<TimeSlot> suggestedSlots;
  final String urgencyNote;

  const TaskRescheduleSuggestion({
    required this.overdueTask,
    required this.suggestedSlots,
    required this.urgencyNote,
  });

  bool get hasSlots => suggestedSlots.isNotEmpty;
}

enum AlternativeScheduleMode { urgentOnly, balanced, fullPower }

extension AlternativeScheduleModeX on AlternativeScheduleMode {
  String get label => switch (this) {
        AlternativeScheduleMode.urgentOnly => 'Urgent Only',
        AlternativeScheduleMode.balanced => 'Balanced',
        AlternativeScheduleMode.fullPower => 'Full Power',
      };

  String get description => switch (this) {
        AlternativeScheduleMode.urgentOnly =>
          'Critical items only — focused and fast',
        AlternativeScheduleMode.balanced =>
          'Overdue tasks with breathing room',
        AlternativeScheduleMode.fullPower =>
          'Clear the entire backlog today',
      };

  IconData get icon => switch (this) {
        AlternativeScheduleMode.urgentOnly => Icons.priority_high_rounded,
        AlternativeScheduleMode.balanced => Icons.balance_rounded,
        AlternativeScheduleMode.fullPower => Icons.bolt_rounded,
      };

  Color get color => switch (this) {
        AlternativeScheduleMode.urgentOnly => const Color(0xFFDC2626),
        AlternativeScheduleMode.balanced => const Color(0xFF22C55E),
        AlternativeScheduleMode.fullPower => const Color(0xFFE91E8C),
      };
}

class AlternativeSchedule {
  final AlternativeScheduleMode mode;
  final List<ScheduleBlock> blocks;
  final int taskCount;
  final int totalWorkMins;

  const AlternativeSchedule({
    required this.mode,
    required this.blocks,
    required this.taskCount,
    required this.totalWorkMins,
  });

  String get totalWorkLabel {
    if (totalWorkMins < 60) return '${totalWorkMins}m';
    final h = totalWorkMins ~/ 60;
    final m = totalWorkMins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class ReschedulePlan {
  final List<TaskRescheduleSuggestion> suggestions;
  final List<AlternativeSchedule> alternatives;
  final BurnoutLevel workloadLevel;
  final MoodType? mood;

  const ReschedulePlan({
    required this.suggestions,
    required this.alternatives,
    required this.workloadLevel,
    this.mood,
  });

  bool get isEmpty => suggestions.isEmpty;
  int get overdueCount => suggestions.length;
}
