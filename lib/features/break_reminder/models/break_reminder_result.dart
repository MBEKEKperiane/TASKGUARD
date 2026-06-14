import '../../mood/models/mood_entry.dart';

class BreakReminderResult {
  final bool isBreakDue;
  final int minutesWorked;
  final int thresholdMins;
  final String message;
  final String subMessage;
  final DateTime? lastBreakAt;
  final MoodType? mood;

  const BreakReminderResult({
    required this.isBreakDue,
    required this.minutesWorked,
    required this.thresholdMins,
    required this.message,
    required this.subMessage,
    this.lastBreakAt,
    this.mood,
  });

  /// How many minutes remain until the next break is due. 0 when already due.
  int get minutesUntilBreak =>
      isBreakDue ? 0 : (thresholdMins - minutesWorked).clamp(0, thresholdMins);

  double get progressFraction =>
      (minutesWorked / thresholdMins).clamp(0.0, 1.0);
}
