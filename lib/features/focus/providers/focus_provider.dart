import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/focus_service.dart';
import '../../../services/local_storage.dart';
import '../../insights/providers/insights_provider.dart';
import '../models/focus_session_state.dart';

class FocusNotifier extends StateNotifier<FocusSessionState> {
  final FocusService _service;
  final Ref _ref;
  Timer? _timer;

  FocusNotifier(this._service, this._ref)
      : super(const FocusSessionState(
          status: FocusStatus.idle,
          totalSeconds: 1500,   // placeholder; overwritten by initialize()
          remainingSeconds: 1500,
        ));

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Called once from the screen's initState. Registers the session with the
  /// backend and transitions to [FocusStatus.idle] once ready (or on failure).
  Future<void> initialize(int plannedMins, String? taskTitle) async {
    final secs = plannedMins * 60;
    state = FocusSessionState(
      status: FocusStatus.starting,
      totalSeconds: secs,
      remainingSeconds: secs,
      taskTitle: taskTitle,
    );

    try {
      final session = await _service.startSession(
        plannedMins: plannedMins,
        taskTitle: taskTitle,
      );
      if (!mounted) return;
      state = state.copyWith(
        status: FocusStatus.idle,
        sessionId: session['id'] as String?,
      );
    } catch (_) {
      // Offline — allow the session to run locally without a server ID.
      if (!mounted) return;
      state = state.copyWith(status: FocusStatus.idle);
    }
  }

  /// Starts the countdown. Only valid from [FocusStatus.idle].
  void start() {
    if (state.status != FocusStatus.idle) return;
    state = state.copyWith(
      status: FocusStatus.active,
      startedAt: DateTime.now(),
    );
    _tick();
  }

  /// Freezes the countdown and records when the pause began.
  void pause() {
    if (state.status != FocusStatus.active) return;
    _timer?.cancel();
    state = state.copyWith(
      status: FocusStatus.paused,
      pausedAt: DateTime.now(),
    );
  }

  /// Resumes the countdown, committing the elapsed pause duration.
  void resume() {
    if (state.status != FocusStatus.paused) return;
    final additionalPause = state.pausedAt != null
        ? DateTime.now().difference(state.pausedAt!).inSeconds
        : 0;
    state = state.copyWith(
      status: FocusStatus.active,
      pausedSeconds: state.pausedSeconds + additionalPause,
      clearPausedAt: true,
    );
    _tick();
  }

  /// Ends the session, saves stats locally, and updates the productivity score.
  Future<void> end() async {
    _timer?.cancel();

    // Commit any ongoing pause before computing actual focus time.
    if (state.status == FocusStatus.paused && state.pausedAt != null) {
      final extra = DateTime.now().difference(state.pausedAt!).inSeconds;
      state = state.copyWith(
        pausedSeconds: state.pausedSeconds + extra,
        clearPausedAt: true,
      );
    }

    final actualMins = state.actualFocusMins;
    state = state.copyWith(status: FocusStatus.ending);

    // ── End session on backend ────────────────────────────────────────────
    Map<String, dynamic>? apiResult;
    if (state.sessionId != null) {
      try {
        apiResult = await _service.endSession(
          state.sessionId!,
          actualMins: actualMins,
        );
      } catch (_) {}
    }
    if (!mounted) return;

    // ── Build and persist the local session record ────────────────────────
    final focusScore = _resolveFocusScore(
      apiResult, actualMins, state.totalSeconds ~/ 60,
    );
    final record = <String, dynamic>{
      'id': state.sessionId ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      'plannedMins': state.totalSeconds ~/ 60,
      'actualMins': actualMins,
      'focusScore': focusScore,
      'taskTitle': state.taskTitle,
      'startedAt': state.startedAt?.toIso8601String(),
      'completedAt': DateTime.now().toIso8601String(),
    };

    await LocalStorage.addFocusSession(record);

    // Refresh insights so the screen reflects the new session immediately.
    _ref.read(insightsProvider.notifier).load();

    // ── Update productivity score when the API provides a fresh value ─────
    final newScore = _resolveProductivityScore(apiResult);
    if (newScore != null) {
      final existing = LocalStorage.getProductivityScore() ?? {};
      await LocalStorage.saveProductivityScore({
        ...existing,
        'score': newScore,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;
    state = state.copyWith(
      status: FocusStatus.completed,
      completedSession: record,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        end(); // natural completion
      }
    });
  }

  /// Prefer the server's focus score; fall back to a completion-ratio score.
  int _resolveFocusScore(
    Map<String, dynamic>? result,
    int actualMins,
    int plannedMins,
  ) {
    final v = result?['session']?['focusScore'] ?? result?['focusScore'];
    if (v is num) return v.toInt().clamp(0, 100);
    if (plannedMins == 0) return 0;
    return ((actualMins / plannedMins) * 100).round().clamp(0, 100);
  }

  /// Returns the updated productivity score from the API, or null if absent.
  int? _resolveProductivityScore(Map<String, dynamic>? result) {
    final v = result?['productivityScore'] ?? result?['score'];
    return v is num ? v.toInt().clamp(0, 100) : null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final focusServiceProvider = Provider<FocusService>((_) => FocusService());

/// autoDispose ensures the timer and session state are cleaned up when
/// FocusTimerScreen is popped from the navigator stack.
final focusProvider =
    StateNotifierProvider.autoDispose<FocusNotifier, FocusSessionState>(
  (ref) => FocusNotifier(ref.read(focusServiceProvider), ref),
);
