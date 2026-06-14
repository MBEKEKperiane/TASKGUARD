import '../features/health/models/health_models.dart';
import 'local_storage.dart';

class HealthEngine {
  HealthEngine._();

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Load ──────────────────────────────────────────────────────────────────────

  static HealthEntry? todayEntry() {
    final today = _todayKey();
    final all = LocalStorage.getHealthEntries();
    try {
      return all
          .map((m) => HealthEntry.fromMap(m))
          .firstWhere((e) => e.date == today);
    } catch (_) {
      return null;
    }
  }

  static List<HealthEntry> recentEntries({int days = 7}) {
    final all = LocalStorage.getHealthEntries()
        .map((m) => HealthEntry.fromMap(m))
        .toList();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(days).toList();
  }

  // ── Save ──────────────────────────────────────────────────────────────────────

  static Future<void> saveEntry(HealthEntry entry) async {
    final all = LocalStorage.getHealthEntries();
    final idx = all.indexWhere((m) => m['date'] == entry.date);
    if (idx >= 0) {
      all[idx] = entry.toMap();
    } else {
      all.insert(0, entry.toMap());
    }
    // Keep last 90 days
    final trimmed = all.length > 90 ? all.sublist(0, 90) : all;
    await LocalStorage.saveHealthEntries(trimmed);
  }

  // ── Compute workload ──────────────────────────────────────────────────────────

  static WorkloadLevel computeWorkload(HealthEntry entry) {
    final score =
        sleepScore(entry.sleepHours) + // 0-3
        energyScore(entry.energyLevel) + // 0-4
        entry.mood.score; // 0-4   total 0-11

    if (score <= 2) return WorkloadLevel.rest;
    if (score <= 4) return WorkloadLevel.light;
    if (score <= 7) return WorkloadLevel.moderate;
    if (score <= 9) return WorkloadLevel.full;
    return WorkloadLevel.stretch;
  }

  static HealthInsight insight(HealthEntry entry) {
    final workload = computeWorkload(entry);
    return HealthInsight(workload: workload, tips: workload.tips);
  }

  // ── Task filtering ────────────────────────────────────────────────────────────
  // Returns the subset of tasks the user should focus on given their workload.
  // Falls back to the full list when there is no health entry.

  static List<Map<String, dynamic>> filteredTasks(
    List<dynamic> tasks,
    WorkloadLevel? workload,
  ) {
    if (workload == null) return tasks.cast<Map<String, dynamic>>();

    final allowed = workload.allowedPriorities;
    final cap = workload.taskCap;

    List<Map<String, dynamic>> result = tasks
        .whereType<Map<String, dynamic>>()
        .where((t) => t['isCompleted'] != true)
        .toList();

    if (allowed != null) {
      result = result
          .where((t) =>
              allowed.contains(
                  ((t['priority'] ?? 'LOW') as String).toUpperCase()))
          .toList();
    }

    if (cap != null && result.length > cap) {
      result = result.sublist(0, cap);
    }

    return result;
  }

  // ── Averages (for dashboard) ──────────────────────────────────────────────────

  static double averageSleep(List<HealthEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.fold(0.0, (s, e) => s + e.sleepHours) / entries.length;
  }

  static double averageEnergy(List<HealthEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.fold(0.0, (s, e) => s + e.energyLevel) / entries.length;
  }

  static double averageMoodScore(List<HealthEntry> entries) {
    if (entries.isEmpty) return 0;
    return entries.fold(0.0, (s, e) => s + e.mood.score) / entries.length;
  }
}
