import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/reports/models/daily_report.dart';
import '../../features/reports/models/weekly_report.dart';
import '../../features/reports/providers/reports_provider.dart';
import '../../theme/app_colors.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);

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
        title: Text('Reports',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.colText1)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: context.colIcon, size: 22),
            onPressed: () => ref.read(reportsProvider.notifier).loadAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.colText2,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: const [Tab(text: 'Daily'), Tab(text: 'Weekly')],
        ),
      ),
      body: state.isLoading && state.dailyReport == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _DailyTab(state: state),
                _WeeklyTab(state: state),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTab extends ConsumerWidget {
  final ReportsState state;
  const _DailyTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = state.dailyReport;
    final isToday = _isToday(state.selectedDate);

    return RefreshIndicator(
      onRefresh: () => ref.read(reportsProvider.notifier).loadAll(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date navigator ───────────────────────────────────────────────
            _DateNavigator(
              label: isToday
                  ? 'Today'
                  : _formatDate(state.selectedDate),
              canGoForward: !isToday,
              onBack: () => ref.read(reportsProvider.notifier).shiftDay(-1),
              onForward: () => ref.read(reportsProvider.notifier).shiftDay(1),
            ),
            const SizedBox(height: 20),

            if (report == null) ...[
              const _EmptyState(),
            ] else ...[
              // ── Score hero ─────────────────────────────────────────────────
              _ScoreHero(score: report.productivityScore, label: report.scoreLabel),
              const SizedBox(height: 16),

              // ── 4 stat cards ───────────────────────────────────────────────
              Row(children: [
                Expanded(
                    child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completed',
                  value: report.completedTasks.toString(),
                  color: AppColors.secondary,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  icon: Icons.cancel_outlined,
                  label: 'Missed',
                  value: report.missedTasks.toString(),
                  color: AppColors.error,
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Focus Time',
                  value: report.focusTimeLabel,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  icon: Icons.insights_rounded,
                  label: 'Productivity',
                  value: '${report.productivityScore.toInt()}%',
                  color: AppColors.warning,
                )),
              ]),
              const SizedBox(height: 16),

              // ── Task breakdown donut ───────────────────────────────────────
              if (report.totalTasks > 0)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle('Task Breakdown',
                          sub: '${report.completionRate.toInt()}% completion rate'),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: _TaskDonut(report: report),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend(
                              color: AppColors.secondary,
                              label:
                                  '${report.completedTasks} Completed'),
                          const SizedBox(width: 20),
                          _Legend(
                              color: AppColors.error,
                              label: '${report.missedTasks} Missed'),
                          if (report.totalTasks -
                                  report.completedTasks -
                                  report.missedTasks >
                              0) ...[
                            const SizedBox(width: 20),
                            _Legend(
                                color: context.colDivider,
                                label:
                                    '${report.totalTasks - report.completedTasks - report.missedTasks} Pending'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              if (report.totalTasks > 0) const SizedBox(height: 16),

              // ── Focus sessions bar ─────────────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle('Focus Sessions',
                        sub: '${report.focusSessions} sessions · avg score ${report.avgFocusScore.toInt()}%'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (report.avgFocusScore / 100).clamp(0, 1),
                          backgroundColor: context.colPrimaryC,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _MiniStat(
                          label: 'Sessions',
                          value: report.focusSessions.toString()),
                      _Divider(),
                      _MiniStat(
                          label: 'Focus Time',
                          value: report.focusTimeLabel),
                      _Divider(),
                      _MiniStat(
                          label: 'Avg Score',
                          value: '${report.avgFocusScore.toInt()}%'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Tab
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  final ReportsState state;
  const _WeeklyTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = state.weekReport;
    final isCurrentWeek =
        _sameWeek(state.selectedWeekStart, DateTime.now());

    return RefreshIndicator(
      onRefresh: () => ref.read(reportsProvider.notifier).loadAll(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Week navigator ───────────────────────────────────────────────
            _DateNavigator(
              label: isCurrentWeek
                  ? 'This Week'
                  : _formatWeekRange(state.selectedWeekStart),
              canGoForward: !isCurrentWeek,
              onBack: () =>
                  ref.read(reportsProvider.notifier).shiftWeek(-1),
              onForward: () =>
                  ref.read(reportsProvider.notifier).shiftWeek(1),
            ),
            const SizedBox(height: 20),

            if (report == null) ...[
              const _EmptyState(),
            ] else ...[
              // ── Weekly score hero ──────────────────────────────────────────
              _ScoreHero(
                  score: report.avgProductivityScore,
                  label: 'Weekly Average'),
              const SizedBox(height: 16),

              // ── 4 stat cards ───────────────────────────────────────────────
              Row(children: [
                Expanded(
                    child: _StatCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completed',
                  value: report.totalCompleted.toString(),
                  color: AppColors.secondary,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  icon: Icons.cancel_outlined,
                  label: 'Missed',
                  value: report.totalMissed.toString(),
                  color: AppColors.error,
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Focus Time',
                  value: report.focusTimeLabel,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                  icon: Icons.insights_rounded,
                  label: 'Completion',
                  value: '${report.completionRate.toInt()}%',
                  color: AppColors.warning,
                )),
              ]),
              const SizedBox(height: 16),

              // ── Daily score line chart ─────────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: _CardTitle('Daily Scores',
                            sub: 'Productivity score per day'),
                      ),
                      Text(
                        '${report.avgProductivityScore.toInt()}%',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 130,
                      child: report.hasData
                          ? _ScoreLineChart(report: report)
                          : _emptyChart(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Daily focus hours bar chart ────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardTitle('Focus Hours',
                        sub: 'Daily deep work time this week'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: report.hasData
                          ? _FocusHoursBarChart(report: report)
                          : _emptyChart(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Best day highlight ─────────────────────────────────────────
              if (report.bestDay != null && report.hasData)
                _BestDayCard(day: report.bestDay!),

              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Charts
// ─────────────────────────────────────────────────────────────────────────────

class _TaskDonut extends StatelessWidget {
  final DailyReport report;
  const _TaskDonut({required this.report});

  @override
  Widget build(BuildContext context) {
    final pending = report.totalTasks - report.completedTasks - report.missedTasks;
    final sections = <PieChartSectionData>[
      if (report.completedTasks > 0)
        PieChartSectionData(
          value: report.completedTasks.toDouble(),
          color: AppColors.secondary,
          radius: 50,
          showTitle: false,
        ),
      if (report.missedTasks > 0)
        PieChartSectionData(
          value: report.missedTasks.toDouble(),
          color: AppColors.error,
          radius: 50,
          showTitle: false,
        ),
      if (pending > 0)
        PieChartSectionData(
          value: pending.toDouble(),
          color: context.colDivider,
          radius: 50,
          showTitle: false,
        ),
    ];

    if (sections.isEmpty) return const SizedBox.shrink();

    return PieChart(PieChartData(
      sections: sections,
      centerSpaceRadius: 52,
      sectionsSpace: 3,
      startDegreeOffset: -90,
    ));
  }
}

class _ScoreLineChart extends StatelessWidget {
  final WeeklyReport report;
  const _ScoreLineChart({required this.report});

  @override
  Widget build(BuildContext context) {
    final days = report.dailyBreakdown;
    final spots = days
        .asMap()
        .entries
        .map((e) => FlSpot(
            e.key.toDouble(), e.value.productivityScore))
        .toList();

    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: 100,
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= days.length) return const SizedBox();
              return Text(_dayLabel(days[i].date),
                  style: GoogleFonts.inter(
                      fontSize: 10, color: context.colHint));
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: spot.y >= 75
                  ? AppColors.secondary
                  : spot.y >= 50
                      ? AppColors.warning
                      : AppColors.primary,
              strokeWidth: 0,
              strokeColor: Colors.transparent,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }
}

class _FocusHoursBarChart extends StatelessWidget {
  final WeeklyReport report;
  const _FocusHoursBarChart({required this.report});

  @override
  Widget build(BuildContext context) {
    final days = report.dailyBreakdown;
    final maxH = days.fold(0.0, (m, d) => d.focusHours > m ? d.focusHours : m);
    final maxY = maxH < 1 ? 2.0 : (maxH + 0.5).ceilToDouble();
    final groups = days.asMap().entries.map((e) {
      final d = e.value;
      final isToday = _isToday(d.date);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: d.focusHours,
            color: isToday ? AppColors.primary : context.colPrimaryC,
            width: 22,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final h = rod.toY;
            final mins = (h * 60).round();
            final label = mins < 60 ? '${mins}m' : '${h.toStringAsFixed(1)}h';
            return BarTooltipItem(label,
                GoogleFonts.inter(fontSize: 11, color: Colors.white));
          },
        ),
      ),
      maxY: maxY,
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 18,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= days.length) return const SizedBox();
              return Text(_dayLabel(days[i].date),
                  style: GoogleFonts.inter(
                      fontSize: 10, color: context.colHint));
            },
          ),
        ),
      ),
      barGroups: groups,
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  final double score;
  final String label;
  const _ScoreHero({required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? AppColors.secondary
        : score >= 50
            ? AppColors.warning
            : score >= 25
                ? AppColors.primary
                : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (score / 100).clamp(0, 1),
                  strokeWidth: 7,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${score.toInt()}%',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colText2)),
                const SizedBox(height: 4),
                Text(_scoreLabel(score),
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.colText1)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0, 1),
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestDayCard extends StatelessWidget {
  final DailyReport day;
  const _BestDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded,
                color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Day',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 0.4)),
                Text(
                  '${_fullDayLabel(day.date)} — ${day.productivityScore.toInt()}% · ${day.completedTasks} tasks done',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.colText1,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final String label;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  const _DateNavigator(
      {required this.label,
      required this.canGoForward,
      required this.onBack,
      required this.onForward});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.chevron_left_rounded,
              color: context.colIcon, size: 28),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        Expanded(
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colText1)),
        ),
        IconButton(
          onPressed: canGoForward ? onForward : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: canGoForward ? context.colIcon : context.colDivider,
            size: 28,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  final String? sub;
  const _CardTitle(this.title, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        if (sub != null)
          Text(sub!,
              style: GoogleFonts.inter(
                  fontSize: 12, color: context.colText2)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.colText1)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: context.colText2)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        const SizedBox(height: 2),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 10, color: context.colText2),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: context.colDivider);
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style:
              GoogleFonts.inter(fontSize: 11, color: context.colText2)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                color: context.colHint, size: 48),
            const SizedBox(height: 12),
            Text('No data for this period',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colText2)),
            const SizedBox(height: 6),
            Text('Complete tasks or start a focus session to see reports.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: context.colHint),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _emptyChart(BuildContext context) => Center(
      child: Text('No focus data yet',
          style: GoogleFonts.inter(
              fontSize: 12, color: context.colHint)),
    );

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

bool _sameWeek(DateTime a, DateTime b) {
  final aStart = a.subtract(Duration(days: a.weekday - 1));
  final bStart = b.subtract(Duration(days: b.weekday - 1));
  return aStart.year == bStart.year &&
      aStart.month == bStart.month &&
      aStart.day == bStart.day;
}

String _scoreLabel(double score) {
  if (score >= 90) return 'Elite';
  if (score >= 75) return 'Strong';
  if (score >= 55) return 'Building';
  if (score >= 30) return 'Getting Started';
  if (score > 0) return 'Needs Effort';
  return 'No Activity';
}

String _dayLabel(DateTime date) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[date.weekday - 1];
}

String _fullDayLabel(DateTime date) {
  const labels = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  return labels[date.weekday - 1];
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}';
}

String _formatWeekRange(DateTime start) {
  final end = start.add(const Duration(days: 6));
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  if (start.month == end.month) {
    return '${months[start.month - 1]} ${start.day}–${end.day}';
  }
  return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
}
