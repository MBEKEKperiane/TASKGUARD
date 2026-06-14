import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/break_reminder_engine.dart';
import '../models/break_reminder_result.dart';

class BreakReminderNotifier extends StateNotifier<BreakReminderResult?> {
  BreakReminderNotifier() : super(null);

  Future<void> analyze() async {
    final result = await BreakReminderEngine.analyze();
    if (mounted) state = result;
  }

  Future<void> recordBreak() async {
    await BreakReminderEngine.recordBreak();
    // Re-analyze immediately so the banner disappears
    await analyze();
  }
}

final breakReminderProvider =
    StateNotifierProvider<BreakReminderNotifier, BreakReminderResult?>(
  (_) => BreakReminderNotifier(),
);
