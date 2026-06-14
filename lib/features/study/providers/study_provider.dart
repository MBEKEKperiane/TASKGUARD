import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/local_storage.dart';
import '../../../services/study_engine.dart';
import '../models/study_models.dart';

class StudyState {
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> exams;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic>? studyPlan;
  final bool isLoading;

  const StudyState({
    this.assignments = const [],
    this.exams = const [],
    this.subjects = const [],
    this.studyPlan,
    this.isLoading = false,
  });

  StudyState copyWith({
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? exams,
    List<Map<String, dynamic>>? subjects,
    Map<String, dynamic>? studyPlan,
    bool? isLoading,
    bool clearPlan = false,
  }) =>
      StudyState(
        assignments: assignments ?? this.assignments,
        exams: exams ?? this.exams,
        subjects: subjects ?? this.subjects,
        studyPlan: clearPlan ? null : (studyPlan ?? this.studyPlan),
        isLoading: isLoading ?? this.isLoading,
      );

  int get urgentCount {
    final urgentAssign = assignments
        .where((a) => !assignIsCompleted(a) && assignDaysUntilDue(a) <= 2)
        .length;
    final criticalExams = exams
        .where((e) => examDaysUntil(e) >= 0 && examDaysUntil(e) <= 3)
        .length;
    return urgentAssign + criticalExams;
  }

  List<Map<String, dynamic>> get pendingAssignments =>
      assignments.where((a) => !assignIsCompleted(a)).toList()
        ..sort((a, b) => assignDaysUntilDue(a).compareTo(assignDaysUntilDue(b)));

  List<Map<String, dynamic>> get upcomingExams =>
      exams.where((e) => examDaysUntil(e) >= 0).toList()
        ..sort((a, b) => examDaysUntil(a).compareTo(examDaysUntil(b)));

  List<Map<String, dynamic>> get todaySessions {
    if (studyPlan == null) return [];
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return planSessions(studyPlan!)
        .where((s) => sessionScheduledFor(s) == todayKey)
        .toList();
  }
}

class StudyNotifier extends StateNotifier<StudyState> {
  StudyNotifier() : super(const StudyState()) {
    _load();
  }

  void _load() {
    state = state.copyWith(
      assignments: LocalStorage.getAssignments(),
      exams: LocalStorage.getExams(),
      subjects: LocalStorage.getSubjects(),
      studyPlan: LocalStorage.getStudyPlan(),
    );
  }

  // ── Subjects ─────────────────────────────────────────────────────────────────

  Future<void> addSubject(Map<String, dynamic> data) async {
    final updated = [...state.subjects, data];
    await LocalStorage.saveSubjects(updated);
    if (mounted) state = state.copyWith(subjects: updated);
  }

  // ── Assignments ───────────────────────────────────────────────────────────────

  Future<void> addAssignment(Map<String, dynamic> data) async {
    final updated = [data, ...state.assignments];
    await LocalStorage.saveAssignments(updated);
    if (mounted) state = state.copyWith(assignments: updated, clearPlan: true);
  }

  Future<void> toggleAssignment(String id) async {
    final updated = state.assignments.map((a) {
      if (assignId(a) != id) return a;
      return {...a, 'isCompleted': !(a['isCompleted'] == true)};
    }).toList();
    await LocalStorage.saveAssignments(updated);
    if (mounted) state = state.copyWith(assignments: updated, clearPlan: true);
  }

  Future<void> deleteAssignment(String id) async {
    final updated =
        state.assignments.where((a) => assignId(a) != id).toList();
    await LocalStorage.saveAssignments(updated);
    if (mounted) state = state.copyWith(assignments: updated, clearPlan: true);
  }

  // ── Exams ─────────────────────────────────────────────────────────────────────

  Future<void> addExam(Map<String, dynamic> data) async {
    final updated = [data, ...state.exams];
    await LocalStorage.saveExams(updated);
    if (mounted) state = state.copyWith(exams: updated, clearPlan: true);
  }

  Future<void> deleteExam(String id) async {
    final updated = state.exams.where((e) => examId(e) != id).toList();
    await LocalStorage.saveExams(updated);
    if (mounted) state = state.copyWith(exams: updated, clearPlan: true);
  }

  // ── Study Plan ────────────────────────────────────────────────────────────────

  Future<void> generatePlan() async {
    if (mounted) state = state.copyWith(isLoading: true);
    final plan = await Future.microtask(StudyEngine.generatePlan);
    await LocalStorage.saveStudyPlan(plan);
    if (mounted) state = state.copyWith(studyPlan: plan, isLoading: false);
  }

  Future<void> completeSession(String id) async {
    if (state.studyPlan == null) return;
    final sessions = planSessions(state.studyPlan!).map((s) {
      if (s['id'] != id) return s;
      return {...s, 'isCompleted': true};
    }).toList();
    final updated = {...state.studyPlan!, 'sessions': sessions};
    await LocalStorage.saveStudyPlan(updated);
    if (mounted) state = state.copyWith(studyPlan: updated);
  }
}

final studyProvider = StateNotifierProvider<StudyNotifier, StudyState>(
  (_) => StudyNotifier(),
);
