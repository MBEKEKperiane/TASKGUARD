import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/focus/models/focus_session_state.dart';
import '../../features/focus/providers/focus_provider.dart';
import '../../features/gamification/models/gamification_models.dart';
import '../../services/break_reminder_engine.dart';
import '../../services/gamification_engine.dart';
import '../../services/local_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/badge_unlock_overlay.dart';
import '../settings/settings_screen.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final int plannedMins;
  final String? taskTitle;

  const FocusTimerScreen({
    super.key,
    this.plannedMins = 25,
    this.taskTitle,
  });

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback ensures the widget is fully mounted before the
    // async initialize() call triggers its first state update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(focusProvider.notifier).initialize(
              widget.plannedMins,
              widget.taskTitle,
            );
      }
    });
  }

  // ── Toggle (Start / Pause / Resume) ────────────────────────────────────────

  Future<void> _toggle(FocusStatus status) async {
    final n = ref.read(focusProvider.notifier);
    switch (status) {
      case FocusStatus.idle:
        n.start();
        // Schedule a break reminder to fire when the work threshold is reached.
        final breakInfo = await BreakReminderEngine.analyze();
        if (breakInfo.minutesUntilBreak > 0) {
          final fireAt = DateTime.now()
              .add(Duration(minutes: breakInfo.minutesUntilBreak));
          await LocalNotificationService.scheduleBreakReminder(
            fireAt,
            mood: breakInfo.mood,
          );
        }
      case FocusStatus.active:
        n.pause();
      case FocusStatus.paused:
        n.resume();
      default:
        break;
    }
  }

  // ── End with confirmation ───────────────────────────────────────────────────

  Future<void> _requestEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Session?',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        content: Text(
          'Your progress will be saved and stats updated.',
          style: GoogleFonts.inter(
              fontSize: 14, color: context.colText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Going',
                style:
                    GoogleFonts.inter(color: context.colText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('End',
                style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await LocalNotificationService.cancelBreakReminder();
      ref.read(focusProvider.notifier).end();
    }
  }

  // ── Focus gamification ──────────────────────────────────────────────────────

  Future<void> _onFocusSessionCompleted() async {
    final newBadges = await GamificationEngine.onFocusCompleted();
    for (final BadgeDef badge in newBadges) {
      if (mounted) await BadgeUnlockOverlay.show(context, badge);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);

    // Fire gamification hook exactly once when the session transitions to completed.
    ref.listen<FocusSessionState>(focusProvider, (prev, next) {
      if (prev?.status != FocusStatus.completed &&
          next.status == FocusStatus.completed) {
        _onFocusSessionCompleted();
      }
    });

    // Prevent back-swipe / hardware back while actively focusing.
    return PopScope(
      canPop: state.status != FocusStatus.active &&
          state.status != FocusStatus.paused,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestEnd();
      },
      child: Scaffold(
        backgroundColor: context.colBg,
        appBar: AppHeader(
          onSettingsTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: state.status == FocusStatus.completed
              ? _buildSummary(state)
              : _buildTimer(state),
        ),
      ),
    );
  }

  // ── Timer view ───────────────────────────────────────────────────────────────

  Widget _buildTimer(FocusSessionState state) {
    final busy = state.status == FocusStatus.starting ||
        state.status == FocusStatus.ending;
    final canToggle = state.status == FocusStatus.idle ||
        state.status == FocusStatus.active ||
        state.status == FocusStatus.paused;
    final isPaused = state.status == FocusStatus.paused;

    final String toggleLabel = switch (state.status) {
      FocusStatus.starting => 'Preparing…',
      FocusStatus.idle     => 'Start',
      FocusStatus.active   => 'Pause',
      FocusStatus.paused   => 'Resume',
      FocusStatus.ending   => 'Saving…',
      _                    => 'Start',
    };

    final Color accentColor =
        isPaused ? AppColors.warning : AppColors.primary;

    return SingleChildScrollView(
      key: const ValueKey('timer'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Mode badge ─────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isPaused
                    ? AppColors.warningContainer
                    : context.colPrimaryC,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                switch (state.status) {
                  FocusStatus.starting => 'Starting…',
                  FocusStatus.ending   => 'Saving…',
                  FocusStatus.paused   => 'Session Paused',
                  _                    => 'AI Focus Mode',
                },
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColor),
              ),
            ),

            const SizedBox(height: 18),

            // ── Task title ────────────────────────────────────────────────
            Text(
              widget.taskTitle ?? 'Deep Work',
              style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.colText1),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 40),

            // ── Ring timer ────────────────────────────────────────────────
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: busy ? null : (1 - state.progress),
                      strokeWidth: 8,
                      backgroundColor: context.colPrimaryC,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(accentColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  if (!busy)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.timeLabel,
                          style: GoogleFonts.inter(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: -1),
                        ),
                        Text(
                          isPaused ? 'PAUSED' : 'REMAINING',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colText2,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ── Start / Pause / Resume button ──────────────────────────────
            GestureDetector(
              onTap: canToggle ? () => _toggle(state.status) : null,
              child: AnimatedOpacity(
                opacity: canToggle ? 1.0 : 0.55,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isPaused
                        ? const LinearGradient(colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFFFBB3B),
                          ])
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    toggleLabel,
                    style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── End Session button ─────────────────────────────────────────
            OutlinedButton(
              onPressed: busy ? null : _requestEnd,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('End Session',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 28),

            // ── Contextual tip ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.colPrimaryC,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tipText,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.colText1,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ── Summary view (shown after session ends) ────────────────────────────────

  Widget _buildSummary(FocusSessionState state) {
    final session = state.completedSession ?? {};
    final actual = (session['actualMins'] as int?) ?? state.actualFocusMins;
    final planned = state.totalSeconds ~/ 60;
    final score = (session['focusScore'] as int?) ?? 0;
    final pct = planned > 0 ? (actual / planned * 100).round().clamp(0, 100) : 0;

    return SingleChildScrollView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // ── Checkmark icon ────────────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24)),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),

          const SizedBox(height: 20),

          Text('Session Complete!',
              style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),

          const SizedBox(height: 8),

          Text(
            _completionMessage(pct),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: context.colText2, height: 1.5),
          ),

          const SizedBox(height: 32),

          // ── Stat cards ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.timer_rounded,
                  label: 'Focused',
                  value: '$actual min',
                  sub: 'of $planned planned',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  icon: Icons.bolt_rounded,
                  label: 'Focus Score',
                  value: '$score%',
                  sub: _scoreLabel(score),
                  highlight: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Completion bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.colCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Session Completion',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colText1)),
                    Text('$pct%',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.primaryContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Done button ───────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: Text('Done',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? context.colPrimaryC : context.colCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colText1)),
          Text(sub,
              style: GoogleFonts.inter(
                  fontSize: 11, color: context.colText2)),
        ],
      ),
    );
  }

  // ── Pure helpers ───────────────────────────────────────────────────────────

  String _completionMessage(int pct) {
    if (pct >= 90) {
      return 'Outstanding! You completed the full session with deep focus.';
    }
    if (pct >= 60) {
      return 'Great effort — you stayed focused for a meaningful block of time.';
    }
    return 'Every focused minute counts. Keep building the habit!';
  }

  String _scoreLabel(int score) {
    if (score >= 90) return 'Elite';
    if (score >= 70) return 'Strong';
    if (score >= 50) return 'Building';
    return 'Getting Started';
  }

  String get _tipText {
    final hour = DateTime.now().hour;
    final task = widget.taskTitle;
    if (task != null && task.isNotEmpty) {
      if (hour >= 8 && hour < 11) {
        return 'Morning focus peak — ideal for "$task". Notifications are muted.';
      }
      if (hour >= 13 && hour < 16) {
        return 'Post-lunch productivity window. Locked in on "$task".';
      }
      if (hour >= 17) {
        return 'Finishing strong on "$task". TaskGuard has muted distractions.';
      }
      return 'Focused on "$task". TaskGuard has muted notifications to keep you in flow.';
    }
    if (hour >= 8 && hour < 11) {
      return 'Morning focus peak active. Notifications are muted to keep you in flow.';
    }
    if (hour >= 13 && hour < 16) {
      return 'Post-lunch productivity window. Stay locked in — notifications are muted.';
    }
    return "You're in focus mode. TaskGuard has muted notifications to keep you in flow.";
  }
}
