import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/mood_storage.dart';
import '../models/mood_entry.dart';

class MoodState {
  final MoodType? current;
  final List<MoodEntry> history;
  final bool hasLoggedToday;
  final bool isLoading;

  const MoodState({
    this.current,
    this.history = const [],
    this.hasLoggedToday = false,
    this.isLoading = false,
  });

  MoodState copyWith({
    MoodType? current,
    List<MoodEntry>? history,
    bool? hasLoggedToday,
    bool? isLoading,
  }) =>
      MoodState(
        current: current ?? this.current,
        history: history ?? this.history,
        hasLoggedToday: hasLoggedToday ?? this.hasLoggedToday,
        isLoading: isLoading ?? this.isLoading,
      );
}

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(const MoodState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final current = await MoodStorage.loadCurrent();
    final history = await MoodStorage.loadHistory();
    final loggedToday = await MoodStorage.hasLoggedToday();
    state = MoodState(
      current: current,
      history: history,
      hasLoggedToday: loggedToday,
      isLoading: false,
    );
  }

  Future<void> setMood(MoodType mood) async {
    await MoodStorage.save(mood);
    final history = await MoodStorage.loadHistory();
    state = state.copyWith(
      current: mood,
      history: history,
      hasLoggedToday: true,
    );
  }

  void dismissCheckIn() {
    // Mark as logged so the banner hides without persisting a mood.
    state = state.copyWith(hasLoggedToday: true);
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>(
  (_) => MoodNotifier(),
);
