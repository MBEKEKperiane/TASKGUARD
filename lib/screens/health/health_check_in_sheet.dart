import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/health/models/health_models.dart';
import '../../features/health/providers/health_provider.dart';

const _kAccent = Color(0xFF0D9488); // teal-600

Color _bg(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

Color _surface(BuildContext ctx) =>
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

Color _divider(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

Future<void> showHealthCheckInSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.88,
      child: _HealthCheckInSheet(),
    ),
  );
}

class _HealthCheckInSheet extends ConsumerStatefulWidget {
  const _HealthCheckInSheet();

  @override
  ConsumerState<_HealthCheckInSheet> createState() =>
      _HealthCheckInSheetState();
}

class _HealthCheckInSheetState extends ConsumerState<_HealthCheckInSheet> {
  double _sleep = 7.0;
  int _energy = 3;
  HealthMood _mood = HealthMood.okay;
  bool _saving = false;

  String _sleepText(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    if (mins == 0) return '${hrs}h';
    return '${hrs}h ${mins}m';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(healthProvider.notifier).logToday(
          sleepHours: _sleep,
          energyLevel: _energy,
          mood: _mood,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final surface = _surface(context);
    final bg = _bg(context);
    final t1 = _text1(context);
    final t2 = _text2(context);
    final div = _divider(context);
    final workload = WorkloadLevel.values[_previewWorkloadIndex()];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: div,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: _kAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Health Check-in',
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: t1)),
                          Text('Takes 20 seconds',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: t2)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Sleep ──────────────────────────────────────────────────
                  _sectionLabel('😴  Sleep last night', t1),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: div),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_sleepText(_sleep),
                                style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: sleepColor(_sleep))),
                            Text(sleepLabel(_sleep),
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sleepColor(_sleep))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: sleepColor(_sleep),
                            inactiveTrackColor:
                                sleepColor(_sleep).withValues(alpha: 0.2),
                            thumbColor: sleepColor(_sleep),
                            overlayColor:
                                sleepColor(_sleep).withValues(alpha: 0.1),
                            trackHeight: 5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            min: 0,
                            max: 12,
                            divisions: 24,
                            value: _sleep,
                            onChanged: (v) => setState(() => _sleep = v),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0h',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: t2)),
                            Text('12h',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: t2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Energy ─────────────────────────────────────────────────
                  _sectionLabel('⚡  Energy level right now', t1),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final lvl = i + 1;
                      final selected = _energy == lvl;
                      final c = energyColor(lvl);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _energy = lvl),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? c.withValues(alpha: 0.15)
                                  : bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? c : div,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(energyEmoji(lvl),
                                    style:
                                        const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text('$lvl',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? c : t2)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(energyLabel(1),
                          style: GoogleFonts.inter(fontSize: 11, color: t2)),
                      Text(energyLabel(5),
                          style: GoogleFonts.inter(fontSize: 11, color: t2)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Mood ───────────────────────────────────────────────────
                  _sectionLabel('💭  How are you feeling?', t1),
                  const SizedBox(height: 10),
                  Row(
                    children: HealthMood.values.map((m) {
                      final selected = _mood == m;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mood = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                                right: m != HealthMood.values.last ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? m.color.withValues(alpha: 0.12)
                                  : bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? m.color : div,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(m.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(m.label,
                                    style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selected ? m.color : t2)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Workload preview ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: workload.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: workload.color.withValues(alpha: 0.30)),
                    ),
                    child: Row(children: [
                      Text(workload.emoji,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recommended: ${workload.label}',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: workload.color)),
                            const SizedBox(height: 2),
                            Text(workload.subtitle,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: t2, height: 1.35)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Save button ────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Save Check-in',
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
        ],
      ),
    );
  }

  int _previewWorkloadIndex() {
    final score = sleepScore(_sleep) + energyScore(_energy) + _mood.score;
    if (score <= 2) return WorkloadLevel.rest.index;
    if (score <= 4) return WorkloadLevel.light.index;
    if (score <= 7) return WorkloadLevel.moderate.index;
    if (score <= 9) return WorkloadLevel.full.index;
    return WorkloadLevel.stretch.index;
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700, color: color),
      );
}
