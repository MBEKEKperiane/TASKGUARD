import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/burnout/models/burnout_result.dart';
import '../../features/mood/models/mood_entry.dart';
import '../../features/reschedule/models/reschedule_plan.dart';
import '../../features/reschedule/providers/reschedule_provider.dart';
import '../../features/schedule/models/schedule_block.dart';
import '../../theme/app_colors.dart';

class RescheduleScreen extends ConsumerStatefulWidget {
  const RescheduleScreen({super.key});

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rescheduleProvider.notifier).analyze();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rescheduleProvider);

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: _buildAppBar(context, state),
      body: state.isLoading
          ? const _LoadingView()
          : state.plan == null
              ? const _EmptyView()
              : state.allHandled
                  ? const _AllHandledView()
                  : _ScheduleBody(state: state),
    );
  }

  AppBar _buildAppBar(BuildContext context, RescheduleState state) {
    final count = state.visibleSuggestions.length;
    return AppBar(
      backgroundColor: _bg(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: _text1(context), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Text('Emergency Reschedule',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text1(context))),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: AppColors.primary, size: 22),
          tooltip: 'Refresh',
          onPressed: state.isLoading
              ? null
              : () => ref.read(rescheduleProvider.notifier).reset(),
        ),
      ],
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _ScheduleBody extends ConsumerWidget {
  final RescheduleState state;

  const _ScheduleBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = state.plan!;
    final suggestions = state.visibleSuggestions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _AlertHeader(plan: plan),
        const SizedBox(height: 20),
        _sectionLabel(context, 'Overdue Tasks'),
        const SizedBox(height: 10),
        ...suggestions.map((s) => _TaskSuggestionCard(suggestion: s)),
        if (suggestions.length > 1) ...[
          const SizedBox(height: 8),
          _DismissAllButton(
            onTap: () => ref.read(rescheduleProvider.notifier).dismissAll(),
          ),
        ],
        const SizedBox(height: 24),
        _sectionLabel(context, 'Alternative Schedules'),
        const SizedBox(height: 4),
        Text(
          'Pick a mode that fits your energy today',
          style: GoogleFonts.inter(fontSize: 12, color: _text2(context)),
        ),
        const SizedBox(height: 12),
        ...plan.alternatives.map((alt) => _AlternativeCard(alt: alt)),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _text1(context)));
}

// ── Alert header ──────────────────────────────────────────────────────────────

class _AlertHeader extends StatelessWidget {
  final ReschedulePlan plan;

  const _AlertHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    final burnoutColor = plan.workloadLevel.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.overdueCount} task${plan.overdueCount > 1 ? "s" : ""} need rescheduling',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _text1(context)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: burnoutColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Workload: ${plan.workloadLevel.label}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _text2(context)),
                    ),
                    if (plan.mood != null) ...[
                      Text('  ·  ',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _text2(context))),
                      Text(
                        plan.mood!.emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task suggestion card ───────────────────────────────────────────────────────

class _TaskSuggestionCard extends ConsumerWidget {
  final TaskRescheduleSuggestion suggestion;

  const _TaskSuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = suggestion.overdueTask;
    final severityColor = info.severity.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity strip
                Container(
                  width: 4,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text1(context))),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _PriorityChip(priority: info.priority),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityColor
                                  .withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(info.overdueByLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: severityColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Dismiss
                GestureDetector(
                  onTap: () => ref
                      .read(rescheduleProvider.notifier)
                      .dismiss(info.id),
                  child:
                      Icon(Icons.close_rounded, size: 18, color: _hint(context)),
                ),
              ],
            ),
          ),
          // Urgency note
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(suggestion.urgencyNote,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _text2(context),
                    fontStyle: FontStyle.italic)),
          ),
          // Slot suggestions
          if (suggestion.hasSlots) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Suggested slots',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _hint(context))),
            ),
            ...suggestion.suggestedSlots.map((slot) => _SlotChip(
                  slot: slot,
                  taskId: info.id,
                )),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('No available slots today — try again tomorrow',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _hint(context))),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Slot chip ─────────────────────────────────────────────────────────────────

class _SlotChip extends ConsumerStatefulWidget {
  final TimeSlot slot;
  final String taskId;

  const _SlotChip({required this.slot, required this.taskId});

  @override
  ConsumerState<_SlotChip> createState() => _SlotChipState();
}

class _SlotChipState extends ConsumerState<_SlotChip> {
  bool _applying = false;

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    final ok = await ref
        .read(rescheduleProvider.notifier)
        .applySlot(widget.taskId, widget.slot);
    if (mounted) {
      setState(() => _applying = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Rescheduled to ${widget.slot.timeRange}'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to apply — try again'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _surface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _divider(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.timeRange,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _text1(context))),
                  Text(slot.reason,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _text2(context))),
                ],
              ),
            ),
            // Fit score dots
            _FitDots(score: slot.fitScore),
            const SizedBox(width: 10),
            _applying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : GestureDetector(
                    onTap: _apply,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Apply',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _FitDots extends StatelessWidget {
  final double score;

  const _FitDots({required this.score});

  @override
  Widget build(BuildContext context) {
    final filled = (score * 3).round().clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled
                ? AppColors.secondary
                : _divider(context),
          ),
        );
      }),
    );
  }
}

// ── Dismiss all ───────────────────────────────────────────────────────────────

class _DismissAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DismissAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Text('Dismiss all',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: _hint(context),
                decoration: TextDecoration.underline,
                decorationColor: _hint(context))),
      ),
    );
  }
}

// ── Alternative schedule card ─────────────────────────────────────────────────

class _AlternativeCard extends StatefulWidget {
  final AlternativeSchedule alt;

  const _AlternativeCard({required this.alt});

  @override
  State<_AlternativeCard> createState() => _AlternativeCardState();
}

class _AlternativeCardState extends State<_AlternativeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.alt.mode;
    final color = mode.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        children: [
          // Header (always visible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(mode.icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mode.label,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _text1(context))),
                        Text(mode.description,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: _text2(context))),
                      ],
                    ),
                  ),
                  // Stats
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${widget.alt.taskCount} tasks',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _text1(context))),
                      Text(widget.alt.totalWorkLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _text2(context))),
                    ],
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        color: _hint(context), size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Expanded blocks preview
          if (_expanded) _BlocksPreview(alt: widget.alt),
        ],
      ),
    );
  }
}

class _BlocksPreview extends StatelessWidget {
  final AlternativeSchedule alt;

  const _BlocksPreview({required this.alt});

  @override
  Widget build(BuildContext context) {
    if (alt.blocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Text('No slots available in the remaining day',
            style: GoogleFonts.inter(fontSize: 12, color: _hint(context))),
      );
    }
    return Column(
      children: [
        Divider(height: 1, color: _divider(context)),
        ...alt.blocks
            .where((b) => b.type != ScheduleBlockType.buffer)
            .map((b) => _MiniBlockRow(block: b)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MiniBlockRow extends StatelessWidget {
  final ScheduleBlock block;

  const _MiniBlockRow({required this.block});

  @override
  Widget build(BuildContext context) {
    final color = block.blockColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(block.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: block.isTask ? FontWeight.w500 : FontWeight.w400,
                    color: block.isTask ? _text1(context) : _text2(context))),
          ),
          Text(block.timeRange,
              style:
                  GoogleFonts.inter(fontSize: 10, color: _hint(context))),
        ],
      ),
    );
  }
}

// ── Priority chip ─────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  final String priority;

  const _PriorityChip({required this.priority});

  Color get _color => switch (priority) {
        'URGENT' => const Color(0xFFDC2626),
        'HIGH' => AppColors.priorityHigh,
        'MEDIUM' => AppColors.priorityMedium,
        _ => AppColors.priorityLow,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(priority,
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _color)),
    );
  }
}

// ── State views ───────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text('Scanning your tasks…',
              style: GoogleFonts.inter(fontSize: 13, color: _text2(context))),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: _hint(context)),
          const SizedBox(height: 12),
          Text('Nothing to analyse yet',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _text1(context))),
          const SizedBox(height: 4),
          Text('Tap ↻ to scan for overdue tasks',
              style:
                  GoogleFonts.inter(fontSize: 13, color: _text2(context))),
        ],
      ),
    );
  }
}

class _AllHandledView extends StatelessWidget {
  const _AllHandledView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 56, color: AppColors.secondary),
          const SizedBox(height: 12),
          Text('All caught up!',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _text1(context))),
          const SizedBox(height: 4),
          Text('All overdue tasks have been rescheduled.',
              style:
                  GoogleFonts.inter(fontSize: 13, color: _text2(context))),
        ],
      ),
    );
  }
}

// ── Theme helpers (avoids extension import) ───────────────────────────────────

Color _bg(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
}

Color _card(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF1E293B) : Colors.white;
}

Color _surface(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
}

Color _text1(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
}

Color _text2(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
}

Color _hint(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
}

Color _divider(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
}
