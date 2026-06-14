import 'package:flutter/material.dart';

enum BurnoutLevel { low, moderate, high, critical }

extension BurnoutLevelX on BurnoutLevel {
  String get label => switch (this) {
        BurnoutLevel.critical => 'Critical',
        BurnoutLevel.high => 'High Risk',
        BurnoutLevel.moderate => 'Moderate',
        BurnoutLevel.low => 'Healthy',
      };

  Color get color => switch (this) {
        BurnoutLevel.critical => const Color(0xFFDC2626),
        BurnoutLevel.high => const Color(0xFFF97316),
        BurnoutLevel.moderate => const Color(0xFFF59E0B),
        BurnoutLevel.low => const Color(0xFF22C55E),
      };

  // Maps to the string format SuggestionEngine already expects.
  String get apiLevel => switch (this) {
        BurnoutLevel.critical || BurnoutLevel.high => 'HIGH',
        BurnoutLevel.moderate => 'MEDIUM',
        BurnoutLevel.low => 'LOW',
      };
}

class RescheduleSuggestion {
  final String taskId;
  final String taskTitle;
  final String priority;
  final String? dueDate;
  final String reason;

  const RescheduleSuggestion({
    required this.taskId,
    required this.taskTitle,
    required this.priority,
    this.dueDate,
    required this.reason,
  });
}

class BurnoutResult {
  final BurnoutLevel level;
  final int score; // 0-100 risk score
  final List<String> warnings;
  final List<RescheduleSuggestion> rescheduleSuggestions;
  final String headline;
  final String advice;

  const BurnoutResult({
    required this.level,
    required this.score,
    required this.warnings,
    required this.rescheduleSuggestions,
    required this.headline,
    required this.advice,
  });
}
