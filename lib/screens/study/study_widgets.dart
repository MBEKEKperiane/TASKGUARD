import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/study/models/study_models.dart';
import '../../features/study/providers/study_provider.dart';
import '../../theme/app_colors.dart';

// ── Shared form helpers ────────────────────────────────────────────────────────

Widget studyLabel(String text, Color color) => Text(text,
    style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600, color: color));

Widget studyField({
  required TextEditingController controller,
  required String hint,
  required Color surface,
  required Color divider,
  required Color text1,
  required Color text2,
  int maxLines = 1,
  Color accentColor = AppColors.primary,
}) =>
    TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: text1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: text2),
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accentColor)),
      ),
    );

// ── SubjectPicker ──────────────────────────────────────────────────────────────

class SubjectPicker extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>?> onSelect;
  final Future<void> Function(Map<String, dynamic>) onAdd;
  final Color divider;
  final Color text1;
  final Color text2;

  const SubjectPicker({
    super.key,
    required this.subjects,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.divider,
    required this.text1,
    required this.text2,
  });

  @override
  State<SubjectPicker> createState() => _SubjectPickerState();
}

class _SubjectPickerState extends State<SubjectPicker> {
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String pickedColor = kSubjectColorPalette[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('New Subject',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, color: widget.text1)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14, color: widget.text1),
                decoration: InputDecoration(
                  hintText: 'Subject name',
                  hintStyle:
                      GoogleFonts.inter(fontSize: 13, color: widget.text2),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: kSubjectColorPalette.map((hex) {
                  final sel = pickedColor == hex;
                  return GestureDetector(
                    onTap: () => setDialog(() => pickedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: subjectColor(hex),
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: subjectColor(hex)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style:
                      GoogleFonts.inter(color: widget.text2, fontSize: 14)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final subj = <String, dynamic>{
                  'id': 'subj_${DateTime.now().millisecondsSinceEpoch}',
                  'name': name,
                  'colorHex': pickedColor,
                };
                Navigator.pop(ctx);
                await widget.onAdd(subj);
              },
              child: Text('Add',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAddDialog,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('New',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
          ...widget.subjects.map((s) {
            final isSelected = widget.selected != null &&
                subjectId(widget.selected!) == subjectId(s);
            final color = subjectColor(subjectColorHex(s));
            return GestureDetector(
              onTap: () => widget.onSelect(isSelected ? null : s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? color : widget.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(subjectName(s),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? color : widget.text2)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── DifficultyPicker ───────────────────────────────────────────────────────────

class DifficultyPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final Color divider;
  final Color text1;

  const DifficultyPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.divider,
    required this.text1,
  });

  @override
  Widget build(BuildContext context) {
    const levels = [kDifficultyEasy, kDifficultyMedium, kDifficultyHard];
    return Row(
      children: levels.map((d) {
        final selected = value == d;
        final color = difficultyColor(d);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: d == kDifficultyHard ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? color : divider),
              ),
              child: Center(
                child: Text(difficultyLabel(d),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? color : text1)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Convenience wrapper so sheets can call addSubject inline ───────────────────

Future<void> addSubjectViaProvider(
    WidgetRef ref, Map<String, dynamic> data) async {
  await ref.read(studyProvider.notifier).addSubject(data);
}
