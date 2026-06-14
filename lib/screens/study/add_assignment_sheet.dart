import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/study/models/study_models.dart';
import '../../features/study/providers/study_provider.dart';
import '../../theme/app_colors.dart';
import 'study_widgets.dart';

Future<void> showAddAssignmentSheet(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssignmentSheet(),
    );

class AddAssignmentSheet extends ConsumerStatefulWidget {
  const AddAssignmentSheet({super.key});

  @override
  ConsumerState<AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends ConsumerState<AddAssignmentSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _dueDate;
  double _estimatedHours = 2;
  String _difficulty = kDifficultyMedium;
  Map<String, dynamic>? _selectedSubject;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Color _bg() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E293B)
      : Colors.white;
  Color _text1() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF1F5F9)
      : const Color(0xFF0F172A);
  Color _text2() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF94A3B8)
      : const Color(0xFF475569);
  Color _surface() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF0F172A)
      : const Color(0xFFF8FAFC);
  Color _divider() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF334155)
      : const Color(0xFFE2E8F0);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _dueDate == null) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'id': 'asgn_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'subjectName': _selectedSubject != null
          ? subjectName(_selectedSubject!)
          : 'General',
      'subjectColorHex': _selectedSubject != null
          ? subjectColorHex(_selectedSubject!)
          : '6366F1',
      'dueDate': _dueDate!.toIso8601String(),
      'estimatedHours': _estimatedHours,
      'difficulty': _difficulty,
      'notes': _notesCtrl.text.trim(),
      'isCompleted': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await ref.read(studyProvider.notifier).addAssignment(data);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(studyProvider).subjects;
    final bg = _bg();
    final text1 = _text1();
    final text2 = _text2();
    final surface = _surface();
    final divider = _divider();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('New Assignment',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: text1)),
              const SizedBox(height: 20),

              studyLabel('Title', text2),
              const SizedBox(height: 6),
              studyField(
                  controller: _titleCtrl,
                  hint: 'e.g. Chapter 5 Problem Set',
                  surface: surface,
                  divider: divider,
                  text1: text1,
                  text2: text2),
              const SizedBox(height: 16),

              studyLabel('Subject', text2),
              const SizedBox(height: 8),
              SubjectPicker(
                subjects: subjects,
                selected: _selectedSubject,
                onSelect: (s) => setState(() => _selectedSubject = s),
                onAdd: (s) async {
                  await ref.read(studyProvider.notifier).addSubject(s);
                  if (mounted) setState(() => _selectedSubject = s);
                },
                divider: divider,
                text1: text1,
                text2: text2,
              ),
              const SizedBox(height: 16),

              studyLabel('Due Date', text2),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: divider),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: text2),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null
                          ? 'Pick a due date'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _dueDate == null ? text2 : text1),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              studyLabel(
                  'Estimated Study Hours: ${_estimatedHours.toStringAsFixed(1)}h',
                  text2),
              Slider(
                value: _estimatedHours,
                min: 0.5,
                max: 12,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                onChanged: (v) => setState(() => _estimatedHours = v),
              ),
              const SizedBox(height: 12),

              studyLabel('Difficulty', text2),
              const SizedBox(height: 8),
              DifficultyPicker(
                value: _difficulty,
                onChanged: (d) => setState(() => _difficulty = d),
                divider: divider,
                text1: text1,
              ),
              const SizedBox(height: 16),

              studyLabel('Notes (optional)', text2),
              const SizedBox(height: 6),
              studyField(
                  controller: _notesCtrl,
                  hint: 'Any details…',
                  maxLines: 3,
                  surface: surface,
                  divider: divider,
                  text1: text1,
                  text2: text2),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        (_titleCtrl.text.isNotEmpty && _dueDate != null)
                            ? AppColors.primary
                            : divider,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_titleCtrl.text.isNotEmpty &&
                          _dueDate != null &&
                          !_saving)
                      ? _save
                      : null,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Add Assignment',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
