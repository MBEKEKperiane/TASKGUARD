import 'package:flutter/material.dart';

enum MoodType { happy, motivated, tired, stressed }

extension MoodTypeX on MoodType {
  String get label => switch (this) {
        MoodType.happy => 'Happy',
        MoodType.motivated => 'Motivated',
        MoodType.tired => 'Tired',
        MoodType.stressed => 'Stressed',
      };

  String get emoji => switch (this) {
        MoodType.happy => '😊',
        MoodType.motivated => '🔥',
        MoodType.tired => '😴',
        MoodType.stressed => '😤',
      };

  String get description => switch (this) {
        MoodType.happy => 'Feeling good and content',
        MoodType.motivated => 'Ready to tackle anything',
        MoodType.tired => 'Low energy, need rest',
        MoodType.stressed => 'Feeling overwhelmed',
      };

  Color get color => switch (this) {
        MoodType.happy => const Color(0xFF22C55E),
        MoodType.motivated => const Color(0xFFE91E8C),
        MoodType.tired => const Color(0xFF64748B),
        MoodType.stressed => const Color(0xFFF97316),
      };

  Color get bgColor => switch (this) {
        MoodType.happy => const Color(0xFFDCFCE7),
        MoodType.motivated => const Color(0xFFFCE4EC),
        MoodType.tired => const Color(0xFFF1F5F9),
        MoodType.stressed => const Color(0xFFFFF7ED),
      };

  Color get darkBgColor => switch (this) {
        MoodType.happy => const Color(0xFF14532D),
        MoodType.motivated => const Color(0xFF4A0E2B),
        MoodType.tired => const Color(0xFF1E293B),
        MoodType.stressed => const Color(0xFF431407),
      };

  /// Duration cap for focus sessions in minutes. null = no cap.
  int? get sessionCap => switch (this) {
        MoodType.happy => null,
        MoodType.motivated => null,
        MoodType.tired => 20,
        MoodType.stressed => 25,
      };

  /// Duration multiplier applied to computed session length.
  double get durationMultiplier => switch (this) {
        MoodType.happy => 1.0,
        MoodType.motivated => 1.2,
        MoodType.tired => 0.75,
        MoodType.stressed => 0.85,
      };

  /// Burnout risk contribution (0–100).
  int get burnoutScore => switch (this) {
        MoodType.happy => 10,
        MoodType.motivated => 5,
        MoodType.tired => 75,
        MoodType.stressed => 90,
      };

  /// Priority pattern modifier: added to pattern score for task ranking.
  /// Stressed/tired boost LOW tasks (easy wins); motivated boosts HIGH/URGENT.
  double patternModifier(String taskPriority) {
    final p = taskPriority.toUpperCase();
    return switch (this) {
      MoodType.motivated => (p == 'URGENT' || p == 'HIGH') ? 15 : 0,
      MoodType.happy => 5,
      MoodType.tired => (p == 'LOW') ? 12 : (p == 'URGENT' ? 0 : -8),
      MoodType.stressed => (p == 'LOW') ? 18 : (p == 'URGENT' ? 0 : -10),
    };
  }

  /// Storage string — stable across renames.
  String get storageKey => name; // 'happy' | 'motivated' | 'tired' | 'stressed'

  static MoodType fromStorage(String key) =>
      MoodType.values.firstWhere(
        (m) => m.storageKey == key,
        orElse: () => MoodType.happy,
      );
}

class MoodEntry {
  final MoodType mood;
  final DateTime timestamp;

  const MoodEntry({required this.mood, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'mood': mood.storageKey,
        'ts': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        mood: MoodTypeX.fromStorage(json['mood'] as String),
        timestamp: DateTime.parse(json['ts'] as String),
      );
}
