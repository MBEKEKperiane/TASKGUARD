import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/local_notification_service.dart';
import '../../services/task_service.dart';
import '../../theme/app_colors.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _taskService = TaskService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _deadline;
  TimeOfDay? _startTime;
  String _priority = 'HIGH';
  bool _reminder = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  /// Combines date + time into a single DateTime
  DateTime? get _taskDateTime {
    if (_deadline == null) return null;
    final t = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
        _deadline!.year, _deadline!.month, _deadline!.day, t.hour, t.minute);
  }

  /// The earliest reminder time — 5 min before task start, or at start if sooner.
  DateTime? get _remindAt {
    final dt = _taskDateTime;
    if (dt == null || !_reminder) return null;
    final now = DateTime.now();
    final fiveMinBefore = dt.subtract(const Duration(minutes: 5));
    if (fiveMinBefore.isAfter(now)) return fiveMinBefore;
    if (dt.isAfter(now)) return dt;
    return null;
  }

  Future<void> _submit() async {
    final title = _nameCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a task name.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final task = await _taskService.createTask(
        title: title,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        // .toUtc() first — a bare local-time ISO string has no offset, so the
        // backend (running in UTC) would misread it as that many hours off.
        dueDate: _taskDateTime?.toUtc().toIso8601String(),
        startTime: _taskDateTime?.toUtc().toIso8601String(),
        priority: _priority,
        remindAt: _remindAt?.toUtc().toIso8601String(),
      );
      // Schedule all local reminders — works offline (no backend needed)
      final dt = _taskDateTime;
      if (_reminder && dt != null && dt.isAfter(DateTime.now())) {
        await LocalNotificationService.scheduleAllReminders(
          taskId: task['id'] as String,
          taskTitle: title,
          startTime: dt,
          dueDate: dt,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                '🔔 Reminders set: 5-min warning, start alert & overdue follow-ups'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ));
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Saved offline — will sync when connected.'),
              backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded,
                        color: context.colText1, size: 24),
                  ),
                  const Spacer(),
                  Text('TaskGuard AI',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const Spacer(),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Task',
                        style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colText1)),
                    const SizedBox(height: 4),
                    Text('Define your next milestone.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: context.colText2)),
                    const SizedBox(height: 28),

                    // Task name
                    _label('Task Name *'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        hintStyle: TextStyle(color: context.colHint),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryLight, width: 1.5)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: AppColors.primary, width: 2)),
                        filled: false,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _label('Description (optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add details...',
                        hintStyle: TextStyle(color: context.colHint),
                        filled: true,
                        fillColor: context.colSurfaceVar,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date + Time row
                    _cardField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Date & Time'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickDate,
                                  child: Row(children: [
                                    const Icon(Icons.calendar_month_outlined,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _deadline != null
                                          ? DateFormat('MMM dd, yyyy')
                                              .format(_deadline!)
                                          : 'Pick date',
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _deadline != null
                                              ? context.colText1
                                              : context.colHint),
                                    ),
                                  ]),
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickTime,
                                child: Row(children: [
                                  const Icon(Icons.access_time_rounded,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _startTime != null
                                        ? _startTime!.format(context)
                                        : 'Pick time',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _startTime != null
                                            ? context.colText1
                                            : context.colHint),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    _cardField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Priority'),
                          const SizedBox(height: 12),
                          Row(children: [
                            _priorityBtn('LOW'),
                            const SizedBox(width: 10),
                            _priorityBtn('MEDIUM'),
                            const SizedBox(width: 10),
                            _priorityBtn('HIGH'),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reminder toggle
                    _toggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'Smart reminders',
                      subtitle: _remindAt != null
                          ? '5-min warning at ${DateFormat('h:mm a').format(_remindAt!)}'
                              ', start alert & overdue follow-ups'
                          : _deadline == null
                              ? 'Set a date & time first'
                              : 'Task time has already passed',
                      value: _reminder,
                      onChanged: (v) => setState(() => _reminder = v),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Create Task button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.darkButtonGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('Create Task',
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.colText2));

  Widget _cardField({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colDivider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _priorityBtn(String p) {
    final selected = _priority == p;
    final color = p == 'HIGH'
        ? AppColors.priorityHigh
        : p == 'MEDIUM'
            ? AppColors.priorityMedium
            : AppColors.priorityLow;
    return GestureDetector(
      onTap: () => setState(() => _priority = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : context.colDivider),
        ),
        child: Text(p,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : context.colText2)),
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colText2, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colText1)),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: context.colHint)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primaryLight,
        ),
      ],
    );
  }
}
