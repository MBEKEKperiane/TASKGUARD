import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/prioritization/models/prioritized_task.dart';
import '../../features/prioritization/providers/prioritization_provider.dart';
import '../../theme/app_colors.dart';

class PrioritizationScreen extends ConsumerStatefulWidget {
  const PrioritizationScreen({super.key});

  @override
  ConsumerState<PrioritizationScreen> createState() =>
      _PrioritizationScreenState();
}

class _PrioritizationScreenState extends ConsumerState<PrioritizationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prioritizationProvider.notifier).rank();
    });
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prioritizationProvider);

    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppBar(
        backgroundColor: context.colSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colText1),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Priority Queue',
          style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.colText1),
        ),
        actions: [
          if (state.lastRefreshed != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  _timeAgo(state.lastRefreshed),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: context.colHint),
                ),
              ),
            ),
          IconButton(
            icon: state.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Icon(Icons.refresh_rounded, color: context.colIcon),
            onPressed: state.isLoading
                ? null
                : () => ref.read(prioritizationProvider.notifier).rank(),
          ),
        ],
      ),
      body: state.isLoading && state.rankedTasks.isEmpty
          ? _buildLoading()
          : state.rankedTasks.isEmpty
              ? _buildEmpty()
              : _buildList(state),
    );
  }

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Analysing your tasks…',
                style: GoogleFonts.inter(
                    fontSize: 14, color: context.colText2)),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: context.colPrimaryC, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('All clear!',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.colText1)),
            const SizedBox(height: 6),
            Text('No pending tasks to prioritise.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: context.colText2)),
          ],
        ),
      );

  Widget _buildList(PrioritizationState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: state.rankedTasks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(state);
        return _buildTaskCard(state.rankedTasks[index - 1]);
      },
    );
  }

  // ── Header: score legend + top recommendation ────────────────────────────

  Widget _buildHeader(PrioritizationState state) {
    final top = state.rankedTasks.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanation banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colPrimaryC,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ranked by urgency, importance, deadline proximity, and your focus patterns.',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Top recommendation card
        Text('Start here',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colHint,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        _buildTopCard(top),
        const SizedBox(height: 24),

        if (state.rankedTasks.length > 1) ...[
          Text('Full ranking',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.colHint,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ── Rank #1 hero card ────────────────────────────────────────────────────

  Widget _buildTopCard(PrioritizedTask pt) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rankBadge(1, light: true),
              const Spacer(),
              _priorityPill(pt.priority, light: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(pt.title,
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(pt.recommendation,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45)),
          const SizedBox(height: 14),
          _scoreBar(pt.totalScore, light: true),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pt.reasons
                .map((r) => _reasonChip(r, light: true))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Ranked task card (rank 2+) ───────────────────────────────────────────

  Widget _buildTaskCard(PrioritizedTask pt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rankBadge(pt.rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(pt.title,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colText1),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    _priorityPill(pt.priority),
                  ],
                ),
                const SizedBox(height: 6),
                Text(pt.recommendation,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.colText2,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                _scoreBar(pt.totalScore),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: pt.reasons
                      .map((r) => _reasonChip(r))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Score breakdown bar ──────────────────────────────────────────────────

  Widget _scoreBar(double score, {bool light = false}) {
    final pct = (score / 100).clamp(0.0, 1.0);
    final label = score >= 75
        ? 'Critical'
        : score >= 55
            ? 'High'
            : score >= 35
                ? 'Medium'
                : 'Low';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: light
                      ? Colors.white.withValues(alpha: 0.25)
                      : context.colDivider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      light ? Colors.white : AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${score.toInt()}  ·  $label',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: light
                      ? Colors.white.withValues(alpha: 0.85)
                      : context.colText2),
            ),
          ],
        ),
      ],
    );
  }

  // ── Reason chip ──────────────────────────────────────────────────────────

  Widget _reasonChip(String label, {bool light = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: light
              ? Colors.white.withValues(alpha: 0.18)
              : context.colSurfaceVar,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: light ? Colors.white : context.colText2)),
      );

  // ── Rank badge ───────────────────────────────────────────────────────────

  Widget _rankBadge(int rank, {bool light = false}) {
    final isTop = rank == 1;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.20)
            : isTop
                ? AppColors.primary
                : context.colSurfaceVar,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: light
                ? Colors.white
                : isTop
                    ? Colors.white
                    : context.colText2),
      ),
    );
  }

  // ── Priority pill ────────────────────────────────────────────────────────

  Widget _priorityPill(String priority, {bool light = false}) {
    Color c = switch (priority) {
      'URGENT' => const Color(0xFFDC2626),
      'HIGH' => AppColors.priorityHigh,
      'MEDIUM' => AppColors.priorityMedium,
      _ => AppColors.priorityLow,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.18) : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority,
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: light ? Colors.white : c),
      ),
    );
  }
}
