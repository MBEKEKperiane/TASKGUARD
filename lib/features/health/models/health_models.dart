import 'package:flutter/material.dart';

// ── Health mood ────────────────────────────────────────────────────────────────

enum HealthMood { great, good, okay, low, burned }

extension HealthMoodX on HealthMood {
  String get label => switch (this) {
        HealthMood.great => 'Great',
        HealthMood.good => 'Good',
        HealthMood.okay => 'Okay',
        HealthMood.low => 'Low',
        HealthMood.burned => 'Burned out',
      };

  String get emoji => switch (this) {
        HealthMood.great => '😄',
        HealthMood.good => '🙂',
        HealthMood.okay => '😐',
        HealthMood.low => '😔',
        HealthMood.burned => '😩',
      };

  Color get color => switch (this) {
        HealthMood.great => const Color(0xFF22C55E),
        HealthMood.good => const Color(0xFF3B82F6),
        HealthMood.okay => const Color(0xFFF59E0B),
        HealthMood.low => const Color(0xFFF97316),
        HealthMood.burned => const Color(0xFFEF4444),
      };

  // Score contribution 0–4 for composite calculation.
  int get score => switch (this) {
        HealthMood.great => 4,
        HealthMood.good => 3,
        HealthMood.okay => 2,
        HealthMood.low => 1,
        HealthMood.burned => 0,
      };

  String get key => name;

  static HealthMood fromKey(String key) =>
      HealthMood.values.firstWhere((m) => m.key == key,
          orElse: () => HealthMood.okay);
}

// ── Energy level helpers ───────────────────────────────────────────────────────
// Energy is stored as int 1–5.

String energyEmoji(int level) => switch (level) {
      1 => '😫',
      2 => '😔',
      3 => '😐',
      4 => '🙂',
      _ => '⚡',
    };

String energyLabel(int level) => switch (level) {
      1 => 'Exhausted',
      2 => 'Low',
      3 => 'Moderate',
      4 => 'Good',
      _ => 'Energized',
    };

Color energyColor(int level) => switch (level) {
      1 => const Color(0xFFEF4444),
      2 => const Color(0xFFF97316),
      3 => const Color(0xFFF59E0B),
      4 => const Color(0xFF22C55E),
      _ => const Color(0xFF0D9488),
    };

// Score contribution 0–4 for composite calculation.
int energyScore(int level) => (level - 1).clamp(0, 4);

// ── Sleep score ────────────────────────────────────────────────────────────────

int sleepScore(double hours) {
  if (hours >= 7.5) return 3;
  if (hours >= 6.0) return 2;
  if (hours >= 4.0) return 1;
  return 0;
}

String sleepLabel(double hours) {
  if (hours >= 8) return 'Well rested';
  if (hours >= 7) return 'Good sleep';
  if (hours >= 6) return 'Light sleep';
  if (hours >= 5) return 'Short sleep';
  return 'Insufficient sleep';
}

Color sleepColor(double hours) {
  if (hours >= 7.5) return const Color(0xFF22C55E);
  if (hours >= 6.0) return const Color(0xFF3B82F6);
  if (hours >= 5.0) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

// ── Workload level ─────────────────────────────────────────────────────────────

enum WorkloadLevel { rest, light, moderate, full, stretch }

extension WorkloadLevelX on WorkloadLevel {
  String get label => switch (this) {
        WorkloadLevel.rest => 'Rest Day',
        WorkloadLevel.light => 'Light Load',
        WorkloadLevel.moderate => 'Moderate',
        WorkloadLevel.full => 'Full Capacity',
        WorkloadLevel.stretch => 'Stretch Mode',
      };

  String get subtitle => switch (this) {
        WorkloadLevel.rest =>
          'Focus on recovery — only critical tasks today.',
        WorkloadLevel.light =>
          'Take it easy — high-priority tasks only.',
        WorkloadLevel.moderate =>
          'Steady work — a balanced day ahead.',
        WorkloadLevel.full =>
          'You\'re in good shape — tackle your full list.',
        WorkloadLevel.stretch =>
          'Peak energy — push beyond your usual limits!',
      };

  Color get color => switch (this) {
        WorkloadLevel.rest => const Color(0xFFEF4444),
        WorkloadLevel.light => const Color(0xFFF97316),
        WorkloadLevel.moderate => const Color(0xFFF59E0B),
        WorkloadLevel.full => const Color(0xFF22C55E),
        WorkloadLevel.stretch => const Color(0xFF0D9488),
      };

  String get emoji => switch (this) {
        WorkloadLevel.rest => '🛌',
        WorkloadLevel.light => '🐢',
        WorkloadLevel.moderate => '⚖️',
        WorkloadLevel.full => '💪',
        WorkloadLevel.stretch => '🚀',
      };

  // Max tasks to surface; null = no cap.
  int? get taskCap => switch (this) {
        WorkloadLevel.rest => 1,
        WorkloadLevel.light => 3,
        WorkloadLevel.moderate => null,
        WorkloadLevel.full => null,
        WorkloadLevel.stretch => null,
      };

  // Priorities to show; null = no filter.
  List<String>? get allowedPriorities => switch (this) {
        WorkloadLevel.rest => ['URGENT'],
        WorkloadLevel.light => ['URGENT', 'HIGH'],
        _ => null,
      };

  List<String> get tips => switch (this) {
        WorkloadLevel.rest => [
            'Drink plenty of water and step outside briefly.',
            'Avoid screens for 30 min before bed tonight.',
            'Take a 10-min nap if possible mid-afternoon.',
            'Only handle what\'s truly urgent — everything else can wait.',
          ],
        WorkloadLevel.light => [
            'Work in short 25-min bursts with 10-min breaks.',
            'Tackle the single most important task first.',
            'Skip optional meetings — protect your limited energy.',
            'Have a nourishing meal before deep work.',
          ],
        WorkloadLevel.moderate => [
            'Keep Pomodoro sessions at 45 min to stay fresh.',
            'Batch similar tasks to reduce context switching.',
            'Take a proper lunch break away from your desk.',
            'Aim for 7–8 hours sleep tonight to recharge.',
          ],
        WorkloadLevel.full => [
            'Great day to tackle complex or creative tasks.',
            'Set stretch goals for your top-priority work.',
            'Block 90-min deep-work windows early in the day.',
            'Maintain momentum — avoid social media spirals.',
          ],
        WorkloadLevel.stretch => [
            'Your peak — use it on the hardest problem on your list.',
            'Document insights while they\'re sharp.',
            'Pair this energy with exercise to lock it in.',
            'Wind down intentionally tonight to sustain the streak.',
          ],
      };

  String get storageKey => name;

  static WorkloadLevel fromKey(String key) =>
      WorkloadLevel.values.firstWhere((w) => w.storageKey == key,
          orElse: () => WorkloadLevel.moderate);
}

// ── Health entry (one per day) ─────────────────────────────────────────────────

class HealthEntry {
  final String date; // "yyyy-MM-dd"
  final double sleepHours;
  final int energyLevel; // 1–5
  final HealthMood mood;

  const HealthEntry({
    required this.date,
    required this.sleepHours,
    required this.energyLevel,
    required this.mood,
  });

  factory HealthEntry.fromMap(Map<String, dynamic> m) => HealthEntry(
        date: m['date'] as String,
        sleepHours: (m['sleepHours'] as num).toDouble(),
        energyLevel: (m['energyLevel'] as num).toInt(),
        mood: HealthMoodX.fromKey(m['mood'] as String),
      );

  Map<String, dynamic> toMap() => {
        'date': date,
        'sleepHours': sleepHours,
        'energyLevel': energyLevel,
        'mood': mood.key,
      };

  HealthEntry copyWith({
    String? date,
    double? sleepHours,
    int? energyLevel,
    HealthMood? mood,
  }) =>
      HealthEntry(
        date: date ?? this.date,
        sleepHours: sleepHours ?? this.sleepHours,
        energyLevel: energyLevel ?? this.energyLevel,
        mood: mood ?? this.mood,
      );
}

// ── Health insight (computed, not stored) ──────────────────────────────────────

class HealthInsight {
  final WorkloadLevel workload;
  final List<String> tips;

  const HealthInsight({required this.workload, required this.tips});
}
