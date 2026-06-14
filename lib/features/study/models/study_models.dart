import 'package:flutter/material.dart';

// ── Difficulty constants ────────────────────────────────────────────────────────
const kDifficultyEasy = 'easy';
const kDifficultyMedium = 'medium';
const kDifficultyHard = 'hard';

// ── Status constants ────────────────────────────────────────────────────────────
const kAssignmentStatusPending = 'pending';
const kAssignmentStatusInProgress = 'in_progress';
const kAssignmentStatusSubmitted = 'submitted';

const kExamStatusUpcoming = 'upcoming';
const kExamStatusCompleted = 'completed';

// ── Session technique constants ────────────────────────────────────────────────
const kTechniquePomodoro = 'pomodoro';
const kTechniqueDeepWork = 'deep_work';
const kTechniqueReview = 'review';
const kTechniqueCram = 'cram';

// ── Target type constants ──────────────────────────────────────────────────────
const kTargetTypeAssignment = 'assignment';
const kTargetTypeExam = 'exam';

// ── Subject color palette (hex strings, no #) ──────────────────────────────────
const kSubjectColorPalette = [
  '6366F1', // indigo
  '3B82F6', // blue
  '22C55E', // green
  'F97316', // orange
  'E91E8C', // pink (brand)
  '06B6D4', // cyan
  'F59E0B', // amber
  'DC2626', // red
];

Color subjectColor(String colorHex) {
  try {
    return Color(int.parse('FF$colorHex', radix: 16));
  } catch (_) {
    return const Color(0xFF6366F1);
  }
}

String autoSubjectColor(String name) =>
    kSubjectColorPalette[name.hashCode.abs() % kSubjectColorPalette.length];

// ── Subject Map helpers ────────────────────────────────────────────────────────
String subjectId(Map m) => (m['id'] ?? '') as String;
String subjectName(Map m) => (m['name'] ?? '') as String;
String subjectColorHex(Map m) => (m['colorHex'] ?? '6366F1') as String;

// ── Assignment Map helpers ─────────────────────────────────────────────────────
String assignId(Map m) => (m['id'] ?? '') as String;
String assignTitle(Map m) => (m['title'] ?? '') as String;
String assignSubjectName(Map m) => (m['subjectName'] ?? 'General') as String;
String assignSubjectColor(Map m) => (m['subjectColorHex'] ?? '6366F1') as String;
String assignDueDate(Map m) => (m['dueDate'] ?? '') as String;
double assignEstimatedHours(Map m) => ((m['estimatedHours'] ?? 2) as num).toDouble();
String assignDifficulty(Map m) => (m['difficulty'] ?? kDifficultyMedium) as String;
String assignNotes(Map m) => (m['notes'] ?? '') as String;
bool assignIsCompleted(Map m) => m['isCompleted'] == true;

int assignDaysUntilDue(Map m) {
  final raw = assignDueDate(m);
  if (raw.isEmpty) return 999;
  try {
    return DateTime.parse(raw).difference(DateTime.now()).inDays;
  } catch (_) {
    return 999;
  }
}

Color assignUrgencyColor(Map m) {
  final days = assignDaysUntilDue(m);
  if (days < 0) return const Color(0xFFDC2626);
  if (days <= 1) return const Color(0xFFF97316);
  if (days <= 3) return const Color(0xFFF59E0B);
  return const Color(0xFF22C55E);
}

String assignDueLabel(Map m) {
  final days = assignDaysUntilDue(m);
  if (days < 0) return '${days.abs()}d overdue';
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due in ${days}d';
}

// ── Exam Map helpers ───────────────────────────────────────────────────────────
String examId(Map m) => (m['id'] ?? '') as String;
String examTitle(Map m) => (m['title'] ?? '') as String;
String examSubjectName(Map m) => (m['subjectName'] ?? 'General') as String;
String examSubjectColor(Map m) => (m['subjectColorHex'] ?? '6366F1') as String;
String examDate(Map m) => (m['date'] ?? '') as String;
String examLocation(Map m) => (m['location'] ?? '') as String;
double examPrepHours(Map m) => ((m['prepHours'] ?? 5) as num).toDouble();
String examDifficulty(Map m) => (m['difficulty'] ?? kDifficultyMedium) as String;
List<String> examTopics(Map m) =>
    List<String>.from((m['topics'] ?? const []) as List);
String examStatus(Map m) => (m['status'] ?? kExamStatusUpcoming) as String;

int examDaysUntil(Map m) {
  final raw = examDate(m);
  if (raw.isEmpty) return 999;
  try {
    return DateTime.parse(raw).difference(DateTime.now()).inDays;
  } catch (_) {
    return 999;
  }
}

Color examUrgencyColor(Map m) {
  final days = examDaysUntil(m);
  if (days < 0) return const Color(0xFF94A3B8);
  if (days <= 1) return const Color(0xFFDC2626);
  if (days <= 3) return const Color(0xFFF97316);
  if (days <= 7) return const Color(0xFFF59E0B);
  return const Color(0xFF22C55E);
}

String examCountdownLabel(Map m) {
  final days = examDaysUntil(m);
  if (days < 0) return 'Passed';
  if (days == 0) return 'Today!';
  if (days == 1) return 'Tomorrow';
  return 'In ${days}d';
}

// ── Session Map helpers ────────────────────────────────────────────────────────
String sessionId(Map m) => (m['id'] ?? '') as String;
String sessionTargetId(Map m) => (m['targetId'] ?? '') as String;
String sessionTargetType(Map m) => (m['targetType'] ?? kTargetTypeAssignment) as String;
String sessionTargetTitle(Map m) => (m['targetTitle'] ?? '') as String;
String sessionSubjectName(Map m) => (m['subjectName'] ?? '') as String;
String sessionSubjectColor(Map m) => (m['subjectColorHex'] ?? '6366F1') as String;
String sessionScheduledFor(Map m) => (m['scheduledFor'] ?? '') as String;
int sessionStartHour(Map m) => (m['startHour'] ?? 9) as int;
int sessionStartMin(Map m) => (m['startMin'] ?? 0) as int;
int sessionDurationMins(Map m) => (m['durationMins'] ?? 60) as int;
String sessionTechnique(Map m) => (m['technique'] ?? kTechniquePomodoro) as String;
bool sessionIsCompleted(Map m) => m['isCompleted'] == true;

String sessionTimeRange(Map m) {
  final h = sessionStartHour(m);
  final min = sessionStartMin(m);
  final endTotal = h * 60 + min + sessionDurationMins(m);
  String fmt(int totalMins) {
    final hh = totalMins ~/ 60;
    final mm = totalMins % 60;
    final suffix = hh >= 12 ? 'PM' : 'AM';
    final h12 = hh % 12 == 0 ? 12 : hh % 12;
    return mm == 0 ? '$h12 $suffix' : '$h12:${mm.toString().padLeft(2, '0')} $suffix';
  }

  return '${fmt(h * 60 + min)} – ${fmt(endTotal)}';
}

String sessionTechniqueLabel(Map m) => switch (sessionTechnique(m)) {
      kTechniquePomodoro => '25/5 Pomodoro',
      kTechniqueDeepWork => 'Deep Work',
      kTechniqueReview => 'Review',
      kTechniqueCram => 'Cram Session',
      _ => 'Study Block',
    };

String sessionTechniqueEmoji(Map m) => switch (sessionTechnique(m)) {
      kTechniquePomodoro => '🍅',
      kTechniqueDeepWork => '🎯',
      kTechniqueReview => '📖',
      kTechniqueCram => '⚡',
      _ => '📚',
    };

// ── Difficulty helpers ─────────────────────────────────────────────────────────
Color difficultyColor(String d) => switch (d) {
      kDifficultyEasy => const Color(0xFF22C55E),
      kDifficultyHard => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };

String difficultyLabel(String d) => switch (d) {
      kDifficultyEasy => 'Easy',
      kDifficultyHard => 'Hard',
      _ => 'Medium',
    };

// ── Study plan Map helpers ─────────────────────────────────────────────────────
int planReadinessScore(Map m) => (m['readinessScore'] ?? 0) as int;
double planTotalStudyHours(Map m) =>
    ((m['totalStudyHours'] ?? 0) as num).toDouble();

List<Map<String, dynamic>> planSessions(Map m) =>
    List<Map<String, dynamic>>.from(
        ((m['sessions'] ?? const []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));

List<Map<String, dynamic>> planUpcomingExams(Map m) =>
    List<Map<String, dynamic>>.from(
        ((m['upcomingExams'] ?? const []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));

List<Map<String, dynamic>> planUrgentAssignments(Map m) =>
    List<Map<String, dynamic>>.from(
        ((m['urgentAssignments'] ?? const []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)));

Color readinessColor(int score) {
  if (score >= 75) return const Color(0xFF22C55E);
  if (score >= 50) return const Color(0xFFF59E0B);
  if (score >= 25) return const Color(0xFFF97316);
  return const Color(0xFFDC2626);
}

String readinessLabel(int score) {
  if (score >= 75) return 'On Track';
  if (score >= 50) return 'Getting There';
  if (score >= 25) return 'Behind';
  return 'At Risk';
}
