import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../focus/focus_timer_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/new_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  final _eventDays = {
    DateTime.utc(2026, 5, 5),
    DateTime.utc(2026, 5, 19),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        onSettingsTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const FractionallySizedBox(
              heightFactor: 0.92,
              child: NewTaskScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                onDaySelected: (sel, foc) =>
                    setState(() { _selected = sel; _focused = foc; }),
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: (day) =>
                    _eventDays.contains(DateTime.utc(day.year, day.month, day.day))
                        ? [true]
                        : [],
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 5,
                  outsideDaysVisible: true,
                  outsideTextStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                  weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
                  defaultTextStyle: GoogleFonts.inter(fontSize: 13),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: false,
                  titleTextStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textSecondary,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                  headerPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  weekendStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Today's Focus section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S FOCUS",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Thursday, 12 Sep',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '3 AI Insights',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Completed task
                  _timelineItem(
                    time: '09:00 AM',
                    title: 'Quarterly Review Prep',
                    subtitle: 'Gather analytics data from the...',
                    completed: true,
                    hasAi: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 14),
                  // Active task
                  _timelineItem(
                    time: '11:00 AM',
                    title: 'Client Strategy Session',
                    subtitle: 'Deep dive into AI implementation for Q4',
                    completed: false,
                    hasAi: true,
                    aiText: 'AI suggests: Focus on automation ROI',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const FocusTimerScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _timelineItem(
                    time: '02:30 PM',
                    title: 'Weekly Sync',
                    subtitle: 'Team updates and blocker resolution',
                    completed: false,
                    hasAi: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem({
    required String time,
    required String title,
    required String subtitle,
    required bool completed,
    required bool hasAi,
    String? aiText,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: MediaQuery.of(context).size.width - 112,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(
                  color: completed ? AppColors.textHint : AppColors.primary,
                  width: 3,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completed
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (hasAi && aiText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        aiText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
