import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/schedule_generator.dart';
import '../models/generated_schedule.dart';

class ScheduleState {
  final GeneratedSchedule? schedule;
  final bool isLoading;
  final int startHour;
  final int endHour;

  const ScheduleState({
    this.schedule,
    this.isLoading = false,
    this.startHour = 9,
    this.endHour = 18,
  });

  ScheduleState copyWith({
    GeneratedSchedule? schedule,
    bool? isLoading,
    int? startHour,
    int? endHour,
  }) =>
      ScheduleState(
        schedule: schedule ?? this.schedule,
        isLoading: isLoading ?? this.isLoading,
        startHour: startHour ?? this.startHour,
        endHour: endHour ?? this.endHour,
      );
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier() : super(const ScheduleState());

  Future<void> generate() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final schedule = await ScheduleGenerator.generate(
      startHour: state.startHour,
      endHour: state.endHour,
    );
    if (mounted) {
      state = state.copyWith(schedule: schedule, isLoading: false);
    }
  }

  void setStartHour(int h) {
    if (h >= state.endHour) return;
    state = state.copyWith(startHour: h);
  }

  void setEndHour(int h) {
    if (h <= state.startHour) return;
    state = state.copyWith(endHour: h);
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (_) => ScheduleNotifier(),
);
