import 'dart:math';
import '../features/gamification/models/gamification_models.dart';
import 'local_storage.dart';

class GamificationEngine {
  GamificationEngine._();

  // ── Load / save ────────────────────────────────────────────────────────────

  static GamificationData load() {
    final map = LocalStorage.getGamificationData();
    if (map == null) return const GamificationData();
    return GamificationData.fromMap(map);
  }

  static Future<void> _save(GamificationData data) =>
      LocalStorage.saveGamificationData(data.toMap());

  // ── Task completed ─────────────────────────────────────────────────────────

  /// Call immediately after a task is marked complete.
  /// Returns any newly earned badges so the caller can show the overlay.
  static Future<List<BadgeDef>> onTaskCompleted({
    required Map<String, dynamic> task,
    DateTime? completedAt,
  }) async {
    completedAt ??= DateTime.now();
    var data = load();

    // 1. Award task XP
    final xpEarned = _taskXP(task);
    data = data.copyWith(
      xp: data.xp + xpEarned,
      totalTasksCompleted: data.totalTasksCompleted + 1,
    );

    // 2. Update streak
    final today = _dayKey(completedAt);
    final (newStreak, newLongest) = _updatedStreak(
      lastDate: data.lastActivityDate,
      current: data.currentStreak,
      longest: data.longestStreak,
      today: today,
    );
    data = data.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActivityDate: today,
    );

    // 3. Check badges — pass event context (hour for early_bird / night_owl)
    final event = <String, dynamic>{'hour': completedAt.hour};
    final newBadges = _checkBadges(data, event);
    if (newBadges.isNotEmpty) {
      final bonusXP = newBadges.fold(0, (s, b) => s + b.xpReward);
      data = data.copyWith(
        xp: data.xp + bonusXP,
        earnedBadgeIds: [
          ...data.earnedBadgeIds,
          ...newBadges.map((b) => b.id),
        ],
      );
    }

    await _save(data);
    return newBadges;
  }

  // ── Focus session completed ────────────────────────────────────────────────

  static Future<List<BadgeDef>> onFocusCompleted() async {
    var data = load();
    data = data.copyWith(
      xp: data.xp + 10,
      focusSessionsCompleted: data.focusSessionsCompleted + 1,
    );

    final newBadges = _checkBadges(data, const {});
    if (newBadges.isNotEmpty) {
      final bonusXP = newBadges.fold(0, (s, b) => s + b.xpReward);
      data = data.copyWith(
        xp: data.xp + bonusXP,
        earnedBadgeIds: [
          ...data.earnedBadgeIds,
          ...newBadges.map((b) => b.id),
        ],
      );
    }

    await _save(data);
    return newBadges;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static List<BadgeDef> _checkBadges(
      GamificationData data, Map<String, dynamic> event) {
    final earned = data.earnedBadgeIds.toSet();
    return kAllBadges
        .where((b) => !earned.contains(b.id))
        .where((b) => b.condition(data, event))
        .toList();
  }

  static (int streak, int longest) _updatedStreak({
    required String? lastDate,
    required int current,
    required int longest,
    required String today,
  }) {
    if (lastDate == null) {
      final s = max(1, current);
      return (s, max(s, longest));
    }
    if (lastDate == today) return (current, longest);

    try {
      final last = DateTime.parse(lastDate);
      final todayDate = DateTime.parse(today);
      final diff = todayDate.difference(last).inDays;
      final newStreak = diff == 1 ? current + 1 : 1;
      return (newStreak, max(newStreak, longest));
    } catch (_) {
      return (1, max(1, longest));
    }
  }

  static int _taskXP(Map task) =>
      switch ((task['priority'] ?? 'LOW') as String) {
        'URGENT' => 25,
        'HIGH' => 15,
        'MEDIUM' => 10,
        _ => 5,
      };

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
