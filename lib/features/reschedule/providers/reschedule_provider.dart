import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/reschedule/models/reschedule_plan.dart';
import '../../../services/local_notification_service.dart';
import '../../../services/reschedule_engine.dart';
import '../../../services/task_service.dart';

class RescheduleState {
  final ReschedulePlan? plan;
  final bool isLoading;
  final Set<String> dismissedIds;
  final Set<String> appliedIds;

  const RescheduleState({
    this.plan,
    this.isLoading = false,
    this.dismissedIds = const {},
    this.appliedIds = const {},
  });

  RescheduleState copyWith({
    ReschedulePlan? plan,
    bool? isLoading,
    Set<String>? dismissedIds,
    Set<String>? appliedIds,
  }) =>
      RescheduleState(
        plan: plan ?? this.plan,
        isLoading: isLoading ?? this.isLoading,
        dismissedIds: dismissedIds ?? this.dismissedIds,
        appliedIds: appliedIds ?? this.appliedIds,
      );

  // Suggestions visible to the UI (filtered by dismissed + applied)
  List<TaskRescheduleSuggestion> get visibleSuggestions =>
      plan?.suggestions
          .where((s) =>
              !dismissedIds.contains(s.overdueTask.id) &&
              !appliedIds.contains(s.overdueTask.id))
          .toList() ??
      const [];

  bool get allHandled => visibleSuggestions.isEmpty && plan != null;
}

class RescheduleNotifier extends StateNotifier<RescheduleState> {
  final _taskService = TaskService();

  RescheduleNotifier() : super(const RescheduleState());

  Future<void> analyze() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final plan = await RescheduleEngine.analyze();
    if (mounted) {
      state = state.copyWith(plan: plan, isLoading: false);
    }
  }

  /// Reschedules [taskId] to [slot]. Returns true on success.
  Future<bool> applySlot(String taskId, TimeSlot slot) async {
    try {
      await _taskService.updateTask(taskId, {
        'startTime': slot.start.toIso8601String(),
        'dueDate': slot.end.toIso8601String(),
      });
      final overdue = state.plan?.suggestions
          .map((s) => s.overdueTask)
          .where((o) => o.id == taskId)
          .firstOrNull;
      final title = overdue?.title ?? '';
      await LocalNotificationService.scheduleAllReminders(
        taskId: taskId,
        taskTitle: title,
        startTime: slot.start,
        dueDate: slot.end,
      );
      if (mounted) {
        state = state.copyWith(
          appliedIds: {...state.appliedIds, taskId},
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void dismiss(String taskId) {
    state = state.copyWith(
      dismissedIds: {...state.dismissedIds, taskId},
    );
  }

  void dismissAll() {
    final allIds =
        state.plan?.suggestions.map((s) => s.overdueTask.id).toSet() ?? {};
    state = state.copyWith(dismissedIds: {...state.dismissedIds, ...allIds});
  }

  void reset() {
    state = const RescheduleState();
    analyze();
  }
}

final rescheduleProvider =
    StateNotifierProvider<RescheduleNotifier, RescheduleState>(
  (_) => RescheduleNotifier(),
);
