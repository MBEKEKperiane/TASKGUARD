import 'dart:math';
import '../features/study/models/study_models.dart';
import 'local_storage.dart';

class StudyEngine {
  StudyEngine._();

  static const int _maxSessionsPerDay = 3;
  static const int _startHour = 8;
  static const int _endHour = 22;
  static const int _bufferMins = 15;
  static const List<int> _preferredStartMins = [540, 840, 1140]; // 9am, 2pm, 7pm

  static Map<String, dynamic> generatePlan() {
    final now = DateTime.now();
    final assignments = LocalStorage.getAssignments()
        .where((a) => !assignIsCompleted(a))
        .toList()
      ..sort((a, b) => assignDaysUntilDue(a).compareTo(assignDaysUntilDue(b)));

    final exams = LocalStorage.getExams()
        .where((e) =>
            examStatus(e) == kExamStatusUpcoming && examDaysUntil(e) >= 0)
        .toList()
      ..sort((a, b) => examDaysUntil(a).compareTo(examDaysUntil(b)));

    // Build busy intervals from existing tasks that have a startTime
    final busyByDay = <String, List<_Interval>>{};
    for (final t in LocalStorage.getAllTasks()) {
      final rawStart = t['startTime'] as String?;
      if (rawStart == null) continue;
      try {
        final start = DateTime.parse(rawStart);
        final durationMins =
            ((t['estimatedDuration'] ?? 60) as num).toInt();
        final key = _dayKey(start);
        (busyByDay[key] ??= []).add(_Interval(
          start: start.hour * 60 + start.minute,
          end: start.hour * 60 + start.minute + durationMins,
        ));
      } catch (_) {}
    }

    final sessionsPerDay = <String, int>{};
    final usedByDay = <String, List<_Interval>>{};
    final sessions = <Map<String, dynamic>>[];
    int counter = 0;

    // Exams first (higher priority)
    for (final exam in exams) {
      final daysUntil = examDaysUntil(exam);
      final technique = _selectTechnique(daysUntil, examDifficulty(exam));
      final sessLen = _sessionDurationMins(technique);
      var minsLeft = (examPrepHours(exam) * 60).round();
      final lastDay = max(0, daysUntil - 1); // don't schedule on exam day

      for (int d = 0; d <= lastDay && minsLeft > 0; d++) {
        final day = now.add(Duration(days: d));
        final key = _dayKey(day);
        if ((sessionsPerDay[key] ?? 0) >= _maxSessionsPerDay) continue;

        final chunk = min(sessLen, minsLeft);
        final slot = _findSlot(key, chunk, busyByDay, usedByDay);
        if (slot == null) continue;

        sessions.add(_buildSession(
          id: 'sess_${counter++}',
          targetId: examId(exam),
          targetType: kTargetTypeExam,
          targetTitle: examTitle(exam),
          subjectName: examSubjectName(exam),
          subjectColorHex: examSubjectColor(exam),
          dayKey: key,
          startMins: slot.start,
          durationMins: chunk,
          technique: technique,
        ));
        minsLeft -= chunk;
        sessionsPerDay[key] = (sessionsPerDay[key] ?? 0) + 1;
        (usedByDay[key] ??= [])
            .add(_Interval(start: slot.start, end: slot.start + chunk + _bufferMins));
      }
    }

    // Assignments
    for (final assign in assignments) {
      final daysUntil = assignDaysUntilDue(assign);
      final technique = _selectTechnique(daysUntil, assignDifficulty(assign));
      final sessLen = _sessionDurationMins(technique);
      var minsLeft = (assignEstimatedHours(assign) * 60).round();
      final lastDay = max(0, daysUntil);

      for (int d = 0; d <= lastDay && minsLeft > 0; d++) {
        final day = now.add(Duration(days: d));
        final key = _dayKey(day);
        if ((sessionsPerDay[key] ?? 0) >= _maxSessionsPerDay) continue;

        final chunk = min(sessLen, minsLeft);
        final slot = _findSlot(key, chunk, busyByDay, usedByDay);
        if (slot == null) continue;

        sessions.add(_buildSession(
          id: 'sess_${counter++}',
          targetId: assignId(assign),
          targetType: kTargetTypeAssignment,
          targetTitle: assignTitle(assign),
          subjectName: assignSubjectName(assign),
          subjectColorHex: assignSubjectColor(assign),
          dayKey: key,
          startMins: slot.start,
          durationMins: chunk,
          technique: technique,
        ));
        minsLeft -= chunk;
        sessionsPerDay[key] = (sessionsPerDay[key] ?? 0) + 1;
        (usedByDay[key] ??= [])
            .add(_Interval(start: slot.start, end: slot.start + chunk + _bufferMins));
      }
    }

    sessions.sort((a, b) {
      final dc = sessionScheduledFor(a).compareTo(sessionScheduledFor(b));
      if (dc != 0) return dc;
      return (sessionStartHour(a) * 60 + sessionStartMin(a))
          .compareTo(sessionStartHour(b) * 60 + sessionStartMin(b));
    });

    final totalMins =
        sessions.fold(0, (sum, s) => sum + sessionDurationMins(s));

    return {
      'generatedAt': now.toIso8601String(),
      'readinessScore': _readinessScore(assignments, exams, sessions),
      'totalStudyHours': totalMins / 60.0,
      'sessions': sessions,
      'upcomingExams': exams.take(3).map((e) => {
            'examId': examId(e),
            'title': examTitle(e),
            'daysUntil': examDaysUntil(e),
            'subjectName': examSubjectName(e),
            'subjectColorHex': examSubjectColor(e),
          }).toList(),
      'urgentAssignments': assignments
          .where((a) => assignDaysUntilDue(a) <= 3)
          .take(5)
          .map((a) => {
                'id': assignId(a),
                'title': assignTitle(a),
                'dueIn': assignDueLabel(a),
                'estimatedHours': assignEstimatedHours(a),
              })
          .toList(),
    };
  }

  static _Interval? _findSlot(
    String dayKey,
    int durationMins,
    Map<String, List<_Interval>> busyByDay,
    Map<String, List<_Interval>> usedByDay,
  ) {
    final busy = <_Interval>[
      ...(busyByDay[dayKey] ?? const <_Interval>[]),
      ...(usedByDay[dayKey] ?? const <_Interval>[]),
    ];

    for (final preferred in _preferredStartMins) {
      final end = preferred + durationMins;
      if (end > _endHour * 60) continue;
      if (!_hasOverlap(preferred, end, busy)) {
        return _Interval(start: preferred, end: end);
      }
    }

    // Linear scan in 30-min steps
    for (int s = _startHour * 60; s + durationMins <= _endHour * 60; s += 30) {
      if (!_hasOverlap(s, s + durationMins, busy)) {
        return _Interval(start: s, end: s + durationMins);
      }
    }
    return null;
  }

  static bool _hasOverlap(int start, int end, List<_Interval> busy) {
    for (final b in busy) {
      if (start < b.end && end > b.start) return true;
    }
    return false;
  }

  static Map<String, dynamic> _buildSession({
    required String id,
    required String targetId,
    required String targetType,
    required String targetTitle,
    required String subjectName,
    required String subjectColorHex,
    required String dayKey,
    required int startMins,
    required int durationMins,
    required String technique,
  }) =>
      {
        'id': id,
        'targetId': targetId,
        'targetType': targetType,
        'targetTitle': targetTitle,
        'subjectName': subjectName,
        'subjectColorHex': subjectColorHex,
        'scheduledFor': dayKey,
        'startHour': startMins ~/ 60,
        'startMin': startMins % 60,
        'durationMins': durationMins,
        'technique': technique,
        'isCompleted': false,
      };

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _selectTechnique(int daysUntil, String difficulty) {
    if (daysUntil <= 0) return kTechniqueReview;
    if (daysUntil == 1) return kTechniqueCram;
    if (daysUntil <= 3) {
      return difficulty == kDifficultyHard
          ? kTechniqueDeepWork
          : kTechniqueReview;
    }
    return kTechniquePomodoro;
  }

  static int _sessionDurationMins(String technique) => switch (technique) {
        kTechniqueDeepWork => 90,
        kTechniqueCram => 45,
        kTechniqueReview => 60,
        _ => 75, // pomodoro
      };

  static int _readinessScore(
    List<Map> assignments,
    List<Map> exams,
    List<Map> sessions,
  ) {
    if (assignments.isEmpty && exams.isEmpty) return 100;
    int score = 100;
    score -= assignments.where((a) => assignDaysUntilDue(a) < 0).length * 15;
    score -= assignments
        .where((a) => assignDaysUntilDue(a) <= 1)
        .where((a) => !sessions.any((s) => sessionTargetId(s) == assignId(a)))
        .length *
        10;
    score -= exams.where((e) => examDaysUntil(e) <= 3).length * 5;
    return score.clamp(10, 100);
  }
}

class _Interval {
  final int start;
  final int end;
  const _Interval({required this.start, required this.end});
}
