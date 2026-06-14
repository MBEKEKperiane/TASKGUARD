import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/schedule/models/generated_schedule.dart';
import '../../features/schedule/models/schedule_block.dart';
import '../../features/schedule/providers/schedule_provider.dart';
import '../../features/mood/models/mood_entry.dart';
import '../../theme/app_colors.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleProvider.notifier).generate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppBar(
        backgroundColor: context.colBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.colText1, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('AI Schedule',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 22),
            tooltip: 'Regenerate',
            onPressed: state.isLoading
                ? null
                : () => ref.read(scheduleProvider.notifier).generate(),
          ),
        ],
      ),
      body: Column(
        children: [
          _SettingsCard(state: state),
          Expanded(
            child: state.isLoading
                ? const _LoadingView()
                : state.schedule == null
                    ? const _EmptyView()
                    : _ScheduleBody(schedule: state.schedule!),
          ),
        ],
      ),
    );
  }
}

// ── Settings card (start/end hour pickers + generate button) ──────────────────

class _SettingsCard extends ConsumerWidget {
  final ScheduleState state;

  const _SettingsCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(scheduleProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colDivider),
      ),
      child: Row(
        children: [
          _HourPicker(
            label: 'Start',
            value: state.startHour,
            onChanged: notifier.setStartHour,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppColors.primary),
          ),
          _HourPicker(
            label: 'End',
            value: state.endHour,
            onChanged: notifier.setEndHour,
          ),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded,
                size: 15, color: Colors.white),
            label: Text('Generate',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            onPressed: state.isLoading
                ? null
                : () => ref.read(scheduleProvider.notifier).generate(),
          ),
        ],
      ),
    );
  }
}

class _HourPicker extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _HourPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  String _fmt(int h) {
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: context.colHint)),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () async {
            final hours = List.generate(17, (i) => i + 6); // 6–22
            await showModalBottomSheet<int>(
              context: context,
              builder: (_) => _HourSheet(hours: hours, selected: value),
            ).then((v) {
              if (v != null) onChanged(v);
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.colSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colDivider),
            ),
            child: Text(_fmt(value),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colText1)),
          ),
        ),
      ],
    );
  }
}

class _HourSheet extends StatelessWidget {
  final List<int> hours;
  final int selected;

  const _HourSheet({required this.hours, required this.selected});

  String _fmt(int h) {
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ...hours.map(
            (h) => ListTile(
              title: Text(_fmt(h),
                  style: GoogleFonts.inter(
                      fontWeight:
                          h == selected ? FontWeight.w700 : FontWeight.w400,
                      color: h == selected
                          ? AppColors.primary
                          : context.colText1)),
              trailing: h == selected
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 18)
                  : null,
              onTap: () => Navigator.pop(context, h),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Body (timeline + summary) ──────────────────────────────────────────────────

class _ScheduleBody extends StatelessWidget {
  final GeneratedSchedule schedule;

  const _ScheduleBody({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SummaryCard(schedule: schedule),
        const SizedBox(height: 20),
        if (schedule.isEmpty) ...[
          const _EmptyScheduleCard(),
        ] else ...[
          _sectionHeader(context, 'Today\'s Schedule'),
          const SizedBox(height: 12),
          ...List.generate(
            schedule.blocks.length,
            (i) => _BlockTile(block: schedule.blocks[i]),
          ),
        ],
        if (schedule.hasDeferredTasks) ...[
          const SizedBox(height: 24),
          _sectionHeader(context, 'Deferred Tasks'),
          const SizedBox(height: 12),
          ...schedule.deferredTasks
              .map((t) => _DeferredTaskTile(task: t)),
        ],
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.colText1));
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final GeneratedSchedule schedule;

  const _SummaryCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final moodLabel = schedule.mood?.label ?? 'Not set';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.scoreLabel,
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                        '${schedule.scheduledTaskCount} tasks · ${schedule.workloadLabel}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85))),
                  ],
                ),
              ),
              _ScorePill(score: schedule.scheduleScore),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                  icon: Icons.work_outline_rounded,
                  value: schedule.totalWorkLabel,
                  label: 'Focus'),
              const SizedBox(width: 16),
              _Stat(
                  icon: Icons.coffee_rounded,
                  value: schedule.breakBlocks.length.toString(),
                  label: 'Breaks'),
              const SizedBox(width: 16),
              _Stat(
                  icon: Icons.sentiment_satisfied_rounded,
                  value: moodLabel,
                  label: 'Mood'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double score;

  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('${score.toInt()}',
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }
}

// ── Block tile (vertical timeline) ────────────────────────────────────────────

class _BlockTile extends StatelessWidget {
  final ScheduleBlock block;

  const _BlockTile({required this.block});

  @override
  Widget build(BuildContext context) {
    final isTask = block.isTask;
    final color = block.blockColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  _shortTime(block.startTime),
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: context.colHint),
                ),
                const Expanded(
                  child: VerticalDivider(width: 1, thickness: 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Block card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: isTask
                    ? color.withOpacity(context.isDark ? 0.18 : 0.10)
                    : context.colSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTask
                      ? color.withOpacity(0.35)
                      : context.colDivider,
                ),
              ),
              child: Row(
                children: [
                  // Color indicator strip
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(block.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.colText1)),
                            ),
                            Text(block.durationLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: context.colHint)),
                          ],
                        ),
                        if (block.note != null) ...[
                          const SizedBox(height: 2),
                          Text(block.note!,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: context.colText2)),
                        ],
                        const SizedBox(height: 2),
                        Text(block.timeRange,
                            style: GoogleFonts.inter(
                                fontSize: 10, color: context.colHint)),
                      ],
                    ),
                  ),
                  if (isTask) ...[
                    const SizedBox(width: 8),
                    _PriorityDot(priority: block.priority),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m\n$p';
  }
}

class _PriorityDot extends StatelessWidget {
  final String priority;

  const _PriorityDot({required this.priority});

  Color get _color => switch (priority) {
        'URGENT' => const Color(0xFFDC2626),
        'HIGH' => AppColors.priorityHigh,
        'MEDIUM' => AppColors.priorityMedium,
        _ => AppColors.priorityLow,
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: priority,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Deferred task tile ─────────────────────────────────────────────────────────

class _DeferredTaskTile extends StatelessWidget {
  final Map<String, dynamic> task;

  const _DeferredTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final title = task['title'] as String? ?? 'Task';
    final priority =
        (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
    final dur = (task['estimatedDuration'] as num?)?.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colDivider),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: context.colHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.colText1)),
          ),
          if (dur != null)
            Text('${dur}m',
                style: GoogleFonts.inter(
                    fontSize: 11, color: context.colHint)),
          const SizedBox(width: 8),
          _PriorityChip(priority: priority),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
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

// ── Empty / loading states ────────────────────────────────────────────────────

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
          Text('Building your schedule…',
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.colText2)),
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
          Icon(Icons.calendar_today_rounded,
              size: 48, color: context.colHint),
          const SizedBox(height: 12),
          Text('No schedule yet',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colText1)),
          const SizedBox(height: 4),
          Text('Tap Generate to build your day',
              style: GoogleFonts.inter(
                  fontSize: 13, color: context.colText2)),
        ],
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.secondary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_rounded,
              color: AppColors.secondary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All clear!',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.colText1)),
                Text('No pending tasks for today.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: context.colText2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
