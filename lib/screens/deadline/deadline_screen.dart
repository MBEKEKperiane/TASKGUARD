import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/deadline/models/deadline_models.dart';
import '../../services/deadline_predictor.dart';
import '../../theme/app_colors.dart';

// ── Theme helpers ──────────────────────────────────────────────────────────────

Color _bg(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

Color _card(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : Colors.white;

Color _text1(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);

Color _text2(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

Color _hint(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

Color _divider(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

// ════════════════════════════════════════════════════════════════════════════════
// Deadline Screen
// ════════════════════════════════════════════════════════════════════════════════

class DeadlineScreen extends StatefulWidget {
  const DeadlineScreen({super.key});

  @override
  State<DeadlineScreen> createState() => _DeadlineScreenState();
}

class _DeadlineScreenState extends State<DeadlineScreen> {
  DeadlineReport? _report;
  int? _expandedIndex;
  String _filter = 'all'; // 'all' | 'warning'

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  void _analyze() {
    setState(() {
      _report = DeadlinePredictor.analyze();
      _expandedIndex = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _text1(context), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deadline Intelligence',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _text1(context))),
            if (report != null)
              Text(_updatedLabel(report.generatedAt),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _hint(context))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 22),
            tooltip: 'Refresh predictions',
            onPressed: _analyze,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: report == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : report.predictions.isEmpty
              ? _noDueDatesState()
              : _body(report),
    );
  }

  // ── No due dates state ────────────────────────────────────────────────────────

  Widget _noDueDatesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No deadlines to predict',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
            const SizedBox(height: 8),
            Text(
              'Add due dates to your tasks and I\'ll predict whether you\'re on track to complete them.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: _text2(context), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main body ─────────────────────────────────────────────────────────────────

  Widget _body(DeadlineReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary counters
          _summaryRow(report),
          const SizedBox(height: 16),

          // All-clear state
          if (report.allClear) ...[
            _allClearCard(),
            const SizedBox(height: 16),
          ],

          // Velocity / history card
          _velocityCard(report),
          const SizedBox(height: 20),

          // Filter + list header
          _listHeader(report),
          const SizedBox(height: 10),

          // Prediction cards
          ..._filteredPredictions(report).asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _predictionCard(entry.value, entry.key),
                ),
              ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────────────────────────

  Widget _summaryRow(DeadlineReport report) {
    return Row(
      children: [
        _summaryBox(report.onTrackCount, RiskLevel.onTrack),
        const SizedBox(width: 8),
        _summaryBox(report.atRiskCount, RiskLevel.atRisk),
        const SizedBox(width: 8),
        _summaryBox(report.criticalCount, RiskLevel.critical),
        const SizedBox(width: 8),
        _summaryBox(report.overdueCount, RiskLevel.overdue),
      ],
    );
  }

  Widget _summaryBox(int count, RiskLevel level) {
    final c = level.color;
    final isActive = count > 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? c.withValues(alpha: 0.10)
              : _card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? c.withValues(alpha: 0.35) : _divider(context),
          ),
        ),
        child: Column(
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text('$count',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isActive ? c : _hint(context))),
            Text(level.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isActive ? c : _hint(context),
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }

  // ── All-clear card ────────────────────────────────────────────────────────────

  Widget _allClearCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.30)),
      ),
      child: Row(children: [
        const Text('🎉', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('All tasks look healthy!',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary)),
              const SizedBox(height: 4),
              Text('Every deadline is on track. Keep up the great momentum.',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _text2(context),
                      height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Velocity card ─────────────────────────────────────────────────────────────

  Widget _velocityCard(DeadlineReport report) {
    final rate = report.overallCompletionRate;
    final rateColor = report.velocityColor;
    final rateLabel = report.velocityLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.insights_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Your Completion Velocity',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
          ]),
          const SizedBox(height: 14),

          // Completion rate bar
          Row(children: [
            SizedBox(
              width: 48,
              child: Text('${(rate * 100).round()}%',
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: rateColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      backgroundColor: rateColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(rateColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('On-time completion rate · $rateLabel',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _text2(context))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Stats row
          Row(children: [
            _velocityStat(
              '${report.avgDailyFocusHours.toStringAsFixed(1)}h',
              'Avg daily focus',
              Icons.timer_outlined,
            ),
            const SizedBox(width: 24),
            _velocityStat(
              '${report.historicalSampleSize}',
              'Tasks analyzed',
              Icons.history_rounded,
            ),
            const SizedBox(width: 24),
            _velocityStat(
              '${report.predictions.length}',
              'Active deadlines',
              Icons.calendar_today_rounded,
            ),
          ]),

          if (report.historicalSampleSize == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Predictions become more accurate as you complete more tasks with due dates.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.warning,
                    height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _velocityStat(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 12, color: _hint(context)),
          const SizedBox(width: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _text1(context))),
        ]),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10, color: _hint(context))),
      ],
    );
  }

  // ── List header + filter ──────────────────────────────────────────────────────

  Widget _listHeader(DeadlineReport report) {
    return Row(children: [
      Text('Predictions',
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _text1(context))),
      const Spacer(),
      _filterChip('All', 'all', report.predictions.length),
      const SizedBox(width: 6),
      _filterChip('At Risk+', 'warning', report.warningCount,
          color: report.worstLevel.color),
    ]);
  }

  Widget _filterChip(String label, String value, int count,
      {Color? color}) {
    final active = _filter == value;
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _expandedIndex = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.withValues(alpha: 0.12) : _card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? c.withValues(alpha: 0.40) : _divider(context)),
        ),
        child: Text('$label  $count',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? c : _hint(context))),
      ),
    );
  }

  List<DeadlinePrediction> _filteredPredictions(DeadlineReport report) {
    final all = report.sorted;
    if (_filter == 'warning') {
      return all.where((p) => p.riskLevel != RiskLevel.onTrack).toList();
    }
    return all;
  }

  // ── Prediction card ───────────────────────────────────────────────────────────

  Widget _predictionCard(DeadlinePrediction pred, int index) {
    final level = pred.riskLevel;
    final c = level.color;
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(
          () => _expandedIndex = isExpanded ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isExpanded
                  ? c.withValues(alpha: 0.45)
                  : _divider(context)),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                      color: c.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Column(
          children: [
            // ── Header row ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Risk indicator
                      Container(
                        width: 4,
                        height: 42,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(pred.taskTitle,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _text1(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              _riskBadge(level),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: [
                              _priorityPill(pred.taskPriority),
                              const SizedBox(width: 6),
                              Text(_dueLabel(pred.hoursUntilDue),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: _text2(context))),
                            ]),
                          ],
                        ),
                      ),
                      // Chevron
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: _hint(context), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Risk score bar + confidence
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(level.headline,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c)),
                              Text('${pred.riskScore}% risk',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: c)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pred.riskScore / 100,
                              backgroundColor: c.withValues(alpha: 0.10),
                              valueColor: AlwaysStoppedAnimation(c),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${pred.confidence}%',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _text2(context))),
                        Text('confidence',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: _hint(context))),
                      ],
                    ),
                  ]),
                ],
              ),
            ),

            // ── Expanded details ──────────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _expandedDetails(pred),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedDetails(DeadlinePrediction pred) {
    final level = pred.riskLevel;
    final c = level.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: _divider(context)),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Why this prediction
              Text('Why this prediction',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _text2(context),
                      letterSpacing: 0.3)),
              const SizedBox(height: 8),
              ...pred.reasons.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.7),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _text1(context),
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  )),

              // Start-by recommendation
              if (pred.recommendStartBy != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Icon(Icons.alarm_rounded, color: c, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _startByMessage(pred.recommendStartBy!),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c,
                            height: 1.3),
                      ),
                    ),
                  ]),
                ),
              ],

              // Completion rate context
              const SizedBox(height: 12),
              Row(children: [
                _detailChip(
                  '${(pred.historicalCompletionRate * 100).round()}% historical',
                  Icons.history_rounded,
                  _text2(context),
                ),
                const SizedBox(width: 8),
                _detailChip(
                  '${_fmtH(pred.estimatedHoursNeeded)} est.',
                  Icons.schedule_rounded,
                  _text2(context),
                ),
                if (pred.historicalSampleSize > 0) ...[
                  const SizedBox(width: 8),
                  _detailChip(
                    '${pred.historicalSampleSize} samples',
                    Icons.bar_chart_rounded,
                    _text2(context),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────────

  Widget _riskBadge(RiskLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(level.emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 4),
        Text(level.label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: level.color)),
      ]),
    );
  }

  Widget _priorityPill(String priority) {
    final c = switch (priority) {
      'URGENT' => const Color(0xFFEF4444),
      'HIGH' => AppColors.primary,
      'LOW' => const Color(0xFF6B7280),
      _ => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(5)),
      child: Text(priority,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _detailChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ── Formatters ─────────────────────────────────────────────────────────────────

  String _dueLabel(double hoursUntilDue) {
    if (hoursUntilDue < 0) {
      final h = (-hoursUntilDue);
      if (h < 24) return 'Overdue by ${h.toStringAsFixed(1)}h';
      return 'Overdue by ${(h / 24).round()}d';
    }
    if (hoursUntilDue < 1) {
      return 'Due in ${(hoursUntilDue * 60).round()}m';
    }
    if (hoursUntilDue < 24) {
      return 'Due in ${hoursUntilDue.toStringAsFixed(1)}h';
    }
    final days = (hoursUntilDue / 24).floor();
    return 'Due in ${days}d';
  }

  String _fmtH(double h) {
    if (h < 1) return '${(h * 60).round()}m';
    final whole = h.floor();
    final mins = ((h - whole) * 60).round();
    return mins > 0 ? '${whole}h ${mins}m' : '${whole}h';
  }

  String _startByMessage(DateTime startBy) {
    final now = DateTime.now();
    final diff = startBy.difference(now);
    if (diff.isNegative || diff.inMinutes < 5) {
      return 'Start immediately to stay on track';
    }
    final h = startBy.hour;
    final m = startBy.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final today = startBy.day == now.day;
    final prefix = today ? 'Today' : 'Tomorrow';
    return 'Start by $prefix $h12:$m $ampm to stay on track';
  }

  String _updatedLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just updated';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }
}
