import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/local_notification_service.dart';
import '../services/task_service.dart';
import '../services/voice_nlp_parser.dart';
import '../theme/app_colors.dart';

enum _Phase { listening, processing, review }

class VoiceTaskSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const VoiceTaskSheet({super.key, this.onCreated});

  @override
  State<VoiceTaskSheet> createState() => _VoiceTaskSheetState();
}

class _VoiceTaskSheetState extends State<VoiceTaskSheet>
    with TickerProviderStateMixin {
  // ── Speech ──────────────────────────────────────────────────────────────────
  final _speech = SpeechToText();
  String _transcript = '';
  double _soundLevel = 0;
  bool _speechAvailable = false;
  String? _speechError;

  // ── Phase ───────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.listening;

  // ── Animations ──────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // ── Review state ─────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String _priority = 'MEDIUM';
  bool _submitting = false;

  // ── Services ─────────────────────────────────────────────────────────────────
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSpeech());
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: _onStatus,
      onError: _onError,
    );
    if (!mounted) return;
    if (_speechAvailable) {
      _startListening();
    } else {
      setState(() =>
          _speechError = 'Speech recognition is not available on this device.');
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _transcript = '';
      _soundLevel = 0;
      _speechError = null;
      _phase = _Phase.listening;
    });
    await _speech.listen(
      onResult: _onResult,
      onSoundLevelChange: (level) {
        if (mounted) {
          setState(() => _soundLevel = ((level + 2) / 12).clamp(0.0, 1.0));
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 2),
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => _transcript = result.recognizedWords);
    if (result.finalResult) _processTranscript();
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if ((status == 'done' || status == 'notListening') &&
        _transcript.isNotEmpty &&
        _phase == _Phase.listening) {
      _processTranscript();
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    if (_transcript.isEmpty) {
      setState(
          () => _speechError = 'Could not understand. Please try again.');
    }
  }

  void _stopAndProcess() {
    _speech.stop();
    if (_transcript.isNotEmpty) {
      _processTranscript();
    }
  }

  void _processTranscript() {
    if (_transcript.isEmpty || _phase != _Phase.listening) return;
    setState(() => _phase = _Phase.processing);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final draft = VoiceNlpParser.parse(_transcript);
      setState(() {
        _titleCtrl.text = draft.title;
        _date = draft.date;
        _time = draft.time;
        _priority = draft.priority;
        _phase = _Phase.review;
      });
    });
  }

  Future<void> _createTask() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _submitting = true);

    final dt = _combinedDateTime();
    try {
      final task = await _taskService.createTask(
        title: title,
        dueDate: dt?.toIso8601String(),
        startTime: dt?.toIso8601String(),
        priority: _priority,
        remindAt: _remindAt(dt)?.toIso8601String(),
      );
      if (dt != null && dt.isAfter(DateTime.now())) {
        await LocalNotificationService.scheduleAllReminders(
          taskId: task['id'] as String,
          taskTitle: title,
          startTime: dt,
          dueDate: dt,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Task created: "$title"',
                    style: GoogleFonts.inter(color: Colors.white))),
          ]),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        Navigator.pop(context);
        widget.onCreated?.call();
      }
    }
  }

  DateTime? _combinedDateTime() {
    if (_date == null) return null;
    final t = _time ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);
  }

  DateTime? _remindAt(DateTime? dt) {
    if (dt == null) return null;
    final five = dt.subtract(const Duration(minutes: 5));
    if (five.isAfter(DateTime.now())) return five;
    if (dt.isAfter(DateTime.now())) return dt;
    return null;
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        top: 16,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          if (_speechError != null)
            _buildErrorView()
          else
            switch (_phase) {
              _Phase.listening => _buildListeningView(),
              _Phase.processing => _buildProcessingView(),
              _Phase.review => _buildReviewView(),
            },
        ],
      ),
    );
  }

  // ── Listening view ──────────────────────────────────────────────────────────

  Widget _buildListeningView() {
    return Column(
      children: [
        Text('Listening…',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        const SizedBox(height: 6),
        Text('Speak your task clearly',
            style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
        const SizedBox(height: 32),

        // ── Pulsing mic ──────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _waveCtrl]),
          builder: (context, _) {
            return SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Transform.scale(
                    scale: _pulseScale.value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary
                            .withValues(alpha: _pulseOpacity.value),
                      ),
                    ),
                  ),
                  // Sound level ring
                  Container(
                    width: 88 + _soundLevel * 16,
                    height: 88 + _soundLevel * 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary
                          .withValues(alpha: 0.08 + _soundLevel * 0.12),
                    ),
                  ),
                  // Mic button
                  GestureDetector(
                    onTap: _stopAndProcess,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, Color(0xFFFF6EB4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.mic_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // ── Waveform bars ────────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (context, _) {
            final t = _waveCtrl.value * 2 * pi;
            final bars = [
              4 + _soundLevel * 24 * (0.4 + 0.6 * ((sin(t * 2.1) + 1) / 2)),
              4 + _soundLevel * 32 * (0.4 + 0.6 * ((sin(t * 1.7 + 1.2) + 1) / 2)),
              4 + _soundLevel * 40 * (0.4 + 0.6 * ((sin(t * 2.3 + 2.4) + 1) / 2)),
              4 + _soundLevel * 32 * (0.4 + 0.6 * ((sin(t * 1.9 + 3.6) + 1) / 2)),
              4 + _soundLevel * 24 * (0.4 + 0.6 * ((sin(t * 2.5 + 4.8) + 1) / 2)),
            ];
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: bars.asMap().entries.map((e) {
                return Container(
                  width: 5,
                  height: e.value,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.4 + _soundLevel * 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),

        // ── Live transcript ──────────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _transcript.isEmpty
              ? Text('Try: "Remind me to submit the report tomorrow at 3pm"',
                  key: const ValueKey('hint'),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.colHint,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center)
              : Text(_transcript,
                  key: const ValueKey('transcript'),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.colText1,
                      height: 1.5),
                  textAlign: TextAlign.center),
        ),
        const SizedBox(height: 28),

        // ── Actions ──────────────────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colText2,
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: context.colDivider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23)),
              ),
              child: Text('Cancel',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _transcript.isEmpty ? null : _stopAndProcess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                disabledBackgroundColor: context.colDivider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23)),
              ),
              icon: const Icon(Icons.stop_circle_rounded, size: 18),
              label: Text('Done',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Tap the mic or "Done" when finished',
            style: GoogleFonts.inter(fontSize: 11, color: context.colHint),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Processing view ─────────────────────────────────────────────────────────

  Widget _buildProcessingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text('Analyzing your task…',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colText1)),
          const SizedBox(height: 6),
          Text('Extracting date, time and priority',
              style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
        ],
      ),
    );
  }

  // ── Review view ─────────────────────────────────────────────────────────────

  Widget _buildReviewView() {
    final priorityColor = _priority == 'URGENT' || _priority == 'HIGH'
        ? AppColors.priorityHigh
        : _priority == 'LOW'
            ? AppColors.priorityLow
            : AppColors.priorityMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.secondary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Task recognized',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.colText1)),
          ),
          GestureDetector(
            onTap: () => _startListening(),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Review and edit before creating',
            style: GoogleFonts.inter(fontSize: 12, color: context.colText2)),
        const SizedBox(height: 20),

        // ── Transcript chip ──────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.colSurfaceVar,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.mic_none_rounded, size: 14, color: context.colHint),
            const SizedBox(width: 6),
            Expanded(
              child: Text('"$_transcript"',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.colHint,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Title field ──────────────────────────────────────────────────────
        _sectionLabel('Task Title'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'What needs to be done?',
            hintStyle: TextStyle(color: context.colHint),
            filled: true,
            fillColor: context.colCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Date & Time row ──────────────────────────────────────────────────
        _sectionLabel('Date & Time'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: _chipButton(
              icon: Icons.calendar_month_outlined,
              label: _date != null
                  ? DateFormat('EEE, MMM d').format(_date!)
                  : 'No date',
              hasValue: _date != null,
              onTap: _pickDate,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _chipButton(
              icon: Icons.access_time_rounded,
              label: _time != null
                  ? _formatTime(_time!)
                  : 'No time',
              hasValue: _time != null,
              onTap: _pickTime,
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // ── Priority selector ─────────────────────────────────────────────────
        _sectionLabel('Priority'),
        const SizedBox(height: 8),
        Row(children: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].map((p) {
          final selected = _priority == p;
          final c = p == 'URGENT' || p == 'HIGH'
              ? AppColors.priorityHigh
              : p == 'LOW'
                  ? AppColors.priorityLow
                  : AppColors.priorityMedium;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _priority = p),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? c.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: selected ? c : context.colDivider),
                ),
                alignment: Alignment.center,
                child: Text(p == 'URGENT' ? '🔴' : p == 'HIGH' ? '🟠' : p == 'LOW' ? '🟢' : '🟡',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _priority,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: priorityColor),
          ),
        ),
        const SizedBox(height: 24),

        // ── Create button ─────────────────────────────────────────────────────
        GestureDetector(
          onTap: _submitting ? null : _createTask,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: _submitting
                  ? null
                  : AppColors.darkButtonGradient,
              color: _submitting ? context.colDivider : null,
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_task_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Create Task',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── Error view ──────────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.mic_off_rounded, size: 52, color: context.colHint),
          const SizedBox(height: 16),
          Text('Speech Unavailable',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colText1)),
          const SizedBox(height: 8),
          Text(_speechError ?? 'Speech recognition is not available.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.colText2),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initSpeech,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.colText2)),
          ),
        ],
      ),
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  // ── Small helpers ────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.colText2,
          letterSpacing: 0.3));

  Widget _chipButton({
    required IconData icon,
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.colCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasValue
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : context.colDivider),
        ),
        child: Row(children: [
          Icon(icon,
              size: 16,
              color: hasValue ? AppColors.primary : context.colHint),
          const SizedBox(width: 7),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? AppColors.primary : context.colHint),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

/// Shows the voice task creation sheet. [onCreated] is called after task is saved.
void showVoiceTaskSheet(BuildContext context, {VoidCallback? onCreated}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: VoiceTaskSheet(onCreated: onCreated),
    ),
  );
}
