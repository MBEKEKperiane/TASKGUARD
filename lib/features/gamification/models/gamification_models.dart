import 'dart:math';
import 'package:flutter/material.dart';

// ── Badge rarity ───────────────────────────────────────────────────────────────

enum BadgeRarity { common, rare, epic, legendary }

extension BadgeRarityX on BadgeRarity {
  String get label => switch (this) {
        BadgeRarity.common => 'Common',
        BadgeRarity.rare => 'Rare',
        BadgeRarity.epic => 'Epic',
        BadgeRarity.legendary => 'Legendary',
      };

  Color get color => switch (this) {
        BadgeRarity.common => const Color(0xFF6B7280),
        BadgeRarity.rare => const Color(0xFF3B82F6),
        BadgeRarity.epic => const Color(0xFF8B5CF6),
        BadgeRarity.legendary => const Color(0xFFF59E0B),
      };

  List<Color> get gradient => switch (this) {
        BadgeRarity.common => [
            const Color(0xFF6B7280),
            const Color(0xFF9CA3AF)
          ],
        BadgeRarity.rare => [
            const Color(0xFF1D4ED8),
            const Color(0xFF60A5FA)
          ],
        BadgeRarity.epic => [
            const Color(0xFF6D28D9),
            const Color(0xFFA78BFA)
          ],
        BadgeRarity.legendary => [
            const Color(0xFFB45309),
            const Color(0xFFFBBF24)
          ],
      };
}

// ── Badge condition context ────────────────────────────────────────────────────
// Passed to condition functions so they can check time/task metadata.

typedef BadgeCondition = bool Function(
    GamificationData data, Map<String, dynamic> event);

// ── Badge definition ───────────────────────────────────────────────────────────

class BadgeDef {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeRarity rarity;
  final int xpReward;
  final BadgeCondition condition;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.xpReward,
    required this.condition,
  });
}

// ── All badge definitions ──────────────────────────────────────────────────────

final List<BadgeDef> kAllBadges = [
  // ── Task completion milestones ──────────────────────────────────────────────
  BadgeDef(
    id: 'first_step',
    name: 'First Step',
    description: 'Complete your very first task',
    emoji: '🎯',
    rarity: BadgeRarity.common,
    xpReward: 20,
    condition: (d, _) => d.totalTasksCompleted >= 1,
  ),
  BadgeDef(
    id: 'productive',
    name: 'Productive',
    description: 'Complete 5 tasks',
    emoji: '✅',
    rarity: BadgeRarity.common,
    xpReward: 30,
    condition: (d, _) => d.totalTasksCompleted >= 5,
  ),
  BadgeDef(
    id: 'momentum',
    name: 'Momentum',
    description: 'Complete 10 tasks',
    emoji: '🚀',
    rarity: BadgeRarity.common,
    xpReward: 50,
    condition: (d, _) => d.totalTasksCompleted >= 10,
  ),
  BadgeDef(
    id: 'task_crusher',
    name: 'Task Crusher',
    description: 'Complete 25 tasks',
    emoji: '💪',
    rarity: BadgeRarity.rare,
    xpReward: 75,
    condition: (d, _) => d.totalTasksCompleted >= 25,
  ),
  BadgeDef(
    id: 'overachiever',
    name: 'Overachiever',
    description: 'Complete 50 tasks',
    emoji: '🏆',
    rarity: BadgeRarity.rare,
    xpReward: 100,
    condition: (d, _) => d.totalTasksCompleted >= 50,
  ),
  BadgeDef(
    id: 'centurion',
    name: 'Centurion',
    description: 'Complete 100 tasks',
    emoji: '🌟',
    rarity: BadgeRarity.epic,
    xpReward: 200,
    condition: (d, _) => d.totalTasksCompleted >= 100,
  ),
  BadgeDef(
    id: 'elite',
    name: 'Elite',
    description: 'Complete 250 tasks',
    emoji: '⚡',
    rarity: BadgeRarity.epic,
    xpReward: 350,
    condition: (d, _) => d.totalTasksCompleted >= 250,
  ),
  BadgeDef(
    id: 'legend_tasks',
    name: 'Legendary',
    description: 'Complete 500 tasks',
    emoji: '👑',
    rarity: BadgeRarity.legendary,
    xpReward: 500,
    condition: (d, _) => d.totalTasksCompleted >= 500,
  ),

  // ── Streak milestones ───────────────────────────────────────────────────────
  BadgeDef(
    id: 'consistent',
    name: 'Consistent',
    description: 'Maintain a 3-day completion streak',
    emoji: '🔥',
    rarity: BadgeRarity.common,
    xpReward: 25,
    condition: (d, _) => d.currentStreak >= 3,
  ),
  BadgeDef(
    id: 'hot_streak',
    name: 'Hot Streak',
    description: 'Maintain a 7-day completion streak',
    emoji: '🔥',
    rarity: BadgeRarity.rare,
    xpReward: 75,
    condition: (d, _) => d.currentStreak >= 7,
  ),
  BadgeDef(
    id: 'on_fire',
    name: 'On Fire',
    description: 'Maintain a 14-day completion streak',
    emoji: '🔥',
    rarity: BadgeRarity.rare,
    xpReward: 100,
    condition: (d, _) => d.currentStreak >= 14,
  ),
  BadgeDef(
    id: 'ironclad',
    name: 'Ironclad',
    description: 'Maintain a 30-day completion streak',
    emoji: '🔥',
    rarity: BadgeRarity.epic,
    xpReward: 300,
    condition: (d, _) => d.currentStreak >= 30,
  ),
  BadgeDef(
    id: 'iron_will',
    name: 'Iron Will',
    description: 'Maintain a 60-day completion streak',
    emoji: '🔥',
    rarity: BadgeRarity.legendary,
    xpReward: 500,
    condition: (d, _) => d.currentStreak >= 60,
  ),
  BadgeDef(
    id: 'streak_legend',
    name: 'Streak Legend',
    description: 'Maintain a 100-day completion streak',
    emoji: '🔥',
    rarity: BadgeRarity.legendary,
    xpReward: 1000,
    condition: (d, _) => d.currentStreak >= 100,
  ),

  // ── Focus sessions ──────────────────────────────────────────────────────────
  BadgeDef(
    id: 'in_the_zone',
    name: 'In the Zone',
    description: 'Complete your first focus session',
    emoji: '🎯',
    rarity: BadgeRarity.common,
    xpReward: 20,
    condition: (d, _) => d.focusSessionsCompleted >= 1,
  ),
  BadgeDef(
    id: 'deep_worker',
    name: 'Deep Worker',
    description: 'Complete 5 focus sessions',
    emoji: '🧠',
    rarity: BadgeRarity.rare,
    xpReward: 60,
    condition: (d, _) => d.focusSessionsCompleted >= 5,
  ),
  BadgeDef(
    id: 'flow_master',
    name: 'Flow State Master',
    description: 'Complete 25 focus sessions',
    emoji: '🎯',
    rarity: BadgeRarity.epic,
    xpReward: 200,
    condition: (d, _) => d.focusSessionsCompleted >= 25,
  ),

  // ── Time-based specials ─────────────────────────────────────────────────────
  BadgeDef(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Complete a task before 8:00 AM',
    emoji: '🌅',
    rarity: BadgeRarity.rare,
    xpReward: 40,
    condition: (d, event) => (event['hour'] as int? ?? 12) < 8,
  ),
  BadgeDef(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Complete a task after 10:00 PM',
    emoji: '🦉',
    rarity: BadgeRarity.rare,
    xpReward: 40,
    condition: (d, event) => (event['hour'] as int? ?? 12) >= 22,
  ),

  // ── Level milestone ─────────────────────────────────────────────────────────
  BadgeDef(
    id: 'rising_star',
    name: 'Rising Star',
    description: 'Reach Level 5',
    emoji: '⭐',
    rarity: BadgeRarity.epic,
    xpReward: 0, // 0 to avoid XP loop
    condition: (d, _) => d.level >= 5,
  ),
  BadgeDef(
    id: 'master',
    name: 'Master',
    description: 'Reach the maximum Level 10',
    emoji: '🏅',
    rarity: BadgeRarity.legendary,
    xpReward: 0,
    condition: (d, _) => d.level >= 10,
  ),
];

// ── Level system ───────────────────────────────────────────────────────────────

const List<int> kLevelThresholds = [
  0,     // Level 1
  100,   // Level 2
  300,   // Level 3
  600,   // Level 4
  1000,  // Level 5
  1500,  // Level 6
  2200,  // Level 7
  3000,  // Level 8
  4200,  // Level 9
  6000,  // Level 10
];

const List<String> kLevelLabels = [
  'Beginner',
  'Apprentice',
  'Focused',
  'Productive',
  'Dedicated',
  'Expert',
  'Elite',
  'Master',
  'Champion',
  'Legend',
];

int gamificationLevel(int xp) {
  for (int i = kLevelThresholds.length - 1; i >= 0; i--) {
    if (xp >= kLevelThresholds[i]) return i + 1;
  }
  return 1;
}

String gamificationLevelLabel(int level) {
  final idx = (level - 1).clamp(0, kLevelLabels.length - 1);
  return kLevelLabels[idx];
}

Color gamificationLevelColor(int level) {
  if (level >= 10) return const Color(0xFFF59E0B); // gold
  if (level >= 8) return const Color(0xFF8B5CF6);  // purple
  if (level >= 6) return const Color(0xFF3B82F6);  // blue
  if (level >= 4) return const Color(0xFF22C55E);  // green
  if (level >= 2) return const Color(0xFF6B7280);  // grey
  return const Color(0xFF94A3B8);                  // slate
}

int _xpForLevel(int level) {
  if (level <= 1) return 0;
  if (level > kLevelThresholds.length) return kLevelThresholds.last + 999999;
  return kLevelThresholds[level - 1];
}

// ── User gamification data ─────────────────────────────────────────────────────

class GamificationData {
  final int xp;
  final int totalTasksCompleted;
  final int currentStreak;
  final int longestStreak;
  final String? lastActivityDate; // "yyyy-MM-dd"
  final List<String> earnedBadgeIds;
  final int focusSessionsCompleted;

  const GamificationData({
    this.xp = 0,
    this.totalTasksCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.earnedBadgeIds = const [],
    this.focusSessionsCompleted = 0,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  int get level => gamificationLevel(xp);

  int get nextLevelXP => _xpForLevel(level + 1);

  int get currentLevelXP => _xpForLevel(level);

  double get levelProgress {
    if (level >= 10) return 1.0;
    final range = nextLevelXP - currentLevelXP;
    if (range <= 0) return 1.0;
    return ((xp - currentLevelXP) / range).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => max(0, nextLevelXP - xp);

  List<BadgeDef> get earnedBadges {
    final ids = earnedBadgeIds.toSet();
    return kAllBadges.where((b) => ids.contains(b.id)).toList();
  }

  // ── Serialization ────────────────────────────────────────────────────────────

  factory GamificationData.fromMap(Map<String, dynamic> m) => GamificationData(
        xp: (m['xp'] ?? 0) as int,
        totalTasksCompleted: (m['totalTasksCompleted'] ?? 0) as int,
        currentStreak: (m['currentStreak'] ?? 0) as int,
        longestStreak: (m['longestStreak'] ?? 0) as int,
        lastActivityDate: m['lastActivityDate'] as String?,
        earnedBadgeIds:
            List<String>.from((m['earnedBadgeIds'] ?? const []) as List),
        focusSessionsCompleted: (m['focusSessionsCompleted'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'xp': xp,
        'totalTasksCompleted': totalTasksCompleted,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': lastActivityDate,
        'earnedBadgeIds': earnedBadgeIds,
        'focusSessionsCompleted': focusSessionsCompleted,
      };

  GamificationData copyWith({
    int? xp,
    int? totalTasksCompleted,
    int? currentStreak,
    int? longestStreak,
    String? lastActivityDate,
    List<String>? earnedBadgeIds,
    int? focusSessionsCompleted,
  }) =>
      GamificationData(
        xp: xp ?? this.xp,
        totalTasksCompleted:
            totalTasksCompleted ?? this.totalTasksCompleted,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastActivityDate: lastActivityDate ?? this.lastActivityDate,
        earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
        focusSessionsCompleted:
            focusSessionsCompleted ?? this.focusSessionsCompleted,
      );
}
