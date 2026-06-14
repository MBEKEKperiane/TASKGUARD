import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class DailyReport {
  final DateTime date;
  final int completedTasks;
  final int missedTasks;
  final int totalTasks;
  final double focusHours;
  final double productivityScore;
  final double completionRate;
  final double avgFocusScore;
  final int focusSessions;

  const DailyReport({
    required this.date,
    required this.completedTasks,
    required this.missedTasks,
    required this.totalTasks,
    required this.focusHours,
    required this.productivityScore,
    required this.completionRate,
    required this.avgFocusScore,
    required this.focusSessions,
  });

  factory DailyReport.empty(DateTime date) => DailyReport(
        date: date,
        completedTasks: 0,
        missedTasks: 0,
        totalTasks: 0,
        focusHours: 0,
        productivityScore: 0,
        completionRate: 0,
        avgFocusScore: 0,
        focusSessions: 0,
      );

  bool get hasData => focusSessions > 0 || totalTasks > 0;

  String get scoreLabel {
    if (productivityScore >= 90) return 'Elite';
    if (productivityScore >= 75) return 'Strong';
    if (productivityScore >= 55) return 'Building';
    if (productivityScore >= 30) return 'Getting Started';
    return 'No Data';
  }

  Color get scoreColor {
    if (productivityScore >= 75) return AppColors.secondary;
    if (productivityScore >= 50) return AppColors.warning;
    if (productivityScore >= 25) return AppColors.primary;
    return AppColors.error;
  }

  String get focusTimeLabel {
    final totalMins = (focusHours * 60).round();
    if (totalMins < 60) return '${totalMins}m';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
