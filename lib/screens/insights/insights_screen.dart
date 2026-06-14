import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/insights/models/insights_data.dart';
import '../../features/insights/providers/insights_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../settings/settings_screen.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(insightsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(insightsProvider);

    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppHeader(
        onSettingsTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      body: data.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(insightsProvider.notifier).load(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(children: [
                      Text('Productivity Insights',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: context.colText1)),
                      const SizedBox(width: 10),
                      _badge(context),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      _headline(data),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.colText2,
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // ── Daily score ───────────────────────────────────────
                    _card(
                      context,
                      child: Row(
                        children: [
                          // Circular gauge
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value:
                                      (data.dailyScore / 100).clamp(0, 1),
                                  strokeWidth: 8,
                                  backgroundColor: context.colPrimaryC,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary),
                                  strokeCap: StrokeCap.round,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data.dailyScore.toInt().toString(),
                                      style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary),
                                    ),
                                    Text('%',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: context.colText2)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Score',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: context.colText1)),
                                const SizedBox(height: 4),
                                Text(_scoreLabel(data.dailyScore),
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary)),
                                const SizedBox(height: 8),
                                Text(
                                  'Weekly avg: ${data.weeklyScore.toInt()}%',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: context.colText2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Stats row ─────────────────────────────────────────
                    Row(children: [
                      Expanded(
                          child: _statCard(context,
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Completed',
                              value: data.completedTasks.toString(),
                              color: AppColors.secondary)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(context,
                              icon: Icons.cancel_outlined,
                              label: 'Missed',
                              value: data.missedTasks.toString(),
                              color: AppColors.error)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _statCard(context,
                              icon: Icons.timer_outlined,
                              label: 'Focus Sessions',
                              value: data.focusSessions.toString(),
                              color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(context,
                              icon: Icons.pie_chart_outline_rounded,
                              label: 'Completion',
                              value:
                                  '${data.completionRate.toInt()}%',
                              color: AppColors.warning)),
                    ]),
                    const SizedBox(height: 14),

                    // ── Weekly performance chart ───────────────────────────
                    _card(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Weekly Performance',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: context.colText1)),
                                  Text('Daily productivity scores',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: context.colText2)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${data.weeklyScore.toInt()}%',
                                  style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary),
                                ),
                                Text('avg this week',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: context.colText2)),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 120,
                            child: _weeklyChart(context, data),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Focus Score section ────────────────────────────────
                    _card(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Focus Score',
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: context.colText1)),
                                  Text('Average deep work quality',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: context.colText2)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data.avgFocusScore.toInt().toString(),
                                  style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: context.colText1),
                                ),
                                Text(
                                    _scoreLabel(data.avgFocusScore),
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: context.colText2)),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // Bar chart: focus sessions per day (last 7 days)
                          SizedBox(
                            height: 100,
                            child: _focusSessionsChart(context, data),
                          ),
                          const SizedBox(height: 14),

                          // Stats row inside card
                          Row(children: [
                            _focusStat(context,
                                label: 'Total Sessions',
                                value: _allTimeSessions(data).toString()),
                            _vDivider(),
                            _focusStat(context,
                                label: 'Focus Time Today',
                                value: _formatMins(
                                    data.totalFocusMinutes)),
                            _vDivider(),
                            _focusStat(context,
                                label: 'Avg Score',
                                value:
                                    '${data.avgFocusScore.toInt()}%'),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Chart builders ─────────────────────────────────────────────────────────

  Widget _weeklyChart(BuildContext context, InsightsData data) {
    if (data.weeklyBreakdown.isEmpty) return _emptyChart(context);

    final spots = data.weeklyBreakdown
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();

    final days = data.weeklyBreakdown
        .map((d) => _dayLabel(d.date))
        .toList();

    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
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
              return Text(days[i],
                  style: GoogleFonts.inter(
                      fontSize: 10, color: context.colHint));
            },
          ),
        ),
      ),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3,
              color: AppColors.primary,
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

  Widget _focusSessionsChart(BuildContext context, InsightsData data) {
    if (data.weeklyBreakdown.isEmpty) return _emptyChart(context);

    final maxSessions = data.weeklyBreakdown
        .map((d) => d.focusSessions)
        .fold(0, (a, b) => a > b ? a : b);
    final maxY = (maxSessions < 3 ? 4 : maxSessions + 1).toDouble();

    final groups = data.weeklyBreakdown.asMap().entries.map((e) {
      final isToday = e.key == 6;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.focusSessions.toDouble(),
            color: isToday ? AppColors.primary : context.colPrimaryC,
            width: 20,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    final days =
        data.weeklyBreakdown.map((d) => _dayLabel(d.date)).toList();

    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: false),
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
              return Text(days[i],
                  style: GoogleFonts.inter(
                      fontSize: 10, color: context.colHint));
            },
          ),
        ),
      ),
      barGroups: groups,
    ));
  }

  Widget _emptyChart(BuildContext context) => Center(
        child: Text('No data yet — complete tasks or start a focus session.',
            style:
                GoogleFonts.inter(fontSize: 12, color: context.colHint),
            textAlign: TextAlign.center),
      );

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _badge(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: context.colPrimaryC,
            borderRadius: BorderRadius.circular(12)),
        child: Text('Live',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );

  Widget _card(BuildContext context, {required Widget child}) => Container(
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

  Widget _statCard(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
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

  Widget _focusStat(BuildContext context,
      {required String label, required String value}) {
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

  Widget _vDivider() => Container(
      width: 1, height: 32, color: context.colDivider);

  // ── Pure helpers ───────────────────────────────────────────────────────────

  String _headline(InsightsData data) {
    if (data.completedTasks == 0 && data.focusSessions == 0) {
      return 'Start completing tasks or a focus session to see your stats.';
    }
    if (data.dailyScore >= 80) {
      return 'Excellent day — you\'re in the top performance zone.';
    }
    if (data.dailyScore >= 50) {
      return 'Good progress today. Keep the momentum going.';
    }
    return 'You\'re building the habit. Every session counts.';
  }

  String _scoreLabel(double score) {
    if (score >= 90) return 'Elite';
    if (score >= 75) return 'Strong';
    if (score >= 55) return 'Building';
    if (score >= 30) return 'Getting Started';
    return 'Needs Effort';
  }

  String _dayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  String _formatMins(int mins) {
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  int _allTimeSessions(InsightsData data) =>
      data.weeklyBreakdown.fold(0, (sum, d) => sum + d.focusSessions);
}
