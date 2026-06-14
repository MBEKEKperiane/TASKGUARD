import '../../../theme/app_colors.dart';
import 'package:flutter/material.dart';

enum ScheduleBlockType { task, breakTime, lunch, buffer }

class ScheduleBlock {
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleBlockType type;
  final Map<String, dynamic>? task;
  final String label;
  final String? note;

  const ScheduleBlock({
    required this.startTime,
    required this.endTime,
    required this.type,
    this.task,
    required this.label,
    this.note,
  });

  bool get isTask => type == ScheduleBlockType.task;
  bool get isBreak => type == ScheduleBlockType.breakTime || type == ScheduleBlockType.lunch;
  int get durationMins => endTime.difference(startTime).inMinutes;

  String get priority =>
      (task?['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';

  Color get blockColor => switch (type) {
        ScheduleBlockType.task => _taskColor(),
        ScheduleBlockType.breakTime => const Color(0xFF14B8A6),
        ScheduleBlockType.lunch => const Color(0xFFF59E0B),
        ScheduleBlockType.buffer => const Color(0xFFCBD5E1),
      };

  Color _taskColor() => switch (priority) {
        'URGENT' => const Color(0xFFDC2626),
        'HIGH' => AppColors.priorityHigh,
        'MEDIUM' => AppColors.priorityMedium,
        _ => AppColors.priorityLow,
      };

  String get timeRange {
    String fmt(DateTime dt) {
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    }
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  String get durationLabel {
    if (durationMins < 60) return '${durationMins}m';
    final h = durationMins ~/ 60;
    final m = durationMins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
