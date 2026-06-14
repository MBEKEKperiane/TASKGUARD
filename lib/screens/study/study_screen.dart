import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../features/study/models/study_models.dart';
import '../../features/study/providers/study_provider.dart';
import '../../theme/app_colors.dart';
import 'add_assignment_sheet.dart';
import 'add_exam_sheet.dart';

// ── Theme helpers (context-free, passed as parameters) ─────────────────────────
Color _bg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF0F172A)
    : const Color(0xFFF8FAFC);
Color _card(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF1E293B)
    : Colors.white;
Color _surface(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);
Color _text1(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFFF1F5F9)
    : const Color(0xFF0F172A);
Color _text2(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF94A3B8)
    : const Color(0xFF475569);
Color _hint(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF475569)
    : const Color(0xFF94A3B8);
Color _divider(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

const _kStudyAccent = Color(0xFF6366F1);

// ── Screen ─────────────────────────────────────────────────────────────────────

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyProvider);

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _text1(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Study Mode',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        actions: [
          if (state.urgentCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${state.urgentCount} urgent',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626))),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kStudyAccent,
          unselectedLabelColor: _hint(context),
          indicatorColor: _kStudyAccent,
          indicatorWeight: 2,
          labelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              child: _TabLabel(
                'Assignments',
                count: state.pendingAssignments.length,
              ),
            ),
            Tab(
              child: _TabLabel(
                'Exams',
                count: state.upcomingExams.length,
              ),
            ),
            const Tab(text: 'Study Plan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AssignmentsTab(
            onAdd: () => showAddAssignmentSheet(context),
          ),
          _ExamsTab(
            onAdd: () => showAddExamSheet(context),
          ),
          const _StudyPlanTab(),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;

  const _TabLabel(this.label, {this.count = 0});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 5),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _kStudyAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kStudyAccent)),
        ),
      ],
    );
  }
}

// ── Assignments Tab ────────────────────────────────────────────────────────────

class _AssignmentsTab extends ConsumerWidget {
  final VoidCallback onAdd;
  const _AssignmentsTab({required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(studyProvider).assignments;
    all.sort((a, b) => assignDaysUntilDue(a).compareTo(assignDaysUntilDue(b)));

    return Scaffold(
      backgroundColor: _bg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Assignment',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: all.isEmpty
          ? _EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No assignments yet',
              subtitle: 'Add your first assignment to start tracking',
              color: AppColors.primary,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AssignmentCard(assignment: all[i]),
            ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final Map<String, dynamic> assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = assignIsCompleted(assignment);
    final urgencyColor = assignUrgencyColor(assignment);
    final subjectCol = subjectColor(assignSubjectColor(assignment));
    final difficulty = assignDifficulty(assignment);

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: Opacity(
        opacity: isCompleted ? 0.55 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: subjectCol, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject chip
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: subjectCol.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(assignSubjectName(assignment),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: subjectCol)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: difficultyColor(difficulty)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(difficultyLabel(difficulty),
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: difficultyColor(difficulty))),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        assignTitle(assignment),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _text1(context),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: urgencyColor),
                        const SizedBox(width: 4),
                        Text(assignDueLabel(assignment),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: urgencyColor)),
                        const SizedBox(width: 12),
                        Icon(Icons.timer_outlined,
                            size: 12, color: _hint(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${assignEstimatedHours(assignment).toStringAsFixed(1)}h',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _text2(context)),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => ref
                      .read(studyProvider.notifier)
                      .toggleAssignment(assignId(assignment)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF22C55E)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF22C55E)
                            : _hint(context),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Assignment?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('This will also clear any scheduled study sessions.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(studyProvider.notifier)
                  .deleteAssignment(assignId(assignment));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Exams Tab ──────────────────────────────────────────────────────────────────

class _ExamsTab extends ConsumerWidget {
  final VoidCallback onAdd;
  const _ExamsTab({required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(studyProvider).upcomingExams;

    return Scaffold(
      backgroundColor: _bg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        backgroundColor: _kStudyAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Exam',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: all.isEmpty
          ? _EmptyState(
              icon: Icons.school_outlined,
              title: 'No exams added',
              subtitle: 'Add an upcoming exam to plan preparation',
              color: _kStudyAccent,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ExamCard(exam: all[i]),
            ),
    );
  }
}

class _ExamCard extends ConsumerWidget {
  final Map<String, dynamic> exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyColor = examUrgencyColor(exam);
    final subjectCol = subjectColor(examSubjectColor(exam));
    final topics = examTopics(exam);
    final daysUntil = examDaysUntil(exam);
    final prepHours = examPrepHours(exam);

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: urgencyColor, width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subjectCol.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(examSubjectName(exam),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: subjectCol)),
              ),
              const Spacer(),
              // Countdown pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    daysUntil <= 1
                        ? Icons.warning_amber_rounded
                        : Icons.timer_outlined,
                    size: 12,
                    color: urgencyColor,
                  ),
                  const SizedBox(width: 4),
                  Text(examCountdownLabel(exam),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: urgencyColor)),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            Text(examTitle(exam),
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
            if (examLocation(exam).isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 12, color: _hint(context)),
                const SizedBox(width: 4),
                Text(examLocation(exam),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: _text2(context))),
              ]),
            ],
            const SizedBox(height: 10),
            // Prep hours bar
            Row(children: [
              Icon(Icons.menu_book_rounded,
                  size: 12, color: _hint(context)),
              const SizedBox(width: 4),
              Text('${prepHours.toStringAsFixed(1)}h prep needed',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _text2(context))),
              const Spacer(),
              Text(difficultyLabel(examDifficulty(exam)),
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: difficultyColor(examDifficulty(exam)))),
            ]),
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: topics
                    .take(5)
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _surface(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _divider(context)),
                          ),
                          child: Text(t,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: _text2(context))),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Exam?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Preparation sessions for this exam will be removed.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(studyProvider.notifier)
                  .deleteExam(examId(exam));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Study Plan Tab ─────────────────────────────────────────────────────────────

class _StudyPlanTab extends ConsumerWidget {
  const _StudyPlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyProvider);

    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: _kStudyAccent, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text('Building your study plan…',
                style: GoogleFonts.inter(
                    fontSize: 14, color: _text2(context))),
          ],
        ),
      );
    }

    if (state.studyPlan == null) {
      return _NoPlanState(
        hasData: state.assignments.isNotEmpty || state.exams.isNotEmpty,
        onGenerate: () =>
            ref.read(studyProvider.notifier).generatePlan(),
      );
    }

    final plan = state.studyPlan!;
    final sessions = planSessions(plan);
    final score = planReadinessScore(plan);
    final totalHours = planTotalStudyHours(plan);
    final urgent = planUrgentAssignments(plan);
    final upcomingExams = planUpcomingExams(plan);

    // Group sessions by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in sessions) {
      (grouped[sessionScheduledFor(s)] ??= []).add(s);
    }
    final days = grouped.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Readiness card
              _ReadinessCard(
                  score: score, totalHours: totalHours),

              // Urgent assignments strip
              if (urgent.isNotEmpty)
                _UrgentStrip(items: urgent),

              // Upcoming exams strip
              if (upcomingExams.isNotEmpty)
                _UpcomingExamsStrip(items: upcomingExams),

              // Regenerate button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(studyProvider.notifier).generatePlan(),
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: _kStudyAccent),
                  label: Text('Regenerate Plan',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kStudyAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kStudyAccent),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No study sessions needed — you\'re all caught up!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: _text2(context)),
                  ),
                ),
            ],
          ),
        ),

        // Daily session groups
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final day = days[i];
              final daySessions = grouped[day]!;
              return _DayGroup(
                  dayKey: day, sessions: daySessions);
            },
            childCount: days.length,
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

class _NoPlanState extends StatelessWidget {
  final bool hasData;
  final VoidCallback onGenerate;

  const _NoPlanState({required this.hasData, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kStudyAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: _kStudyAccent, size: 32),
            ),
            const SizedBox(height: 20),
            Text('No Study Plan Yet',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
            const SizedBox(height: 10),
            Text(
              hasData
                  ? 'Generate a personalised study schedule based on your assignments and exams'
                  : 'Add assignments and exams first, then generate your plan',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: _text2(context)),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: hasData ? onGenerate : null,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text('Generate Study Plan',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor:
                    hasData ? _kStudyAccent : const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final int score;
  final double totalHours;

  const _ReadinessCard({required this.score, required this.totalHours});

  @override
  Widget build(BuildContext context) {
    final color = readinessColor(score);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        // Score circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            color: color.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Text('$score',
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(readinessLabel(score),
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 4),
              Text('Readiness score',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _text2(context))),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: _text2(context)),
                const SizedBox(width: 4),
                Text(
                  '${totalHours.toStringAsFixed(1)}h planned',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _text1(context)),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _UrgentStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _UrgentStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded,
                size: 14, color: Color(0xFFDC2626)),
            const SizedBox(width: 6),
            Text('Urgent',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626))),
          ]),
          const SizedBox(height: 8),
          ...items.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Expanded(
                    child: Text(a['title'] as String? ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _text1(context))),
                  ),
                  Text(a['dueIn'] as String? ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626))),
                ]),
              )),
        ],
      ),
    );
  }
}

class _UpcomingExamsStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _UpcomingExamsStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final e = items[i];
          final days = e['daysUntil'] as int? ?? 0;
          final color = days <= 1
              ? const Color(0xFFDC2626)
              : days <= 3
                  ? const Color(0xFFF97316)
                  : _kStudyAccent;
          final subColor =
              subjectColor(e['subjectColorHex'] as String? ?? '6366F1');

          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: subColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    e['subjectName'] as String? ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: subColor),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  e['title'] as String? ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _text1(context)),
                ),
                Text(
                  days == 0
                      ? 'Today!'
                      : days == 1
                          ? 'Tomorrow'
                          : 'In ${days}d',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayGroup extends ConsumerWidget {
  final String dayKey;
  final List<Map<String, dynamic>> sessions;

  const _DayGroup({required this.dayKey, required this.sessions});

  String _dayLabel() {
    try {
      final d = DateTime.parse(dayKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(d.year, d.month, d.day);
      final diff = target.difference(today).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      return DateFormat('EEE, MMM d').format(d);
    } catch (_) {
      return dayKey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _dayLabel();
    final isToday = label == 'Today';
    final completedCount =
        sessions.where((s) => sessionIsCompleted(s)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isToday
                    ? _kStudyAccent.withValues(alpha: 0.12)
                    : _surface(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isToday ? _kStudyAccent : _text2(context))),
            ),
            const SizedBox(width: 8),
            Text(
              '${sessions.length} session${sessions.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: _hint(context)),
            ),
            if (completedCount > 0) ...[
              const SizedBox(width: 6),
              Text('· $completedCount done',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF22C55E))),
            ],
          ]),
          const SizedBox(height: 8),
          ...sessions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionTile(session: s),
              )),
        ],
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final Map<String, dynamic> session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = sessionIsCompleted(session);
    final subColor = subjectColor(sessionSubjectColor(session));
    final isExam = sessionTargetType(session) == kTargetTypeExam;

    return GestureDetector(
      onTap: isCompleted
          ? null
          : () => ref
              .read(studyProvider.notifier)
              .completeSession(sessionId(session)),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isCompleted ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: subColor, width: 3)),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      sessionTechniqueEmoji(session),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        sessionTargetTitle(session),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _text1(context),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isExam) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kStudyAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Exam',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _kStudyAccent)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: _hint(context)),
                    const SizedBox(width: 4),
                    Text(sessionTimeRange(session),
                        style: GoogleFonts.inter(
                            fontSize: 11, color: _text2(context))),
                    const SizedBox(width: 10),
                    Text('· ${sessionDurationMins(session)}min',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: _hint(context))),
                    const SizedBox(width: 10),
                    Text(sessionTechniqueLabel(session),
                        style: GoogleFonts.inter(
                            fontSize: 11, color: _hint(context))),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF22C55E)
                      : _hint(context),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, color: _text2(context))),
          ],
        ),
      ),
    );
  }
}
