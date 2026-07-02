import 'package:dio/dio.dart';
import '../features/assistant/models/assistant_models.dart';
import '../features/health/models/health_models.dart';
import '../services/health_engine.dart';
import '../services/gamification_engine.dart';
import 'api_client.dart';
import 'local_storage.dart';

class AssistantService {
  AssistantService._();
  static final AssistantService instance = AssistantService._();

  final _api = ApiClient();

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<List<ChatMessage>> loadHistory() async {
    final cached = LocalStorage.getChatHistory();
    return cached
        .map((m) => ChatMessage(
              id: '${m['createdAt'] ?? DateTime.now().toIso8601String()}',
              role: m['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
              content: (m['content'] ?? '') as String,
              timestamp: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
            ))
        .toList();
  }

  Future<({String reply, TaskDraft? taskDraft, List<String>? subtaskItems})> send(
      String userMessage) async {
    final intent = detectIntent(userMessage);
    final contextPrefix = _buildContextPrefix();
    final enriched = '$contextPrefix$userMessage';

    // Call AI endpoint
    String reply;
    try {
      final res = await _api.post('/ai/chat', data: {'message': enriched});
      reply = (res.data['reply'] as String?) ?? 'No response received.';
    } on DioException catch (e) {
      final code = e.response?.data is Map ? e.response?.data['code'] : null;
      if (code == 'AI_OFFLINE') {
        // Backend reachable but OpenRouter/AI provider is down.
        reply = 'The AI assistant is temporarily unavailable. '
            'Please try again in a moment.';
      } else {
        // True network error — device is offline or backend is cold-starting.
        reply = _offlineFallback(intent);
      }
    }

    // Persist both sides to local cache
    final now = DateTime.now().toIso8601String();
    await LocalStorage.appendChatMessages([
      {'role': 'user', 'content': userMessage, 'createdAt': now},
      {'role': 'assistant', 'content': reply, 'createdAt': now},
    ]);

    // Extract structured data from the reply / user message
    TaskDraft? taskDraft;
    List<String>? subtaskItems;

    if (intent == MessageIntent.createTask) {
      taskDraft = _extractTaskDraft(userMessage);
    }

    if (intent == MessageIntent.breakdownTask ||
        intent == MessageIntent.generateSchedule) {
      final items = _extractListItems(reply);
      if (items.length >= 2) {
        subtaskItems = items;
      }
    }

    return (reply: reply, taskDraft: taskDraft, subtaskItems: subtaskItems);
  }

  Future<void> clearHistory() async {
    await LocalStorage.saveChatHistory([]);
    try {
      await _api.delete('/ai/chat/history');
    } catch (_) {}
  }

  // ── Context injection ─────────────────────────────────────────────────────

  String _buildContextPrefix() {
    final tasks = LocalStorage.getAllTasks();
    final pending = tasks.where((t) => t['isCompleted'] != true).length;
    final urgent = tasks
        .where((t) =>
            t['isCompleted'] != true &&
            ((t['priority'] ?? '') as String).toUpperCase() == 'URGENT')
        .length;

    final now = DateTime.now();
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dayNames[now.weekday - 1];
    final month = monthNames[now.month - 1];
    final period = now.hour < 12 ? 'morning' : (now.hour < 17 ? 'afternoon' : 'evening');

    final health = HealthEngine.todayEntry();
    final healthStr = health != null
        ? ', energy ${health.energyLevel}/5, mood: ${health.mood.label}'
        : '';

    final gam = GamificationEngine.load();
    final streakStr = gam.currentStreak > 0 ? ', ${gam.currentStreak}-day streak' : '';

    return '[$day $month ${now.day}, $period. '
        '$pending pending task${pending != 1 ? "s" : ""} ($urgent urgent)'
        '$healthStr$streakStr. '
        'You are TaskGuard AI, a concise productivity assistant. '
        'Use bullet points for lists. Be brief and actionable.]\n\n';
  }

  // ── Offline fallback ──────────────────────────────────────────────────────

  String _offlineFallback(MessageIntent intent) {
    switch (intent) {
      case MessageIntent.createTask:
        return "I'm offline, but I've captured your task draft below — tap **Add to TaskGuard** to save it locally. It will sync when you're back online.";
      case MessageIntent.breakdownTask:
        return "I can't reach the AI right now. Try splitting your task into:\n• Define the goal clearly\n• Identify 3–5 key milestones\n• Set a deadline for each step\n• Start with the smallest first action";
      case MessageIntent.generateSchedule:
        return "I'm offline. A quick schedule tip: block your first 90 minutes for your most important task, take a break, then handle communication tasks in the afternoon.";
      case MessageIntent.prioritize:
        return "I'm offline. Classic prioritization: tackle **Urgent + Important** tasks first, then **Important but not Urgent**, then delegate or drop the rest.";
      case MessageIntent.general:
        return "I'm currently offline. Your data is saved locally. Reconnect to unlock AI-powered advice.";
    }
  }

  // ── Task draft extraction (client-side NLP) ───────────────────────────────

  TaskDraft _extractTaskDraft(String message) {
    return TaskDraft(
      title: _extractTitle(message),
      priority: _extractPriority(message),
      dueDateIso: _extractDueDate(message),
    );
  }

  String _extractTitle(String message) {
    String text = message.trim();

    final prefixes = [
      RegExp(r'^(please\s+)?(can you\s+)?(create|add|make|set up|set)\s+(a\s+|an\s+)?(new\s+)?task\s+(to\s+|for\s+)?', caseSensitive: false),
      RegExp(r'^(remind me to|i need to|help me|i want to)\s+', caseSensitive: false),
      RegExp(r'^(can you\s+)?(help me\s+)?(add|create|make)\s+(a\s+)?', caseSensitive: false),
    ];
    for (final p in prefixes) {
      text = text.replaceFirst(p, '');
    }

    // Remove trailing priority/date noise
    text = text
        .replaceAll(RegExp(r',?\s*(urgent|high|medium|low)\s+priority\b', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*by\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|tomorrow|today|next\s+week)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*in\s+\d+\s+days?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r',?\s*(asap|immediately|urgently)\b', caseSensitive: false), '')
        .trim()
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();

    if (text.isEmpty) {
      return 'New Task';
    }
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _extractPriority(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('urgent') || lower.contains('asap') || lower.contains('critical') || lower.contains('emergency')) {
      return 'URGENT';
    }
    if (lower.contains('high priority') || lower.contains('high-priority') || lower.contains('very important')) {
      return 'HIGH';
    }
    if (lower.contains('low priority') || lower.contains('low-priority') || lower.contains('not urgent') || lower.contains('whenever')) {
      return 'LOW';
    }
    return 'MEDIUM';
  }

  String? _extractDueDate(String message) {
    final lower = message.toLowerCase();
    final now = DateTime.now();

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    if (lower.contains('today')) {
      return fmt(now);
    }
    if (lower.contains('tomorrow')) {
      return fmt(now.add(const Duration(days: 1)));
    }
    if (lower.contains('next week')) {
      return fmt(now.add(const Duration(days: 7)));
    }
    if (lower.contains('end of week') || lower.contains('this friday')) {
      int diff = 5 - now.weekday;
      if (diff < 0) {
        diff += 7;
      }
      return fmt(now.add(Duration(days: diff == 0 ? 7 : diff)));
    }

    const weekdays = {
      'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
    };
    for (final e in weekdays.entries) {
      if (lower.contains(e.key)) {
        int diff = e.value - now.weekday;
        if (diff <= 0) {
          diff += 7;
        }
        return fmt(now.add(Duration(days: diff)));
      }
    }

    final numMatch = RegExp(r'in (\d+) days?').firstMatch(lower);
    if (numMatch != null) {
      final n = int.tryParse(numMatch.group(1)!) ?? 0;
      return fmt(now.add(Duration(days: n)));
    }

    return null;
  }

  // ── List extraction from AI response ─────────────────────────────────────

  List<String> _extractListItems(String content) {
    return content
        .split('\n')
        .map((l) => l.trim())
        .where((l) =>
            l.startsWith('• ') ||
            l.startsWith('- ') ||
            l.startsWith('* ') ||
            RegExp(r'^\d+\.\s').hasMatch(l))
        .map((l) => l.replaceFirst(RegExp(r'^[•\-\*]\s+|\d+\.\s+'), '').trim())
        .where((l) => l.isNotEmpty && l.length < 130)
        .take(10)
        .toList();
  }
}
