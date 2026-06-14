import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/mood/models/mood_entry.dart';
import '../features/mood/providers/mood_provider.dart';
import '../theme/app_colors.dart';

class MoodPickerSheet extends ConsumerStatefulWidget {
  /// Called after the user confirms a mood selection.
  final void Function(MoodType mood)? onSelected;

  /// Optional title override; defaults to "How are you feeling?"
  final String? title;

  const MoodPickerSheet({super.key, this.onSelected, this.title});

  @override
  ConsumerState<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends ConsumerState<MoodPickerSheet> {
  MoodType? _selected;
  bool _saving = false;

  Future<void> _confirm() async {
    final mood = _selected;
    if (mood == null || _saving) return;
    setState(() => _saving = true);
    await ref.read(moodProvider.notifier).setMood(mood);
    if (mounted) {
      Navigator.pop(context);
      widget.onSelected?.call(mood);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMood = ref.watch(moodProvider).current;
    // Pre-select the user's existing mood if none chosen yet in this session.
    final effective = _selected ?? currentMood;

    return Container(
      decoration: BoxDecoration(
        color: context.colSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.title ?? 'How are you feeling?',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.colText1),
              ),
              const SizedBox(height: 6),
              Text(
                'Your mood shapes your task recommendations.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: context.colText2),
              ),
              const SizedBox(height: 24),

              // ── 2×2 mood grid ─────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: MoodType.values
                    .map((m) => _MoodCard(
                          mood: m,
                          selected: effective == m,
                          onTap: () => setState(() => _selected = m),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              // ── Confirm CTA ────────────────────────────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: effective != null ? 1.0 : 0.4,
                child: GestureDetector(
                  onTap: effective != null ? _confirm : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: effective != null
                          ? AppColors.primaryGradient
                          : LinearGradient(colors: [
                              context.colDivider,
                              context.colDivider,
                            ]),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: effective != null
                          ? [
                              BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            effective != null
                                ? 'Save — ${effective.emoji} ${effective.label}'
                                : 'Pick a mood',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: effective != null
                                    ? Colors.white
                                    : context.colHint),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual mood card ─────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  final MoodType mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodCard({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = mood.color;
    final bg = context.isDark ? mood.darkBgColor : mood.bgColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : context.colCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c : context.colDivider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: c.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          children: [
            // Emoji in a tinted circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? c.withValues(alpha: 0.18) : bg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mood.label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? c : context.colText1)),
                  const SizedBox(height: 2),
                  Text(mood.description,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: context.colText2,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: c, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Convenience function — shows the sheet and returns the selected mood.
Future<MoodType?> showMoodPicker(
  BuildContext context, {
  String? title,
  void Function(MoodType)? onSelected,
}) {
  return showModalBottomSheet<MoodType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MoodPickerSheet(title: title, onSelected: onSelected),
  );
}
