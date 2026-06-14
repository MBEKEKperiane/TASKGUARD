import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('taskguard_cache');
  }

  // ── Tasks ──────────────────────────────────────────────
  static List<Map<String, dynamic>> getTodayTasks() => _getList('today_tasks');
  static Future<void> saveTodayTasks(List<dynamic> v) =>
      _box.put('today_tasks', jsonEncode(v));

  static List<Map<String, dynamic>> getAllTasks() => _getList('all_tasks');
  static Future<void> saveAllTasks(List<dynamic> v) =>
      _box.put('all_tasks', jsonEncode(v));

  // ── Chat ───────────────────────────────────────────────
  static List<Map<String, dynamic>> getChatHistory() =>
      _getList('chat_history');

  static Future<void> saveChatHistory(List<dynamic> v) =>
      _box.put('chat_history', jsonEncode(v));

  static Future<void> appendChatMessages(List<Map<String, dynamic>> msgs) async {
    final history = getChatHistory();
    history.addAll(msgs);
    final trimmed =
        history.length > 100 ? history.sublist(history.length - 100) : history;
    await saveChatHistory(trimmed);
  }

  // ── User ───────────────────────────────────────────────
  static Map<String, dynamic>? getUser() {
    final raw = _box.get('user') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> saveUser(Map<String, dynamic> v) =>
      _box.put('user', jsonEncode(v));

  // ── Productivity score ─────────────────────────────────
  static Map<String, dynamic>? getProductivityScore() {
    final raw = _box.get('productivity_score') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> saveProductivityScore(Map<String, dynamic> v) =>
      _box.put('productivity_score', jsonEncode(v));

  // ── Pending offline ops ────────────────────────────────
  static List<Map<String, dynamic>> getPendingOps() =>
      _getList('pending_ops');

  static Future<void> addPendingOp(Map<String, dynamic> op) async {
    final ops = getPendingOps();
    ops.add(op);
    await _box.put('pending_ops', jsonEncode(ops));
  }

  static Future<void> clearPendingOps() =>
      _box.put('pending_ops', jsonEncode([]));

  // ── Focus history ──────────────────────────────────────
  static List<Map<String, dynamic>> getFocusHistory() =>
      _getList('focus_history');

  static Future<void> _saveFocusHistory(List<dynamic> v) =>
      _box.put('focus_history', jsonEncode(v));

  /// Prepends [session] to the history and keeps only the 50 most recent entries.
  static Future<void> addFocusSession(Map<String, dynamic> session) async {
    final history = getFocusHistory();
    history.insert(0, session);
    final trimmed = history.length > 50 ? history.sublist(0, 50) : history;
    await _saveFocusHistory(trimmed);
  }

  // ── Teams ──────────────────────────────────────────────
  static List<Map<String, dynamic>> getTeams() => _getList('teams');
  static Future<void> saveTeams(List<dynamic> v) =>
      _box.put('teams', jsonEncode(v));

  static List<Map<String, dynamic>> getTeamMembers(String teamId) =>
      _getList('team_members_$teamId');
  static Future<void> saveTeamMembers(String teamId, List<dynamic> v) =>
      _box.put('team_members_$teamId', jsonEncode(v));

  static List<Map<String, dynamic>> getTeamInvites() =>
      _getList('team_invites');
  static Future<void> saveTeamInvites(List<dynamic> v) =>
      _box.put('team_invites', jsonEncode(v));

  static List<Map<String, dynamic>> getAssignedTasks() =>
      _getList('assigned_tasks');
  static Future<void> saveAssignedTasks(List<dynamic> v) =>
      _box.put('assigned_tasks', jsonEncode(v));

  static List<Map<String, dynamic>> getSharedTasks() =>
      _getList('shared_tasks');
  static Future<void> saveSharedTasks(List<dynamic> v) =>
      _box.put('shared_tasks', jsonEncode(v));

  static Map<String, dynamic>? getTeamProgress(String teamId) {
    final raw = _box.get('team_progress_$teamId') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> saveTeamProgress(String teamId, Map<String, dynamic> v) =>
      _box.put('team_progress_$teamId', jsonEncode(v));

  // ── Study — Subjects ───────────────────────────────────
  static List<Map<String, dynamic>> getSubjects() => _getList('study_subjects');
  static Future<void> saveSubjects(List<dynamic> v) =>
      _box.put('study_subjects', jsonEncode(v));

  // ── Study — Assignments ────────────────────────────────
  static List<Map<String, dynamic>> getAssignments() =>
      _getList('study_assignments');
  static Future<void> saveAssignments(List<dynamic> v) =>
      _box.put('study_assignments', jsonEncode(v));

  // ── Study — Exams ──────────────────────────────────────
  static List<Map<String, dynamic>> getExams() => _getList('study_exams');
  static Future<void> saveExams(List<dynamic> v) =>
      _box.put('study_exams', jsonEncode(v));

  // ── Study — Plan ───────────────────────────────────────
  static Map<String, dynamic>? getStudyPlan() {
    final raw = _box.get('study_plan') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> saveStudyPlan(Map<String, dynamic> v) =>
      _box.put('study_plan', jsonEncode(v));

  // ── Health ─────────────────────────────────────────────
  static List<Map<String, dynamic>> getHealthEntries() =>
      _getList('health_entries');
  static Future<void> saveHealthEntries(List<dynamic> v) =>
      _box.put('health_entries', jsonEncode(v));

  // ── Gamification ───────────────────────────────────────
  static Map<String, dynamic>? getGamificationData() {
    final raw = _box.get('gamification_data') as String?;
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static Future<void> saveGamificationData(Map<String, dynamic> v) =>
      _box.put('gamification_data', jsonEncode(v));

  // ── Clear all ──────────────────────────────────────────
  static Future<void> clearAll() => _box.clear();

  // ── Helper ─────────────────────────────────────────────
  static List<Map<String, dynamic>> _getList(String key) {
    final raw = _box.get(key, defaultValue: '[]') as String;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
