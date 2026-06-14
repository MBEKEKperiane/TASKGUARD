// ── Message role ──────────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

// ── Intent ────────────────────────────────────────────────────────────────────

enum MessageIntent {
  createTask,
  breakdownTask,
  generateSchedule,
  prioritize,
  general,
}

MessageIntent detectIntent(String message) {
  final lower = message.toLowerCase();

  if (RegExp(r'\b(break\s*down|breakdown|subtasks?|steps\s+for|how\s+to\s+(do|complete|finish))\b')
      .hasMatch(lower)) {
    return MessageIntent.breakdownTask;
  }

  if (RegExp(r'\b(create|add|new task|remind me to|i need to)\b').hasMatch(lower) &&
      !lower.contains('break')) {
    return MessageIntent.createTask;
  }

  if (RegExp(r'\b(schedule|plan my day|daily plan|when should i)\b').hasMatch(lower)) {
    return MessageIntent.generateSchedule;
  }

  if (RegExp(r'\b(prioritize|prioritise|what should i do first|most important)\b')
      .hasMatch(lower)) {
    return MessageIntent.prioritize;
  }

  return MessageIntent.general;
}

// ── Task draft ─────────────────────────────────────────────────────────────────

class TaskDraft {
  final String title;
  final String priority; // URGENT | HIGH | MEDIUM | LOW
  final String? dueDateIso; // "yyyy-MM-dd"
  bool added; // true once the user confirms creation

  TaskDraft({
    required this.title,
    required this.priority,
    this.dueDateIso,
    this.added = false,
  });
}

// ── Chat message ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  // Optional structured data attached to AI replies
  TaskDraft? taskDraft;
  List<String>? subtaskItems; // extracted list — cleared after user adds tasks
  bool subtasksAdded;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.taskDraft,
    this.subtaskItems,
    this.subtasksAdded = false,
  });
}

// ── Quick prompts ──────────────────────────────────────────────────────────────

class QuickPrompt {
  final String label;
  final String emoji;
  final String message;
  const QuickPrompt({
    required this.label,
    required this.emoji,
    required this.message,
  });
}

const List<QuickPrompt> kQuickPrompts = [
  QuickPrompt(
    label: 'Create task',
    emoji: '📝',
    message: 'Help me create a new task',
  ),
  QuickPrompt(
    label: 'Plan my day',
    emoji: '📅',
    message:
        'Generate a schedule for my day based on my pending tasks and energy level',
  ),
  QuickPrompt(
    label: 'Prioritize',
    emoji: '🎯',
    message: 'Help me decide which tasks I should focus on first today',
  ),
  QuickPrompt(
    label: 'Break it down',
    emoji: '🧩',
    message:
        'I have a complex project. Help me break it down into actionable steps',
  ),
  QuickPrompt(
    label: 'Focus tips',
    emoji: '💡',
    message:
        'Give me 3 actionable productivity tips I can apply right now to stay focused',
  ),
];
