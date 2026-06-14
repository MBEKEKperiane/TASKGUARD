import 'package:shared_preferences/shared_preferences.dart';
import '../features/burnout/models/burnout_result.dart';
import '../features/mood/models/mood_entry.dart';
import '../features/prioritization/models/prioritized_task.dart';
import '../features/schedule/models/generated_schedule.dart';
import '../features/schedule/models/schedule_block.dart';
import 'burnout_detector.dart';
import 'local_storage.dart';
import 'task_prioritization_engine.dart';

/// Offline-first AI schedule generator.
///
/// Slotting algorithm:
///  1. Rank all pending tasks via [TaskPrioritizationEngine].
///  2. Respect a workload cap derived from [BurnoutLevel] and mood.
///  3. Insert mandatory breaks every [breakThreshold] minutes.
///  4. Slot a lunch break when the schedule crosses noon.
///  5. Add 5-min buffers between consecutive tasks.
///  6. Tasks that don't fit → deferred list.
class ScheduleGenerator {
  ScheduleGenerator._();

  // ── Workload caps (minutes of actual focus work) ───────────────────────────
  static int _maxWorkMins(BurnoutLevel level, int available) => switch (level) {
        BurnoutLevel.critical => available.clamp(0, 120),
        BurnoutLevel.high => available.clamp(0, 240),
        BurnoutLevel.moderate => available.clamp(0, 360),
        BurnoutLevel.low => available,
      };

  // ── Mood-aware break thresholds ────────────────────────────────────────────
  static int _breakThreshold(MoodType? mood) => switch (mood) {
        MoodType.tired => 40,
        MoodType.stressed => 50,
        MoodType.motivated => 80,
        _ => 90,
      };

  static int _breakDuration(MoodType? mood) => switch (mood) {
        MoodType.tired => 20,
        MoodType.stressed => 15,
        _ => 10,
      };

  static String _breakNote(MoodType? mood) => switch (mood) {
        MoodType.tired => 'Rest — energy recovery',
        MoodType.stressed => 'Breathe — reset your focus',
        MoodType.motivated => 'Quick recharge',
        _ => 'Short break',
      };

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<GeneratedSchedule> generate({
    required int startHour,
    required int endHour,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ── 1. Load signals ──────────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final moodRaw = prefs.getString('wellness_mood');
    final mood = moodRaw != null ? MoodTypeX.fromStorage(moodRaw) : null;

    final burnout = await BurnoutDetector.analyze();
    final burnoutLevel = burnout.level;
    final peakHours = _computePeakHours();

    // ── 2. Collect pending tasks (today + all, deduplicated) ─────────────────
    final seen = <String>{};
    final allPending = <Map<String, dynamic>>[];
    for (final src in [
      LocalStorage.getTodayTasks(),
      LocalStorage.getAllTasks(),
    ]) {
      for (final t in src.whereType<Map<String, dynamic>>()) {
        if (t['isCompleted'] == true) continue;
        final id = t['id'] as String?;
        if (id != null && seen.add(id)) allPending.add(t);
      }
    }

    if (allPending.isEmpty) {
      return GeneratedSchedule(
        date: today,
        generatedAt: now,
        blocks: const [],
        deferredTasks: const [],
        scheduledTaskCount: 0,
        deferredTaskCount: 0,
        totalWorkMins: 0,
        totalBreakMins: 0,
        scheduleScore: 100,
        workloadLabel: 'Clear',
        workloadLevel: burnoutLevel,
        mood: mood,
      );
    }

    // ── 3. Rank tasks ────────────────────────────────────────────────────────
    final ranked = await TaskPrioritizationEngine.rank(allPending);

    // ── 4. Build timeline ────────────────────────────────────────────────────
    return _buildSchedule(
      ranked: ranked,
      today: today,
      now: now,
      startHour: startHour,
      endHour: endHour,
      mood: mood,
      burnoutLevel: burnoutLevel,
      peakHours: peakHours,
    );
  }

  // ── Core scheduling algorithm ──────────────────────────────────────────────

  static GeneratedSchedule _buildSchedule({
    required List<PrioritizedTask> ranked,
    required DateTime today,
    required DateTime now,
    required int startHour,
    required int endHour,
    required MoodType? mood,
    required BurnoutLevel burnoutLevel,
    required Set<int> peakHours,
  }) {
    final blocks = <ScheduleBlock>[];
    final deferred = <Map<String, dynamic>>[];

    final availableMins = (endHour - startHour) * 60;
    final maxWork = _maxWorkMins(burnoutLevel, availableMins);
    final breakThreshold = _breakThreshold(mood);
    final breakDur = _breakDuration(mood);

    var current =
        DateTime(today.year, today.month, today.day, startHour, 0);
    final hardEnd =
        DateTime(today.year, today.month, today.day, endHour, 0);
    // Effective end: whichever is sooner, hard end or start + max work + breaks
    // We track work minutes and stop scheduling tasks when maxWork is hit.
    var workMins = 0;
    var lunchAdded = startHour >= 13;
    var scheduledCount = 0;

    for (int i = 0; i < ranked.length; i++) {
      final pt = ranked[i];
      final task = pt.task;
      final dur = (task['estimatedDuration'] as num?)?.toInt() ?? 30;

      // ── Lunch insertion (first time we reach noon) ───────────────────────
      if (!lunchAdded && current.hour >= 12) {
        lunchAdded = true;
        final lunchEnd = current.add(const Duration(minutes: 30));
        if (!lunchEnd.isAfter(hardEnd)) {
          blocks.add(ScheduleBlock(
            startTime: current,
            endTime: lunchEnd,
            type: ScheduleBlockType.lunch,
            label: 'Lunch Break',
            note: '30 min recharge',
          ));
          current = lunchEnd;
          workMins = 0; // reset break counter after lunch
        }
      }

      // ── Break insertion (work threshold reached) ──────────────────────────
      if (workMins >= breakThreshold) {
        final breakEnd =
            current.add(Duration(minutes: breakDur));
        if (!breakEnd.isAfter(hardEnd)) {
          blocks.add(ScheduleBlock(
            startTime: current,
            endTime: breakEnd,
            type: ScheduleBlockType.breakTime,
            label: 'Break',
            note: _breakNote(mood),
          ));
          current = breakEnd;
          workMins = 0;
        }
      }

      // ── Capacity check ─────────────────────────────────────────────────────
      if (workMins + dur > maxWork) {
        deferred.add(task);
        continue;
      }

      // ── Time bounds check ──────────────────────────────────────────────────
      final taskEnd = current.add(Duration(minutes: dur));
      if (taskEnd.isAfter(hardEnd)) {
        deferred.add(task);
        continue;
      }

      // ── Schedule the task ──────────────────────────────────────────────────
      final note = _taskNote(task, current, peakHours, mood, burnoutLevel);
      blocks.add(ScheduleBlock(
        startTime: current,
        endTime: taskEnd,
        type: ScheduleBlockType.task,
        task: task,
        label: task['title'] as String? ?? 'Task',
        note: note,
      ));
      current = taskEnd;
      workMins += dur;
      scheduledCount++;

      // ── 5-min buffer between tasks ─────────────────────────────────────────
      final hasMore = i < ranked.length - 1;
      if (hasMore) {
        final bufEnd = current.add(const Duration(minutes: 5));
        if (!bufEnd.isAfter(hardEnd) && workMins < maxWork) {
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

    // ── Compute final stats ──────────────────────────────────────────────────
    final totalWork = blocks
        .where((b) => b.type == ScheduleBlockType.task)
        .fold(0, (sum, b) => sum + b.durationMins);
    final totalBreak = blocks
        .where((b) =>
            b.type == ScheduleBlockType.breakTime ||
            b.type == ScheduleBlockType.lunch)
        .fold(0, (sum, b) => sum + b.durationMins);

    final score = _computeScore(
        scheduledCount, deferred.length, burnoutLevel, peakHours, blocks);

    return GeneratedSchedule(
      date: today,
      generatedAt: now,
      blocks: blocks,
      deferredTasks: deferred,
      scheduledTaskCount: scheduledCount,
      deferredTaskCount: deferred.length,
      totalWorkMins: totalWork,
      totalBreakMins: totalBreak,
      scheduleScore: score,
      workloadLabel: _workloadLabel(totalWork, availableMins),
      workloadLevel: burnoutLevel,
      mood: mood,
    );
  }

  // ── Task note copy ─────────────────────────────────────────────────────────

  static String? _taskNote(
    Map<String, dynamic> task,
    DateTime slot,
    Set<int> peakHours,
    MoodType? mood,
    BurnoutLevel burnout,
  ) {
    final priority = (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';

    // Overdue marker
    final rawDue = (task['dueDate'] ?? task['startTime']) as String?;
    if (rawDue != null) {
      try {
        if (DateTime.parse(rawDue).isBefore(DateTime.now())) {
          return 'Overdue — act now';
        }
      } catch (_) {}
    }

    if (mood == MoodType.motivated && (priority == 'HIGH' || priority == 'URGENT')) {
      return 'You\'re fired up — push hard';
    }
    if (mood == MoodType.stressed && priority == 'LOW') {
      return 'Easy win — build momentum';
    }
    if (mood == MoodType.tired && priority == 'LOW') {
      return 'Manageable task for low energy';
    }
    if (peakHours.contains(slot.hour)) {
      return 'Peak focus hour';
    }
    if (priority == 'URGENT') return 'Critical — do this first';
    if (priority == 'HIGH') return 'High priority';
    if (burnout == BurnoutLevel.high || burnout == BurnoutLevel.critical) {
      return 'Workload adjusted';
    }
    return null;
  }

  // ── Schedule quality score (0–100) ────────────────────────────────────────

  static double _computeScore(
    int scheduled,
    int deferred,
    BurnoutLevel burnout,
    Set<int> peakHours,
    List<ScheduleBlock> blocks,
  ) {
    double score = 80;

    // Penalise deferred tasks
    score -= (deferred * 8).clamp(0, 40);

    // Reward peak-hour alignment
    final taskBlocks = blocks.where((b) => b.isTask).toList();
    if (peakHours.isNotEmpty && taskBlocks.isNotEmpty) {
      final peakCount =
          taskBlocks.where((b) => peakHours.contains(b.startTime.hour)).length;
      score += (peakCount / taskBlocks.length * 20).clamp(0, 20);
    }

    // Workload-aware cap
    score -= switch (burnout) {
      BurnoutLevel.critical => 20,
      BurnoutLevel.high => 10,
      BurnoutLevel.moderate => 5,
      BurnoutLevel.low => 0,
    };

    // Reward for having breaks scheduled
    final hasBreaks = blocks.any((b) => b.isBreak);
    if (hasBreaks) score += 5;

    return score.clamp(0, 100).toDouble();
  }

  // ── Workload label ─────────────────────────────────────────────────────────

  static String _workloadLabel(int workMins, int availableMins) {
    if (availableMins == 0) return 'Clear';
    final pct = workMins / availableMins;
    if (pct < 0.20) return 'Light';
    if (pct < 0.45) return 'Balanced';
    if (pct < 0.65) return 'Productive';
    if (pct < 0.85) return 'Heavy';
    return 'Intense';
  }

  // ── Peak hours from focus history ──────────────────────────────────────────

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

    final avg = hourCounts.values.reduce((a, b) => a + b) /
        hourCounts.length;
    return hourCounts.entries
        .where((e) => e.value >= avg)
        .map((e) => e.key)
        .toSet();
  }
}
