import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_models.dart';
import '../../../services/health_engine.dart';

class HealthState {
  final HealthEntry? todayEntry;
  final List<HealthEntry> recentEntries;
  final HealthInsight? insight;
  final bool isLoading;

  const HealthState({
    this.todayEntry,
    this.recentEntries = const [],
    this.insight,
    this.isLoading = false,
  });

  bool get hasCheckedInToday => todayEntry != null;

  WorkloadLevel? get workload => insight?.workload;

  HealthState copyWith({
    HealthEntry? todayEntry,
    List<HealthEntry>? recentEntries,
    HealthInsight? insight,
    bool? isLoading,
    bool clearTodayEntry = false,
  }) =>
      HealthState(
        todayEntry: clearTodayEntry ? null : (todayEntry ?? this.todayEntry),
        recentEntries: recentEntries ?? this.recentEntries,
        insight: insight ?? this.insight,
        isLoading: isLoading ?? this.isLoading,
      );
}

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(const HealthState()) {
    _load();
  }

  void _load() {
    final today = HealthEngine.todayEntry();
    final recent = HealthEngine.recentEntries();
    final insight = today != null ? HealthEngine.insight(today) : null;
    state = HealthState(
      todayEntry: today,
      recentEntries: recent,
      insight: insight,
    );
  }

  Future<void> logToday({
    required double sleepHours,
    required int energyLevel,
    required HealthMood mood,
  }) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final entry = HealthEntry(
      date: date,
      sleepHours: sleepHours,
      energyLevel: energyLevel,
      mood: mood,
    );
    await HealthEngine.saveEntry(entry);
    _load();
  }

  void refresh() => _load();
}

final healthProvider =
    StateNotifierProvider<HealthNotifier, HealthState>(
  (_) => HealthNotifier(),
);
