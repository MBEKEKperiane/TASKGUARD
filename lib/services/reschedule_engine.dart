import 'package:shared_preferences/shared_preferences.dart';
import '../features/burnout/models/burnout_result.dart';
import '../features/mood/models/mood_entry.dart';
import '../features/reschedule/models/reschedule_plan.dart';
import '../features/schedule/models/schedule_block.dart';
import 'burnout_detector.dart';
import 'local_storage.dart';

class RescheduleEngine {
  RescheduleEngine._();

  static const _dayEndHour = 22;

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<ReschedulePlan> analyze() async {
    final now = DateTime.now();
    final dayEnd = DateTime(now.year, now.month, now.day, _dayEndHour, 0);

    final prefs = await SharedPreferences.getInstance();
    final moodRaw = prefs.getString('wellness_mood');
    final mood = moodRaw != null ? MoodTypeX.fromStorage(moodRaw) : null;

    final burnout = await BurnoutDetector.analyze();
    final burnoutLevel = burnout.level;
    final peakHours = _computePeakHours();

    // Load and deduplicate all tasks
    final seen = <String>{};
    final allTasks = <Map<String, dynamic>>[];
    for (final src in [
      LocalStorage.getTodayTasks(),
      LocalStorage.getAllTasks(),
    ]) {
      for (final t in src.whereType<Map<String, dynamic>>()) {
        final id = t['id'] as String?;
        if (id != null && seen.add(id)) allTasks.add(t);
      }
    }

    // Separate overdue vs pending (not completed, not overdue)
    final overdue = _detectOverdue(allTasks, now);
    final pending = allTasks.where((t) {
      if (t['isCompleted'] == true) return false;
      final id = t['id'] as String?;
      return !overdue.any((o) => o.id == id);
    }).toList();

    if (overdue.isEmpty) {
      return ReschedulePlan(
        suggestions: const [],
        alternatives: const [],
        workloadLevel: burnoutLevel,
        mood: mood,
      );
    }

    // Build per-task suggestions
    final busyTasks = allTasks
        .where((t) => t['isCompleted'] != true && t['startTime'] != null)
        .toList();

    final suggestions = overdue.map((info) {
      final slots = _suggestSlots(
        task: info.task,
        from: now,
        dayEnd: dayEnd,
        busyTasks: busyTasks,
        peakHours: peakHours,
      );
      return TaskRescheduleSuggestion(
        overdueTask: info,
        suggestedSlots: slots,
        urgencyNote: _urgencyNote(info, burnoutLevel),
      );
    }).toList();

    // Sort: critical first, then by severity, then by title
    suggestions.sort((a, b) {
      final sOrd = b.overdueTask.severity.index - a.overdueTask.severity.index;
      if (sOrd != 0) return sOrd;
      return a.overdueTask.overdueBy.compareTo(b.overdueTask.overdueBy) * -1;
    });

    // Build alternative schedules
    final overdueMaps = overdue.map((o) => o.task).toList();
    final alternatives = _buildAlternatives(
      overdueTasks: overdueMaps,
      pendingTasks: pending,
      from: now,
      dayEnd: dayEnd,
      level: burnoutLevel,
      mood: mood,
    );

    return ReschedulePlan(
      suggestions: suggestions,
      alternatives: alternatives,
      workloadLevel: burnoutLevel,
      mood: mood,
    );
  }

  // ── Overdue detection ──────────────────────────────────────────────────────

  static List<OverdueTaskInfo> _detectOverdue(
    List<Map<String, dynamic>> tasks,
    DateTime now,
  ) {
    final overdue = <OverdueTaskInfo>[];
    for (final t in tasks) {
      if (t['isCompleted'] == true) continue;
      final rawDue = (t['dueDate'] ?? t['startTime']) as String?;
      if (rawDue == null) continue;
      try {
        final due = DateTime.parse(rawDue);
        if (due.isBefore(now)) {
          final overdueBy = now.difference(due);
          overdue.add(OverdueTaskInfo(
            task: t,
            overdueBy: overdueBy,
            severity: _severity(overdueBy),
          ));
        }
      } catch (_) {}
    }
    return overdue;
  }

  static OverdueSeverity _severity(Duration overdueBy) {
    if (overdueBy.inHours < 4) return OverdueSeverity.mild;
    if (overdueBy.inHours < 48) return OverdueSeverity.moderate;
    return OverdueSeverity.critical;
  }

  // ── Slot suggestion ────────────────────────────────────────────────────────

  static List<TimeSlot> _suggestSlots({
    required Map<String, dynamic> task,
    required DateTime from,
    required DateTime dayEnd,
    required List<Map<String, dynamic>> busyTasks,
    required Set<int> peakHours,
  }) {
    final dur = (task['estimatedDuration'] as num?)?.toInt() ?? 30;
    final taskId = task['id'] as String?;

    // Build busy intervals (excluding the task itself)
    final busyIntervals = <_Interval>[];
    for (final t in busyTasks) {
      if (t['id'] == taskId) continue;
      final rawStart = t['startTime'] as String?;
      if (rawStart == null) continue;
      try {
        final start = DateTime.parse(rawStart);
        final rawDue = t['dueDate'] as String?;
        final end = rawDue != null
            ? DateTime.parse(rawDue)
            : start.add(Duration(
                minutes: (t['estimatedDuration'] as num?)?.toInt() ?? 30));
        busyIntervals.add(_Interval(start, end));
      } catch (_) {}
    }

    final totalAvailMins = dayEnd.difference(from).inMinutes;
    final slots = <TimeSlot>[];
    var candidate = _roundUp(from, 15); // check every 15 minutes

    while (true) {
      final slotEnd = candidate.add(Duration(minutes: dur));
      if (slotEnd.isAfter(dayEnd)) break;

      // Check conflicts
      final hasConflict = busyIntervals
          .any((i) => candidate.isBefore(i.end) && slotEnd.isAfter(i.start));

      if (!hasConflict) {
        final score =
            _scoreSlot(candidate, from, totalAvailMins, peakHours);
        slots.add(TimeSlot(
          start: candidate,
          end: slotEnd,
          reason: _slotReason(candidate, peakHours),
          fitScore: score,
        ));
      }

      candidate = candidate.add(const Duration(minutes: 15));
    }

    slots.sort((a, b) => b.fitScore.compareTo(a.fitScore));
    return slots.take(3).toList();
  }

  static double _scoreSlot(
    DateTime start,
    DateTime from,
    int totalAvailMins,
    Set<int> peakHours,
  ) {
    double score = 0;

    if (peakHours.contains(start.hour)) score += 0.40;

    // Sooner is better
    if (totalAvailMins > 0) {
      final mins = start.difference(from).inMinutes.clamp(0, totalAvailMins);
      score += 0.30 * (1 - mins / totalAvailMins);
    }

    // Morning premium
    if (start.hour >= 9 && start.hour <= 11) {
      score += 0.20;
    } else if (start.hour >= 13 && start.hour <= 15) {
      score += 0.10;
    }

    // Late-evening penalty
    if (start.hour >= 19) score -= 0.20;

    return score.clamp(0.0, 1.0);
  }

  static String _slotReason(DateTime start, Set<int> peakHours) {
    if (peakHours.contains(start.hour)) return 'Peak focus hour';
    if (start.hour >= 9 && start.hour <= 11) return 'Morning focus block';
    if (start.hour >= 13 && start.hour <= 15) return 'Post-lunch productivity';
    if (start.hour >= 15 && start.hour < 19) return 'Afternoon session';
    if (start.hour < 9) return 'Early start';
    return 'Available window';
  }

  static DateTime _roundUp(DateTime dt, int stepMins) {
    final excess = dt.minute % stepMins;
    if (excess == 0) return dt;
    final newMin = dt.minute + (stepMins - excess);
    if (newMin >= 60) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour + 1, newMin - 60);
    }
    return DateTime(dt.year, dt.month, dt.day, dt.hour, newMin);
  }

  // ── Urgency note ───────────────────────────────────────────────────────────

  static String _urgencyNote(OverdueTaskInfo info, BurnoutLevel level) {
    final priority = info.priority;
    if (priority == 'URGENT') return 'Requires immediate attention';
    if (info.severity == OverdueSeverity.critical) {
      return 'Days overdue — reschedule ASAP';
    }
    if (info.overdueBy.inHours >= 12) {
      return 'Half a day overdue — prioritise now';
    }
    if (level == BurnoutLevel.critical || level == BurnoutLevel.high) {
      return 'High workload — slot carefully';
    }
    return 'Reschedule today to stay on track';
  }

  // ── Alternative schedules ──────────────────────────────────────────────────

  static List<AlternativeSchedule> _buildAlternatives({
    required List<Map<String, dynamic>> overdueTasks,
    required List<Map<String, dynamic>> pendingTasks,
    required DateTime from,
    required DateTime dayEnd,
    required BurnoutLevel level,
    required MoodType? mood,
  }) {
    final availableMins = dayEnd.difference(from).inMinutes;
    final maxWork = _maxWorkMins(level, availableMins);

    final urgentOverdue = overdueTasks.where((t) {
      final p = (t['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
      return p == 'URGENT' || p == 'HIGH';
    }).toList();

    // Sort pending by priority weight
    final sortedPending = [...pendingTasks]..sort((a, b) {
        return _priorityWeight(b) - _priorityWeight(a);
      });

    return [
      AlternativeSchedule(
        mode: AlternativeScheduleMode.urgentOnly,
        blocks: _slot(urgentOverdue.isEmpty ? overdueTasks.take(3).toList() : urgentOverdue,
            from, dayEnd, maxWork: maxWork, breakEvery: 60, breakDur: 5),
        taskCount: urgentOverdue.isEmpty
            ? overdueTasks.take(3).length
            : urgentOverdue.length,
        totalWorkMins: (urgentOverdue.isEmpty
                ? overdueTasks.take(3)
                : urgentOverdue)
            .fold(0, (s, t) => s + ((t['estimatedDuration'] as num?)?.toInt() ?? 30)),
      ),
      AlternativeSchedule(
        mode: AlternativeScheduleMode.balanced,
        blocks: _slot(
            [...overdueTasks, ...sortedPending.take(3)], from, dayEnd,
            maxWork: maxWork, breakEvery: 90, breakDur: 10),
        taskCount: overdueTasks.length + sortedPending.take(3).length,
        totalWorkMins: [...overdueTasks, ...sortedPending.take(3)]
            .fold(0, (s, t) => s + ((t['estimatedDuration'] as num?)?.toInt() ?? 30)),
      ),
      AlternativeSchedule(
        mode: AlternativeScheduleMode.fullPower,
        blocks: _slot([...overdueTasks, ...sortedPending], from, dayEnd,
            maxWork: maxWork, breakEvery: 120, breakDur: 5),
        taskCount: overdueTasks.length + sortedPending.length,
        totalWorkMins: [...overdueTasks, ...sortedPending]
            .fold(0, (s, t) => s + ((t['estimatedDuration'] as num?)?.toInt() ?? 30)),
      ),
    ];
  }

  static List<ScheduleBlock> _slot(
    List<Map<String, dynamic>> tasks,
    DateTime from,
    DateTime dayEnd, {
    required int maxWork,
    int breakEvery = 90,
    int breakDur = 10,
  }) {
    final blocks = <ScheduleBlock>[];
    var current = from;
    var workMins = 0;

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final dur = (task['estimatedDuration'] as num?)?.toInt() ?? 30;

      // Insert break if threshold reached
      if (workMins > 0 && workMins >= breakEvery) {
        final breakEnd = current.add(Duration(minutes: breakDur));
        if (!breakEnd.isAfter(dayEnd)) {
          blocks.add(ScheduleBlock(
            startTime: current,
            endTime: breakEnd,
            type: ScheduleBlockType.breakTime,
            label: 'Break',
            note: '${breakDur}m recovery',
          ));
          current = breakEnd;
          workMins = 0;
        }
      }

      if (workMins + dur > maxWork) break;

      final taskEnd = current.add(Duration(minutes: dur));
      if (taskEnd.isAfter(dayEnd)) break;

      blocks.add(ScheduleBlock(
        startTime: current,
        endTime: taskEnd,
        type: ScheduleBlockType.task,
        task: task,
        label: task['title'] as String? ?? 'Task',
      ));
      current = taskEnd;
      workMins += dur;

      // 5-min buffer between tasks
      if (i < tasks.length - 1) {
        final bufEnd = current.add(const Duration(minutes: 5));
        if (!bufEnd.isAfter(dayEnd)) {
          blocks.add(ScheduleBlock(
            startTime: current,
            endTime: bufEnd,
            type: ScheduleBlockType.buffer,
            label: 'Buffer',
          ));
          current = bufEnd;
        }
      }
    }

    return blocks;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static int _maxWorkMins(BurnoutLevel level, int available) =>
      switch (level) {
        BurnoutLevel.critical => available.clamp(0, 120),
        BurnoutLevel.high => available.clamp(0, 240),
        BurnoutLevel.moderate => available.clamp(0, 360),
        BurnoutLevel.low => available,
      };

  static int _priorityWeight(Map<String, dynamic> t) =>
      switch ((t['priority'] as String?)?.toUpperCase() ?? 'MEDIUM') {
        'URGENT' => 4,
        'HIGH' => 3,
        'MEDIUM' => 2,
        _ => 1,
      };

  static Set<int> _computePeakHours() {
    final history = LocalStorage.getFocusHistory()
        .whereType<Map<String, dynamic>>()
        .take(30)
        .toList();
    final hourCounts = <int, int>{};
    for (final s in history) {
      try {
        final dt = DateTime.parse(s['startedAt'] as String);
        hourCounts[dt.hour] = (hourCounts[dt.hour] ?? 0) + 1;
      } catch (_) {}
    }
    if (hourCounts.isEmpty) return {};
    final avg =
        hourCounts.values.reduce((a, b) => a + b) / hourCounts.length;
    return hourCounts.entries
        .where((e) => e.value >= avg)
        .map((e) => e.key)
        .toSet();
  }
}

class _Interval {
  final DateTime start;
  final DateTime end;
  const _Interval(this.start, this.end);
}
