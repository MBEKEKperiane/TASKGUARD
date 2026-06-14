import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/mood/models/mood_entry.dart';

/// Persists the current mood and a rolling 30-entry history.
///
/// Keys:
///   wellness_mood         — current mood storageKey (backward-compat)
///   wellness_mood_date    — ISO date string of the last entry (for daily check-in guard)
///   wellness_mood_history — JSON-encoded list of MoodEntry (max 30)
class MoodStorage {
  MoodStorage._();

  static const _kCurrent = 'wellness_mood';
  static const _kDate = 'wellness_mood_date';
  static const _kHistory = 'wellness_mood_history';
  static const _historyLimit = 30;

  // ── Write ──────────────────────────────────────────────────────────────────

  static Future<void> save(MoodType mood) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = MoodEntry(mood: mood, timestamp: DateTime.now());

    await prefs.setString(_kCurrent, mood.storageKey);
    await prefs.setString(_kDate, _todayKey());
    await _appendHistory(prefs, entry);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  static Future<MoodType?> loadCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCurrent);
    if (raw == null) return null;
    return MoodTypeX.fromStorage(raw);
  }

  static Future<List<MoodEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistory);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns true when the user has already logged a mood today.
  static Future<bool> hasLoggedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDate) == _todayKey();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static Future<void> _appendHistory(
      SharedPreferences prefs, MoodEntry entry) async {
    List<MoodEntry> history = [];
    final raw = prefs.getString(_kHistory);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        history = list
            .map((e) => MoodEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    history.insert(0, entry);
    if (history.length > _historyLimit) {
      history = history.sublist(0, _historyLimit);
    }
    await prefs.setString(
        _kHistory, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
