import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/local_storage.dart';
import '../../../services/task_prioritization_engine.dart';
import '../models/prioritized_task.dart';

class PrioritizationNotifier extends StateNotifier<PrioritizationState> {
  PrioritizationNotifier() : super(const PrioritizationState());

  Future<void> rank() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final tasks = LocalStorage.getTodayTasks()
        .whereType<Map<String, dynamic>>()
        .toList();

    final ranked = await TaskPrioritizationEngine.rank(tasks);

    state = state.copyWith(
      rankedTasks: ranked,
      isLoading: false,
      lastRefreshed: DateTime.now(),
    );
  }
}

final prioritizationProvider =
    StateNotifierProvider<PrioritizationNotifier, PrioritizationState>(
  (_) => PrioritizationNotifier(),
);
