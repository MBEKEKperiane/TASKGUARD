import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/study/models/study_models.dart';
import '../../features/study/providers/study_provider.dart';
import 'study_widgets.dart';

Future<void> showAddExamSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExamSheet(),
    );

class AddExamSheet extends ConsumerStatefulWidget {
  const AddExamSheet({super.key});

  @override
  ConsumerState<AddExamSheet> createState() => _AddExamSheetState();
}

const _kStudyAccent = Color(0xFF6366F1); // indigo for study/exam theme

class _AddExamSheetState extends ConsumerState<AddExamSheet> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  DateTime? _examDate;
  TimeOfDay? _examTime;
  double _prepHours = 5;
  String _difficulty = kDifficultyMedium;
  Map<String, dynamic>? _selectedSubject;
  final List<String> _topics = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _topicCtrl.dispose();
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
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: _kStudyAccent),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _examDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null && mounted) setState(() => _examTime = t);
  }

  void _addTopic() {
    final t = _topicCtrl.text.trim();
    if (t.isEmpty || _topics.contains(t)) return;
    setState(() {
      _topics.add(t);
      _topicCtrl.clear();
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _examDate == null) return;
    setState(() => _saving = true);

    final fullDate = _examTime != null
        ? DateTime(
            _examDate!.year,
            _examDate!.month,
            _examDate!.day,
            _examTime!.hour,
            _examTime!.minute,
          )
        : _examDate!;

    final data = <String, dynamic>{
      'id': 'exam_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'subjectName': _selectedSubject != null
          ? subjectName(_selectedSubject!)
          : 'General',
      'subjectColorHex': _selectedSubject != null
          ? subjectColorHex(_selectedSubject!)
          : '6366F1',
      'date': fullDate.toIso8601String(),
      'location': _locationCtrl.text.trim(),
      'prepHours': _prepHours,
      'difficulty': _difficulty,
      'topics': _topics,
      'status': kExamStatusUpcoming,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await ref.read(studyProvider.notifier).addExam(data);
    if (mounted) Navigator.pop(context);
  }

  String _dateLabel() {
    if (_examDate == null) return 'Pick exam date';
    String label =
        '${_examDate!.day}/${_examDate!.month}/${_examDate!.year}';
    if (_examTime != null) {
      final suffix = _examTime!.hour >= 12 ? 'PM' : 'AM';
      final h12 =
          _examTime!.hour % 12 == 0 ? 12 : _examTime!.hour % 12;
      label +=
          ' at $h12:${_examTime!.minute.toString().padLeft(2, '0')} $suffix';
    }
    return label;
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
              Text('New Exam',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: text1)),
              const SizedBox(height: 20),

              studyLabel('Title', text2),
              const SizedBox(height: 6),
              studyField(
                  controller: _titleCtrl,
                  hint: 'e.g. Final Exam — Calculus',
                  surface: surface,
                  divider: divider,
                  text1: text1,
                  text2: text2,
                  accentColor: _kStudyAccent),
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

              studyLabel('Exam Date & Time', text2),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: GestureDetector(
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_dateLabel(),
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color:
                                      _examDate == null ? text2 : text1)),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: divider),
                    ),
                    child: Icon(Icons.access_time_rounded,
                        size: 18,
                        color: _examTime != null ? _kStudyAccent : text2),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              studyLabel('Location (optional)', text2),
              const SizedBox(height: 6),
              studyField(
                  controller: _locationCtrl,
                  hint: 'e.g. Hall B, Room 204',
                  surface: surface,
                  divider: divider,
                  text1: text1,
                  text2: text2,
                  accentColor: _kStudyAccent),
              const SizedBox(height: 16),

              studyLabel(
                  'Preparation Hours: ${_prepHours.toStringAsFixed(1)}h',
                  text2),
              Slider(
                value: _prepHours,
                min: 1,
                max: 40,
                divisions: 39,
                activeColor: _kStudyAccent,
                inactiveColor: _kStudyAccent.withValues(alpha: 0.2),
                onChanged: (v) => setState(() => _prepHours = v),
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

              studyLabel('Topics to Cover', text2),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: studyField(
                      controller: _topicCtrl,
                      hint: 'Add a topic…',
                      surface: surface,
                      divider: divider,
                      text1: text1,
                      text2: text2,
                      accentColor: _kStudyAccent),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTopic,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kStudyAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ]),
              if (_topics.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _topics
                      .map((t) => Chip(
                            label: Text(t,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: text1)),
                            deleteIcon: Icon(Icons.close_rounded,
                                size: 14, color: text2),
                            onDeleted: () =>
                                setState(() => _topics.remove(t)),
                            backgroundColor:
                                _kStudyAccent.withValues(alpha: 0.1),
                            side: BorderSide(color: divider),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        (_titleCtrl.text.isNotEmpty && _examDate != null)
                            ? _kStudyAccent
                            : divider,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_titleCtrl.text.isNotEmpty &&
                          _examDate != null &&
                          !_saving)
                      ? _save
                      : null,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Add Exam',
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
