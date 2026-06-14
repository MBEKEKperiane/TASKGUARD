enum FocusStatus { idle, starting, active, paused, ending, completed }

class FocusSessionState {
  final FocusStatus status;

  /// Planned duration set at session start — never changes.
  final int totalSeconds;

  /// Counts down from totalSeconds to 0.
  final int remainingSeconds;

  /// Cumulative seconds the timer was paused (not counted as focus time).
  final int pausedSeconds;

  final String? sessionId;
  final String? taskTitle;
  final DateTime? startedAt;

  /// Set when a pause begins; cleared on resume.
  final DateTime? pausedAt;

  /// Populated once the session ends and stats are persisted.
  final Map<String, dynamic>? completedSession;

  const FocusSessionState({
    required this.status,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.pausedSeconds = 0,
    this.sessionId,
    this.taskTitle,
    this.startedAt,
    this.pausedAt,
    this.completedSession,
  });

  // ── Computed ─────────────────────────────────────────────────────────────

  int get elapsedSeconds => totalSeconds - remainingSeconds;

  /// Actual focus seconds = elapsed − cumulative paused time (including any
  /// ongoing pause that has not yet been committed to [pausedSeconds]).
  int get actualFocusSeconds {
    int paused = pausedSeconds;
    if (pausedAt != null) {
      paused += DateTime.now().difference(pausedAt!).inSeconds;
    }
    return (elapsedSeconds - paused).clamp(0, totalSeconds);
  }

  /// At least 1 min if the user actually started; 0 if they ended immediately.
  int get actualFocusMins =>
      elapsedSeconds > 0 ? (actualFocusSeconds / 60).ceil().clamp(1, totalSeconds ~/ 60) : 0;

  /// 0.0 → 1.0 ring fill (elapsed / total).
  double get progress =>
      totalSeconds > 0 ? (elapsedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

  String get timeLabel {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Copy ─────────────────────────────────────────────────────────────────

  FocusSessionState copyWith({
    FocusStatus? status,
    int? remainingSeconds,
    int? pausedSeconds,
    String? sessionId,
    String? taskTitle,
    DateTime? startedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Map<String, dynamic>? completedSession,
  }) {
    return FocusSessionState(
      status: status ?? this.status,
      totalSeconds: totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      sessionId: sessionId ?? this.sessionId,
      taskTitle: taskTitle ?? this.taskTitle,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      completedSession: completedSession ?? this.completedSession,
    );
  }
}
