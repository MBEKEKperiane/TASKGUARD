import '../../../features/burnout/models/burnout_result.dart';
import '../../../features/mood/models/mood_entry.dart';
import 'schedule_block.dart';

class GeneratedSchedule {
  final DateTime date;
  final DateTime generatedAt;
  final List<ScheduleBlock> blocks;
  final List<Map<String, dynamic>> deferredTasks;
  final int scheduledTaskCount;
  final int deferredTaskCount;
  final int totalWorkMins;
  final int totalBreakMins;
  final double scheduleScore;
  final String workloadLabel;
  final BurnoutLevel workloadLevel;
  final MoodType? mood;

  const GeneratedSchedule({
    required this.date,
    required this.generatedAt,
    required this.blocks,
    required this.deferredTasks,
    required this.scheduledTaskCount,
    required this.deferredTaskCount,
    required this.totalWorkMins,
    required this.totalBreakMins,
    required this.scheduleScore,
    required this.workloadLabel,
    required this.workloadLevel,
    this.mood,
  });

  bool get isEmpty => blocks.isEmpty;
  bool get hasDeferredTasks => deferredTasks.isNotEmpty;

  List<ScheduleBlock> get taskBlocks =>
      blocks.where((b) => b.isTask).toList();

  List<ScheduleBlock> get breakBlocks =>
      blocks.where((b) => b.isBreak).toList();

  DateTime? get scheduleStart => blocks.isEmpty ? null : blocks.first.startTime;
  DateTime? get scheduleEnd => blocks.isEmpty ? null : blocks.last.endTime;

  String get totalWorkLabel {
    if (totalWorkMins < 60) return '${totalWorkMins}m';
    final h = totalWorkMins ~/ 60;
    final m = totalWorkMins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get scoreLabel {
    if (scheduleScore >= 85) return 'Optimal';
    if (scheduleScore >= 70) return 'Solid';
    if (scheduleScore >= 50) return 'Balanced';
    if (scheduleScore >= 30) return 'Light';
    return 'Minimal';
  }
}
