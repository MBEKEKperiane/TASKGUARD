import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/productivity_report_engine.dart';
import '../models/daily_report.dart';
import '../models/weekly_report.dart';

class ReportsState {
  final DailyReport? dailyReport;
  final WeeklyReport? weekReport;
  final DateTime selectedDate;
  final DateTime selectedWeekStart;
  final bool isLoading;

  const ReportsState({
    this.dailyReport,
    this.weekReport,
    required this.selectedDate,
    required this.selectedWeekStart,
    this.isLoading = false,
  });

  ReportsState copyWith({
    DailyReport? dailyReport,
    WeeklyReport? weekReport,
    DateTime? selectedDate,
    DateTime? selectedWeekStart,
    bool? isLoading,
  }) =>
      ReportsState(
        dailyReport: dailyReport ?? this.dailyReport,
        weekReport: weekReport ?? this.weekReport,
        selectedDate: selectedDate ?? this.selectedDate,
        selectedWeekStart: selectedWeekStart ?? this.selectedWeekStart,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier()
      : super(ReportsState(
          selectedDate: DateTime.now(),
          selectedWeekStart:
              ProductivityReportEngine.weekStartFor(DateTime.now()),
        ));

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    final results = await Future.wait([
      ProductivityReportEngine.generateDaily(state.selectedDate),
      ProductivityReportEngine.generateWeekly(state.selectedWeekStart),
    ]);
    if (mounted) {
      state = state.copyWith(
        dailyReport: results[0] as DailyReport,
        weekReport: results[1] as WeeklyReport,
        isLoading: false,
      );
    }
  }

  Future<void> shiftDay(int delta) async {
    final next = state.selectedDate.add(Duration(days: delta));
    if (next.isAfter(DateTime.now())) return;
    state = state.copyWith(selectedDate: next, isLoading: true);
    final report = await ProductivityReportEngine.generateDaily(next);
    if (mounted) {
      state = state.copyWith(dailyReport: report, isLoading: false);
    }
  }

  Future<void> shiftWeek(int delta) async {
    final next =
        state.selectedWeekStart.add(Duration(days: delta * 7));
    if (next.isAfter(DateTime.now())) return;
    state = state.copyWith(selectedWeekStart: next, isLoading: true);
    final report = await ProductivityReportEngine.generateWeekly(next);
    if (mounted) {
      state = state.copyWith(weekReport: report, isLoading: false);
    }
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>(
  (_) => ReportsNotifier(),
);
