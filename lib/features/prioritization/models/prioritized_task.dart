class PrioritizedTask {
  final Map<String, dynamic> task;
  final int rank;
  final double totalScore;
  final double urgencyScore;
  final double importanceScore;
  final double deadlineScore;
  final double patternScore;
  final String recommendation;
  final List<String> reasons; // top factor labels shown as chips

  const PrioritizedTask({
    required this.task,
    required this.rank,
    required this.totalScore,
    required this.urgencyScore,
    required this.importanceScore,
    required this.deadlineScore,
    required this.patternScore,
    required this.recommendation,
    required this.reasons,
  });

  PrioritizedTask copyWith({int? rank}) => PrioritizedTask(
        task: task,
        rank: rank ?? this.rank,
        totalScore: totalScore,
        urgencyScore: urgencyScore,
        importanceScore: importanceScore,
        deadlineScore: deadlineScore,
        patternScore: patternScore,
        recommendation: recommendation,
        reasons: reasons,
      );

  String get title => task['title'] as String? ?? 'Untitled';
  String get priority => (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
  bool get isOverdue {
    final raw = (task['dueDate'] ?? task['startTime']) as String?;
    if (raw == null) return false;
    try {
      return DateTime.parse(raw).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}

class PrioritizationState {
  final List<PrioritizedTask> rankedTasks;
  final bool isLoading;
  final DateTime? lastRefreshed;

  const PrioritizationState({
    this.rankedTasks = const [],
    this.isLoading = false,
    this.lastRefreshed,
  });

  PrioritizationState copyWith({
    List<PrioritizedTask>? rankedTasks,
    bool? isLoading,
    DateTime? lastRefreshed,
  }) =>
      PrioritizationState(
        rankedTasks: rankedTasks ?? this.rankedTasks,
        isLoading: isLoading ?? this.isLoading,
        lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      );
}
