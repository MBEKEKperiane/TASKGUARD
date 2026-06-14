import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/health/models/health_models.dart';
import '../../features/health/providers/health_provider.dart';
import '../../services/health_engine.dart';
import 'health_check_in_sheet.dart';

const _kAccent = Color(0xFF0D9488);

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

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => ref.read(healthProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);
    final today = health.todayEntry;
    final recent = health.recentEntries;

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
        title: Text('Health & Wellbeing',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        actions: [
          TextButton.icon(
            onPressed: () => showHealthCheckInSheet(context).then(
                (_) => ref.read(healthProvider.notifier).refresh()),
            icon: const Icon(Icons.edit_rounded, color: _kAccent, size: 16),
            label: Text(today != null ? 'Update' : 'Check in',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kAccent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── No entry prompt ────────────────────────────────────────────
            if (today == null) ...[
              _noEntryCard(context),
              const SizedBox(height: 20),
            ],

            // ── Today's status ─────────────────────────────────────────────
            if (today != null) ...[
              _todayCard(context, today, health.insight!),
              const SizedBox(height: 16),
              _statsRow(context, today),
              const SizedBox(height: 20),
              _tipsCard(context, health.insight!),
              const SizedBox(height: 20),
            ],

            // ── 7-day history ──────────────────────────────────────────────
            if (recent.isNotEmpty) ...[
              Text('Last 7 Days',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _text1(context))),
              const SizedBox(height: 12),
              _weekChart(context, recent),
              const SizedBox(height: 20),
              _weekAverages(context, recent),
              const SizedBox(height: 20),
              _historyList(context, recent),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── No-entry card ──────────────────────────────────────────────────────────

  Widget _noEntryCard(BuildContext context) {
    return GestureDetector(
      onTap: () => showHealthCheckInSheet(context)
          .then((_) => ref.read(healthProvider.notifier).refresh()),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _kAccent.withValues(alpha: 0.10),
              _kAccent.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text('🌅', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('How are you doing today?',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _text1(context))),
            const SizedBox(height: 6),
            Text(
              'Log your sleep, energy and mood to get a personalised workload recommendation.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 13, color: _text2(context), height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => showHealthCheckInSheet(context)
                  .then((_) => ref.read(healthProvider.notifier).refresh()),
              child: Text('Check in now',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today card (workload) ──────────────────────────────────────────────────

  Widget _todayCard(
      BuildContext context, HealthEntry entry, HealthInsight insight) {
    final w = insight.workload;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            w.color.withValues(alpha: 0.14),
            w.color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: w.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: w.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(w.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's Workload",
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: w.color)),
                const SizedBox(height: 4),
                Text(w.label,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _text1(context))),
                const SizedBox(height: 4),
                Text(w.subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _text2(context),
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _statsRow(BuildContext context, HealthEntry entry) {
    return Row(
      children: [
        Expanded(
            child: _statBox(
                context,
                '😴',
                _sleepText(entry.sleepHours),
                sleepLabel(entry.sleepHours),
                sleepColor(entry.sleepHours))),
        const SizedBox(width: 10),
        Expanded(
            child: _statBox(
                context,
                energyEmoji(entry.energyLevel),
                '${entry.energyLevel}/5',
                energyLabel(entry.energyLevel),
                energyColor(entry.energyLevel))),
        const SizedBox(width: 10),
        Expanded(
            child: _statBox(context, entry.mood.emoji, entry.mood.label,
                'Mood', entry.mood.color)),
      ],
    );
  }

  Widget _statBox(BuildContext context, String icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 10, color: _hint(context))),
        ],
      ),
    );
  }

  // ── Tips card ──────────────────────────────────────────────────────────────

  Widget _tipsCard(BuildContext context, HealthInsight insight) {
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
            const Icon(Icons.lightbulb_rounded, color: _kAccent, size: 18),
            const SizedBox(width: 8),
            Text('Tips for today',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
          ]),
          const SizedBox(height: 12),
          ...insight.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _kAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tip,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _text2(context),
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Week chart ─────────────────────────────────────────────────────────────

  Widget _weekChart(BuildContext context, List<HealthEntry> entries) {
    // Ordered oldest→newest for chart
    final ordered = [...entries.reversed];
    const maxSleep = 10.0;

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
            _chartLegendDot(_kAccent),
            const SizedBox(width: 6),
            Text('Sleep hours',
                style:
                    GoogleFonts.inter(fontSize: 12, color: _text2(context))),
            const SizedBox(width: 16),
            _chartLegendDot(const Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            Text('Energy (×2h)',
                style:
                    GoogleFonts.inter(fontSize: 12, color: _text2(context))),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ordered.map((e) {
                final sleepFrac = (e.sleepHours / maxSleep).clamp(0.0, 1.0);
                // Energy mapped as (energy*2)/10 for same scale
                final energyFrac =
                    ((e.energyLevel * 2.0) / maxSleep).clamp(0.0, 1.0);
                final dayLabel = _shortDay(e.date);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 64,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Sleep bar
                              Positioned(
                                left: 0,
                                right: 6,
                                bottom: 0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    height: 64 * sleepFrac,
                                    color:
                                        _kAccent.withValues(alpha: 0.70),
                                  ),
                                ),
                              ),
                              // Energy bar (slightly offset right)
                              Positioned(
                                right: 0,
                                left: 6,
                                bottom: 0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    height: 64 * energyFrac,
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.70),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(dayLabel,
                            style: GoogleFonts.inter(
                                fontSize: 10, color: _hint(context))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // ── Week averages ──────────────────────────────────────────────────────────

  Widget _weekAverages(BuildContext context, List<HealthEntry> entries) {
    final avgSleep = HealthEngine.averageSleep(entries);
    final avgEnergy = HealthEngine.averageEnergy(entries);
    final avgMood = HealthEngine.averageMoodScore(entries);

    return Row(children: [
      Expanded(
          child: _avgTile(context, '😴', _sleepText(avgSleep), 'Avg Sleep',
              sleepColor(avgSleep))),
      const SizedBox(width: 10),
      Expanded(
          child: _avgTile(
              context,
              energyEmoji(avgEnergy.round()),
              avgEnergy.toStringAsFixed(1),
              'Avg Energy',
              energyColor(avgEnergy.round()))),
      const SizedBox(width: 10),
      Expanded(
          child: _avgTile(
              context,
              _moodFromScore(avgMood).emoji,
              _moodFromScore(avgMood).label,
              'Avg Mood',
              _moodFromScore(avgMood).color)),
    ]);
  }

  Widget _avgTile(BuildContext context, String icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: _hint(context))),
        ],
      ),
    );
  }

  // ── History list ───────────────────────────────────────────────────────────

  Widget _historyList(BuildContext context, List<HealthEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        const SizedBox(height: 10),
        ...entries.map((e) => _historyTile(context, e)),
      ],
    );
  }

  Widget _historyTile(BuildContext context, HealthEntry entry) {
    final w = HealthEngine.computeWorkload(entry);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider(context)),
      ),
      child: Row(
        children: [
          Text(entry.mood.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_longDay(entry.date),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text1(context))),
                Text(
                  '${_sleepText(entry.sleepHours)} sleep · Energy ${entry.energyLevel}/5 · ${entry.mood.label}',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: _text2(context)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: w.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(w.label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: w.color)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _sleepText(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    if (mins == 0) return '${hrs}h';
    return '${hrs}h ${mins}m';
  }

  String _shortDay(String date) {
    try {
      final d = DateTime.parse(date);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[d.weekday - 1];
    } catch (_) {
      return date.substring(8);
    }
  }

  String _longDay(String date) {
    try {
      final d = DateTime.parse(date);
      final today = DateTime.now();
      if (d.year == today.year &&
          d.month == today.month &&
          d.day == today.day) {
        return 'Today';
      }
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  HealthMood _moodFromScore(double score) {
    if (score >= 3.5) return HealthMood.great;
    if (score >= 2.5) return HealthMood.good;
    if (score >= 1.5) return HealthMood.okay;
    if (score >= 0.5) return HealthMood.low;
    return HealthMood.burned;
  }
}
