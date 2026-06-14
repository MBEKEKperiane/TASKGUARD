import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/assistant/models/assistant_models.dart';
import '../../services/assistant_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_colors.dart';

// ── Theme helpers ──────────────────────────────────────────────────────────────

Color _bg(BuildContext ctx) => ctx.colBg;
Color _card(BuildContext ctx) => ctx.colCard;
Color _surface(BuildContext ctx) => ctx.colSurface;
Color _text1(BuildContext ctx) => ctx.colText1;
Color _text2(BuildContext ctx) => ctx.colText2;
Color _hint(BuildContext ctx) => ctx.colHint;
Color _divider(BuildContext ctx) => ctx.colDivider;

// ── Priority helpers ───────────────────────────────────────────────────────────

Color _priorityColor(String p) => switch (p.toUpperCase()) {
      'URGENT' => const Color(0xFFEF4444),
      'HIGH' => const Color(0xFFE91E8C),
      'LOW' => const Color(0xFF6B7280),
      _ => const Color(0xFFF59E0B),
    };

String _priorityLabel(String p) => switch (p.toUpperCase()) {
      'URGENT' => 'Urgent',
      'HIGH' => 'High',
      'LOW' => 'Low',
      _ => 'Medium',
    };

String _dueDateLabel(String? iso) {
  if (iso == null) return 'No due date';
  try {
    final d = DateTime.parse(iso);
    final now = DateTime.now();
    final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  } catch (_) {
    return iso;
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════════

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _taskService = TaskService();
  final _assistant = AssistantService.instance;

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final history = await _assistant.loadHistory();
    if (mounted) {
      setState(() {
        _messages = history;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) {
      return;
    }
    _ctrl.clear();

    final userMsg = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}u',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _sending = true;
    });
    _scrollToBottom();

    final result = await _assistant.send(text);

    final aiMsg = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}a',
      role: MessageRole.assistant,
      content: result.reply,
      timestamp: DateTime.now(),
      taskDraft: result.taskDraft,
      subtaskItems: result.subtaskItems,
    );

    if (mounted) {
      setState(() {
        _messages.add(aiMsg);
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _confirmTaskDraft(ChatMessage msg) async {
    final draft = msg.taskDraft;
    if (draft == null || draft.added) {
      return;
    }
    setState(() => draft.added = true);

    try {
      await _taskService.createTask(
        title: draft.title,
        priority: draft.priority,
        dueDate: draft.dueDateIso,
      );
      if (mounted) {
        _appendSystemMessage(
            '✅ **${draft.title}** has been added to your tasks!');
      }
    } catch (_) {
      if (mounted) {
        setState(() => draft.added = false);
      }
    }
  }

  Future<void> _addAllSubtasks(ChatMessage msg) async {
    final items = msg.subtaskItems;
    if (items == null || msg.subtasksAdded) {
      return;
    }
    setState(() => msg.subtasksAdded = true);

    int created = 0;
    for (final title in items) {
      try {
        await _taskService.createTask(title: title, priority: 'MEDIUM');
        created++;
      } catch (_) {}
    }

    if (mounted) {
      _appendSystemMessage(
          '✅ Added $created task${created != 1 ? "s" : ""} to TaskGuard!');
    }
  }

  void _appendSystemMessage(String content) {
    setState(() {
      _messages.add(ChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}s',
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(ctx),
        title: Text('Clear conversation?',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: _text1(ctx))),
        content: Text(
            'This will remove all chat history permanently.',
            style: GoogleFonts.inter(color: _text2(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: _text2(ctx))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear',
                style: GoogleFonts.inter(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _assistant.clearHistory();
      if (mounted) {
        setState(() => _messages.clear());
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? _welcomeView()
                    : _messagesList(),
          ),
          _inputArea(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bg(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _text1(context), size: 18),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TaskGuard AI',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _text1(context))),
              Text('Your productivity assistant',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _hint(context))),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: _hint(context), size: 20),
            tooltip: 'Clear history',
            onPressed: _clearHistory,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Welcome view ──────────────────────────────────────────────────────────────

  Widget _welcomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        children: [
          // Avatar + greeting
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 16),
          Text('Hi! I\'m TaskGuard AI ✦',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _text1(context))),
          const SizedBox(height: 8),
          Text(
            'Your intelligent productivity assistant.\nAsk me anything or pick a quick action below.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14, color: _text2(context), height: 1.5),
          ),
          const SizedBox(height: 28),

          // Capability cards
          ...[
            ('📝', 'Create tasks', 'Just describe what you need to do'),
            ('📅', 'Generate schedules', 'Get a smart plan for your day'),
            ('🧩', 'Break down projects', 'Split big tasks into steps'),
            ('🎯', 'Set priorities', 'Know what to tackle first'),
          ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _divider(context)),
                  ),
                  child: Row(children: [
                    Text(item.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _text1(context))),
                        Text(item.$3,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _text2(context))),
                      ],
                    ),
                  ]),
                ),
              )),

          const SizedBox(height: 8),
          Text('Try a quick action',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hint(context))),
          const SizedBox(height: 10),
          _quickChipsGrid(),
        ],
      ),
    );
  }

  Widget _quickChipsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: kQuickPrompts.map((p) {
        return GestureDetector(
          onTap: () => _send(p.message),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(p.label,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Messages list ──────────────────────────────────────────────────────────────

  Widget _messagesList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (_sending && i == _messages.length) {
          return _typingBubble();
        }
        return _messageBubble(_messages[i]);
      },
    );
  }

  Widget _messageBubble(ChatMessage msg) {
    final isAI = msg.role == MessageRole.assistant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Avatar + bubble row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAI) ...[
                _aiAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: isAI
                    ? _aiBubble(msg)
                    : _userBubble(msg),
              ),
              if (!isAI) ...[
                const SizedBox(width: 8),
                _userAvatar(),
              ],
            ],
          ),

          // Structured action cards below AI bubble
          if (isAI && msg.taskDraft != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: _taskDraftCard(msg),
            ),
          ],
          if (isAI &&
              msg.subtaskItems != null &&
              msg.subtaskItems!.isNotEmpty &&
              !msg.subtasksAdded) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: _subtaskListCard(msg),
            ),
          ],

          // Timestamp
          Padding(
            padding: EdgeInsets.only(
                top: 4,
                left: isAI ? 44 : 0,
                right: isAI ? 0 : 44),
            child: Text(
              _formatTime(msg.timestamp),
              style: GoogleFonts.inter(
                  fontSize: 10, color: _hint(context)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bubble widgets ─────────────────────────────────────────────────────────────

  Widget _aiAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 16),
    );
  }

  Widget _userAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _card(context),
        shape: BoxShape.circle,
        border: Border.all(color: _divider(context)),
      ),
      child: Icon(Icons.person_rounded, color: _hint(context), size: 18),
    );
  }

  Widget _aiBubble(ChatMessage msg) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E8C), Color(0xFFFF4BAF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: _RichContent(text: msg.content, textColor: Colors.white),
    );
  }

  Widget _userBubble(ChatMessage msg) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(color: _divider(context)),
      ),
      child: Text(
        msg.content,
        style: GoogleFonts.inter(
            fontSize: 14, color: _text1(context), height: 1.5),
      ),
    );
  }

  // ── Task draft card ────────────────────────────────────────────────────────────

  Widget _taskDraftCard(ChatMessage msg) {
    final draft = msg.taskDraft!;
    final pc = _priorityColor(draft.priority);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.task_alt_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text('Task ready to add',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          Text(draft.title,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text1(context))),
          const SizedBox(height: 6),
          Row(children: [
            _pill(_priorityLabel(draft.priority), pc),
            const SizedBox(width: 6),
            _pill(_dueDateLabel(draft.dueDateIso),
                _text2(context)),
          ]),
          const SizedBox(height: 12),
          draft.added
              ? Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.secondary, size: 16),
                  const SizedBox(width: 6),
                  Text('Added to TaskGuard!',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary)),
                ])
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _confirmTaskDraft(msg),
                    child: Text('Add to TaskGuard',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Subtask list card ─────────────────────────────────────────────────────────

  Widget _subtaskListCard(ChatMessage msg) {
    final items = msg.subtaskItems!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.list_alt_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text('${items.length} steps identified',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          ...items.take(6).toList().asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.value,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _text1(context),
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
          if (items.length > 6)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('+${items.length - 6} more…',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _hint(context))),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _addAllSubtasks(msg),
              child: Text('Add all as tasks',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────────────────────

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _aiAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E8C), Color(0xFFFF4BAF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  // ── Quick chips (inline in input area) ────────────────────────────────────────

  Widget _quickChipsRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kQuickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final p = kQuickPrompts[i];
          return GestureDetector(
            onTap: () => _send(p.message),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _divider(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(p.label,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _text2(context))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Input area ─────────────────────────────────────────────────────────────────

  Widget _inputArea() {
    return Container(
      decoration: BoxDecoration(
        color: _surface(context),
        border: Border(top: BorderSide(color: _divider(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quickChipsRow(),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _divider(context)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      style: GoogleFonts.inter(
                          fontSize: 14, color: _text1(context)),
                      decoration: InputDecoration(
                        hintText: 'Ask anything…',
                        hintStyle:
                            GoogleFonts.inter(fontSize: 14, color: _hint(context)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: _sending
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFE91E8C), Color(0xFFFF4BAF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _sending ? _divider(context) : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _sending ? _hint(context) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────────

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12
        ? local.hour - 12
        : local.hour == 0
            ? 12
            : local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Rich content renderer
// ════════════════════════════════════════════════════════════════════════════════

class _RichContent extends StatelessWidget {
  final String text;
  final Color textColor;

  const _RichContent({required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    int orderedIndex = 0;

    for (final raw in lines) {
      final line = raw.trim();

      if (line.isEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 6));
        }
        orderedIndex = 0;
        continue;
      }

      // Heading: # ## ###
      final headingMatch = RegExp(r'^#{1,3}\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 8, bottom: 2),
          child: Text(headingMatch.group(1)!,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textColor)),
        ));
        orderedIndex = 0;
        continue;
      }

      // Bullet: • - *
      if (line.startsWith('• ') ||
          line.startsWith('- ') ||
          line.startsWith('* ')) {
        final content = line.substring(2).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.70),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _inlineSpan(content, textColor)),
            ],
          ),
        ));
        orderedIndex = 0;
        continue;
      }

      // Numbered list: 1. 2. …
      final numMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(line);
      if (numMatch != null) {
        orderedIndex++;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text('$orderedIndex.',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.70))),
              ),
              const SizedBox(width: 4),
              Expanded(child: _inlineSpan(numMatch.group(1)!, textColor)),
            ],
          ),
        ));
        continue;
      }

      // Horizontal rule: --- or ___
      if (line == '---' || line == '___' || line == '***') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(
              color: textColor.withValues(alpha: 0.30), thickness: 1),
        ));
        orderedIndex = 0;
        continue;
      }

      // Plain text
      orderedIndex = 0;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: _inlineSpan(line, textColor),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _inlineSpan(String text, Color color) {
    // Parse **bold**, *italic*, `code`
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    int last = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: color.withValues(alpha: 0.18),
            fontSize: 12,
          ),
        ));
      }
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: GoogleFonts.inter(fontSize: 14, color: color, height: 1.55),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Animated typing dots
// ════════════════════════════════════════════════════════════════════════════════

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _anims = List.generate(3, (i) {
      final start = i * 0.18;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, math.min(start + 0.45, 1.0),
              curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = _anims[i].value;
          return Container(
            margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
            width: 7,
            height: 7 + v * 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55 + v * 0.45),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
