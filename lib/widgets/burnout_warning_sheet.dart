import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/burnout/models/burnout_result.dart';
import '../services/task_service.dart';
import '../theme/app_colors.dart';

class BurnoutWarningSheet extends StatefulWidget {
  final BurnoutResult result;
  final VoidCallback? onBreakRequested;

  const BurnoutWarningSheet({
    super.key,
    required this.result,
    this.onBreakRequested,
  });

  @override
  State<BurnoutWarningSheet> createState() => _BurnoutWarningSheetState();
}

class _BurnoutWarningSheetState extends State<BurnoutWarningSheet> {
  final _taskService = TaskService();
  final Set<String> _deferredIds = {};
  final Set<String> _deferringIds = {};

  Future<void> _defer(String taskId) async {
    setState(() => _deferringIds.add(taskId));
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowIso = DateTime(
            tomorrow.year, tomorrow.month, tomorrow.day, 9, 0)
        .toIso8601String();
    try {
      await _taskService
          .updateTask(taskId, {'dueDate': tomorrowIso, 'startTime': tomorrowIso});
    } catch (_) {
      // Optimistic — still mark as deferred locally
    }
    if (mounted) {
      setState(() {
        _deferredIds.add(taskId);
        _deferringIds.remove(taskId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final levelColor = r.level.color;

    return Container(
      decoration: BoxDecoration(
        color: context.colSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Level badge ────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: levelColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: levelColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${r.level.label}  ·  Risk score: ${r.score}/100',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: levelColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Headline ───────────────────────────────────────────────
              Text(
                r.headline,
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.colText1,
                    height: 1.3),
              ),

              const SizedBox(height: 12),

              // ── Advice card ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.psychology_rounded,
                        color: levelColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.advice,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.colText1,
                            height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Warnings ───────────────────────────────────────────────
              if (r.warnings.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(context, 'Signals detected'),
                const SizedBox(height: 8),
                ...r.warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: levelColor,
                                  shape: BoxShape.circle),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(w,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: context.colText2,
                                    height: 1.45)),
                          ),
                        ],
                      ),
                    )),
              ],

              // ── Rescheduling suggestions ───────────────────────────────
              if (r.rescheduleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Divider(color: context.colDivider),
                const SizedBox(height: 14),
                _sectionLabel(context, 'Suggested rescheduling'),
                const SizedBox(height: 4),
                Text('Defer these tasks to tomorrow to reduce pressure.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: context.colText2)),
                const SizedBox(height: 12),
                ...r.rescheduleSuggestions.map((s) {
                  final deferred = _deferredIds.contains(s.taskId);
                  final deferring = _deferringIds.contains(s.taskId);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: deferred
                            ? AppColors.secondary.withValues(alpha: 0.4)
                            : context.colDivider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          deferred
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: deferred
                              ? AppColors.secondary
                              : context.colHint,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.taskTitle,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: deferred
                                        ? context.colHint
                                        : context.colText1,
                                    decoration: deferred
                                        ? TextDecoration.lineThrough
                                        : null),
                              ),
                              Text(s.reason,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: context.colText2)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (deferred)
                          Text('Tomorrow',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary))
                        else if (deferring)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary),
                          )
                        else
                          GestureDetector(
                            onTap: () => _defer(s.taskId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Defer',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),

              // ── CTAs ───────────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onBreakRequested?.call();
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text('Take a 15-min break',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("I'll manage",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: context.colText2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colHint,
            letterSpacing: 0.8),
      );
}
