import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../features/burnout/models/burnout_result.dart';
import '../../features/mood/models/mood_entry.dart';
import '../../services/auth_service.dart';
import '../../features/break_reminder/models/break_reminder_result.dart';
import '../../services/break_reminder_engine.dart';
import '../../services/burnout_detector.dart';
import '../../services/mood_storage.dart';
import '../../services/local_notification_service.dart';
import '../../services/local_storage.dart';
import '../../services/task_service.dart';
import '../../services/api_client.dart';
import '../../services/insights_service.dart';
import '../../services/suggestion_engine.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/break_reminder_banner.dart';
import '../../widgets/burnout_warning_sheet.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/responsive_layout.dart';
import '../prioritization/prioritization_screen.dart';
import '../reports/reports_screen.dart';
import '../reschedule/reschedule_screen.dart';
import '../schedule/schedule_screen.dart';
import '../team/team_screen.dart';
import '../study/study_screen.dart';
import '../gamification/achievements_screen.dart';
import '../../features/gamification/models/gamification_models.dart';
import '../../services/gamification_engine.dart';
import '../../widgets/badge_unlock_overlay.dart';
import '../../widgets/voice_task_sheet.dart';
import '../settings/settings_screen.dart';
import '../tasks/new_task_screen.dart';
import '../focus/focus_timer_screen.dart';
import '../health/health_screen.dart';
import '../health/health_check_in_sheet.dart';
import '../../features/health/models/health_models.dart';
import '../../services/health_engine.dart';
import '../deadline/deadline_screen.dart';
import '../../features/deadline/models/deadline_models.dart';
import '../../services/deadline_predictor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _taskService = TaskService();
  final _insightsService = InsightsService();
  final _authService = AuthService();

  List<dynamic> _todayTasks = [];
  final List<dynamic> _completedTasks = [];
  int _overdueCount = 0;
  GamificationData? _gamData;
  HealthEntry? _healthEntry;
  DeadlineReport? _deadlineReport;
  Map<String, dynamic>? _scoreData;
  BurnoutResult? _burnoutResult;
  bool _burnoutShownThisSession = false;
  BreakReminderResult? _breakResult;
  MoodType? _currentMood;
  bool _showMoodCheckin = false;
  String _userName = 'User';
  bool _loading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadCacheThenFetch();
    _registerFcmToken();
    // Request alarm + notification permissions after Activity is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.requestPermissions();
    });
  }

  Future<void> _registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await ApiClient().post('/notifications/token', data: {'token': token});
      }
      // Refresh token if it changes (e.g. app reinstall)
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        ApiClient().post('/notifications/token', data: {'token': newToken});
      });
    } catch (_) {}
  }

  Future<void> _loadCacheThenFetch() async {
    final cachedTasks = LocalStorage.getTodayTasks();
    final cachedScore = LocalStorage.getProductivityScore();
    final cachedUser = LocalStorage.getUser();
    if (cachedTasks.isNotEmpty || cachedScore != null) {
      setState(() {
        _todayTasks = cachedTasks;
        _scoreData = cachedScore;
        _userName = cachedUser?['name'] ?? 'User';
        _loading = false;
      });
    }
    await _load();
  }

  Future<void> _load() async {
    await _taskService.syncPendingOps();

    // Tasks always load — getTodayTasks() handles offline internally.
    // This must happen before the auth check so new tasks are always visible.
    final tasks = await _taskService.getTodayTasks();
    if (mounted) {
      final now = DateTime.now();
      final allTasks = LocalStorage.getAllTasks();
      final overdueCount = allTasks.where((t) {
        if (t['isCompleted'] == true) return false;
        final raw = (t['dueDate'] ?? t['startTime']) as String?;
        if (raw == null) return false;
        try {
          return DateTime.parse(raw).isBefore(now);
        } catch (_) {
          return false;
        }
      }).length;
      setState(() {
        _todayTasks = tasks;
        _overdueCount = overdueCount;
        _loading = false;
        _gamData = GamificationEngine.load();
        _healthEntry = HealthEngine.todayEntry();
        _deadlineReport = DeadlinePredictor.analyze();
      });
      // Keep overdue reminders alive — re-batches if the original 5-hour window expired.
      LocalNotificationService.rescheduleOverdueAlerts(
        tasks.whereType<Map<String, dynamic>>().toList(),
      );
    }

    // Auth check: determines online/offline status
    try {
      final user = await _authService.getMe();
      await LocalStorage.saveUser(user);
      if (mounted) {
        setState(() {
          _userName = user['name'] ?? 'User';
          _isOffline = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final isNetworkDown = e.response == null ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      setState(() { _isOffline = isNetworkDown; });
      return;
    }

    // Non-critical: fail silently
    try {
      final score = await _insightsService.getProductivityScore();
      if (mounted) setState(() { _scoreData = score; });
    } catch (_) {}

    final burnout = await BurnoutDetector.analyze();
    final breakResult = await BreakReminderEngine.analyze();
    final mood = await MoodStorage.loadCurrent();
    final loggedToday = await MoodStorage.hasLoggedToday();
    if (mounted) {
      setState(() {
        _burnoutResult = burnout;
        _breakResult = breakResult;
        _currentMood = mood;
        _showMoodCheckin = !loggedToday;
      });
      if (!_burnoutShownThisSession &&
          burnout.level.index >= BurnoutLevel.high.index) {
        _burnoutShownThisSession = true;
        _showBurnoutSheet(burnout);
      }
    }
  }

  void _showBurnoutSheet(BurnoutResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => BurnoutWarningSheet(result: result),
      ),
    ).then((_) => _load());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  FocusSuggestion get _suggestion => SuggestionEngine.generate(
        pendingTasks: _todayTasks
            .whereType<Map<String, dynamic>>()
            .where((t) => t['isCompleted'] != true)
            .toList(),
        hour: DateTime.now().hour,
        scoreData: _scoreData,
        overloadData: _burnoutResult == null
            ? null
            : {
                'level': _burnoutResult!.level.apiLevel,
                'message': _burnoutResult!.headline,
              },
        mood: _currentMood,
      );

  @override
  Widget build(BuildContext context) {
    final score = (_scoreData?['score'] as num?)?.toDouble() ?? 0;
    final pendingCount =
        _todayTasks.where((t) => t['isCompleted'] == false).length;

    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppHeader(
        onSettingsTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice task creation
          FloatingActionButton.small(
            heroTag: 'voice_fab',
            onPressed: () => showVoiceTaskSheet(context, onCreated: _load),
            backgroundColor: context.colCard,
            elevation: 3,
            child: const Icon(Icons.mic_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 10),
          // Text task creation
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const FractionallySizedBox(
                    heightFactor: 0.92, child: NewTaskScreen()),
              );
              _load();
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline) const OfflineBanner(),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ResponsiveLayout(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_greeting()}, $_userName.',
                              style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: context.colText1)),
                          const SizedBox(height: 4),
                          Text('You have $pendingCount priority tasks today.',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: context.colText2)),
                          if (_showMoodCheckin) ...[
                            const SizedBox(height: 16),
                            _moodCheckInCard(),
                          ],
                          const SizedBox(height: 32),
                          Center(
                            child: CircularPercentIndicator(
                              radius: 100,
                              lineWidth: 12,
                              percent: (score / 100).clamp(0.0, 1.0),
                              animation: true,
                              animationDuration: 1200,
                              circularStrokeCap: CircularStrokeCap.round,
                              progressColor: AppColors.primary,
                              backgroundColor: AppColors.primaryContainer,
                              center: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${score.toInt()}%',
                                      style: GoogleFonts.inter(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary)),
                                  Text('PRODUCTIVITY',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: context.colText2,
                                          letterSpacing: 1.5)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(children: [
                            Text('Smart Suggestions',
                                style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: context.colText1)),
                            const Spacer(),
                            _aiBadge(),
                          ]),
                          const SizedBox(height: 14),
                          _suggestionCard(
                            icon: _suggestion.icon,
                            title: _suggestion.cardTitle,
                            description: _suggestion.description,
                            durationMins: _suggestion.durationMins,
                            actionLabel:
                                'Accept · ${_suggestion.durationMins} min',
                            filled: true,
                            onAction: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FocusTimerScreen(
                                  plannedMins: _suggestion.durationMins,
                                  taskTitle: _suggestion.taskTitle,
                                ),
                              ),
                            ),
                          ),
                          if (_burnoutResult != null &&
                              _burnoutResult!.level.index >=
                                  BurnoutLevel.moderate.index) ...[
                            const SizedBox(height: 12),
                            _burnoutCard(_burnoutResult!),
                          ],
                          if (_breakResult != null && _breakResult!.isBreakDue) ...[
                            const SizedBox(height: 12),
                            BreakReminderBanner(
                              result: _breakResult!,
                              onBreakTaken: () async {
                                await BreakReminderEngine.recordBreak();
                                final updated = await BreakReminderEngine.analyze();
                                if (mounted) setState(() => _breakResult = updated);
                              },
                              onSnoozed: () async {
                                final updated = await BreakReminderEngine.analyze();
                                if (mounted) setState(() => _breakResult = updated);
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (_overdueCount > 0) ...[
                            _rescheduleAlert(),
                            const SizedBox(height: 10),
                          ],
                          _priorityQueueBanner(),
                          const SizedBox(height: 10),
                          _reportsBanner(),
                          const SizedBox(height: 10),
                          _scheduleBanner(),
                          const SizedBox(height: 10),
                          _teamBanner(),
                          const SizedBox(height: 10),
                          _studyBanner(),
                          const SizedBox(height: 10),
                          _gamificationBanner(),
                          const SizedBox(height: 10),
                          _healthBanner(),
                          const SizedBox(height: 10),
                          _deadlineBanner(),
                          const SizedBox(height: 28),
                          Text('Upcoming Tasks',
                              style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: context.colText1)),
                          if (_isWorkloadFiltered) ...[
                            const SizedBox(height: 8),
                            _workloadFilterNotice(),
                          ],
                          const SizedBox(height: 12),
                          if (_displayedTasks.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  _todayTasks.isEmpty
                                      ? 'No pending tasks — great job!'
                                      : 'Rest up — only urgent tasks shown today.',
                                  style: GoogleFonts.inter(
                                      color: context.colHint)),
                              ),
                            )
                          else
                            ..._displayedTasks.map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _taskItem(task: t),
                                )),
                          if (_completedTasks.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Row(children: [
                              Text('Completed Today',
                                  style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: context.colText1)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text('${_completedTasks.length}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary)),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            ..._completedTasks.map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _taskItem(task: t),
                                )),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                      ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _aiBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: context.colPrimaryC,
            borderRadius: BorderRadius.circular(12)),
        child: Text('AI Powered',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );

  Widget _burnoutCard(BurnoutResult result) {
    final c = result.level.color;
    return GestureDetector(
      onTap: () => _showBurnoutSheet(result),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.favorite_outline_rounded, color: c, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.level.label,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(result.headline,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.colText1,
                          height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: c, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _moodCheckInCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('👋', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'How are you feeling today?',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.colText1),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showMoodCheckin = false),
                child: Icon(Icons.close_rounded,
                    color: context.colHint, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: MoodType.values.map((m) {
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await MoodStorage.save(m);
                    if (mounted) {
                      setState(() {
                        _currentMood = m;
                        _showMoodCheckin = false;
                      });
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                        right: m == MoodType.values.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: context.colCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colDivider),
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
                                color: context.colText2)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _priorityQueueBanner() {
    final pending = _todayTasks
        .where((t) => t['isCompleted'] != true)
        .length;
    if (pending == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrioritizationScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: context.colPrimaryC, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Priority Queue',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colText1)),
                  Text('See which of your $pending tasks to do first',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.colText2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colIcon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _reportsBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: context.colPrimaryC, shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Productivity Reports',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colText1)),
                  Text('Daily & weekly breakdowns with charts',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.colText2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colIcon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _scheduleBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: context.colPrimaryC, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Schedule',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colText1)),
                  Text('Optimised day plan from your tasks',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.colText2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colIcon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _rescheduleAlert() {
    const alertRed = Color(0xFFDC2626);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RescheduleScreen()),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: alertRed.withValues(alpha: context.isDark ? 0.18 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: alertRed.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: alertRed.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded,
                  color: alertRed, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_overdueCount overdue task${_overdueCount > 1 ? "s" : ""}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colText1),
                  ),
                  Text('Tap to reschedule now',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.colText2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colIcon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _teamBanner() {
    final inviteCount = LocalStorage.getTeamInvites()
        .where((i) => i['status'] == 'pending')
        .length;
    final assignedCount = LocalStorage.getAssignedTasks().length;
    final badgeCount = inviteCount + assignedCount;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeamScreen()),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colDivider),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: context.colPrimaryC, shape: BoxShape.circle),
                  child: const Icon(Icons.group_rounded,
                      color: AppColors.primary, size: 18),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFDC2626),
                          shape: BoxShape.circle),
                      child: Text('$badgeCount',
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Teams',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colText1)),
                  Text(
                    badgeCount > 0
                        ? '$badgeCount update${badgeCount > 1 ? "s" : ""} waiting'
                        : 'Share and assign tasks with others',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: context.colText2),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colIcon, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _studyBanner() {
    final assignments = LocalStorage.getAssignments();
    final exams = LocalStorage.getExams();
    final now = DateTime.now();
    final urgentCount = assignments.where((a) {
          if (a['isCompleted'] == true) return false;
          final raw = a['dueDate'] as String?;
          if (raw == null) return false;
          try {
            return DateTime.parse(raw).difference(now).inDays <= 2;
          } catch (_) {
            return false;
          }
        }).length +
        exams.where((e) {
          final raw = e['date'] as String?;
          if (raw == null) return false;
          try {
            final d = DateTime.parse(raw).difference(now).inDays;
            return d >= 0 && d <= 3;
          } catch (_) {
            return false;
          }
        }).length;

    const studyAccent = Color(0xFF6366F1);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudyScreen()),
      ).then((_) => _load()),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colDivider),
        ),
        child: Row(children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Color(0x1A6366F1), shape: BoxShape.circle),
                child: const Icon(Icons.school_rounded,
                    color: studyAccent, size: 18),
              ),
              if (urgentCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Color(0xFFDC2626), shape: BoxShape.circle),
                    child: Text('$urgentCount',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Mode',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colText1)),
                Text(
                  urgentCount > 0
                      ? '$urgentCount item${urgentCount > 1 ? "s" : ""} need attention'
                      : 'Assignments, exams & revision plans',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: context.colText2),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: context.colIcon, size: 20),
        ]),
      ),
    );
  }

  Widget _gamificationBanner() {
    final data = _gamData;
    if (data == null) return const SizedBox.shrink();

    final level = data.level;
    final levelColor = gamificationLevelColor(level);
    final progress = data.levelProgress;
    final streak = data.currentStreak;
    final earnedCount = data.earnedBadgeIds.length;
    final isMaxLevel = level >= 10;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
      ).then((_) => setState(() => _gamData = GamificationEngine.load())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              levelColor.withValues(alpha: context.isDark ? 0.20 : 0.12),
              levelColor.withValues(alpha: context.isDark ? 0.06 : 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: levelColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level badge + streak + chevron
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv. $level',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                gamificationLevelLabel(level),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colText1),
              ),
              const Spacer(),
              if (streak > 0) ...[
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text(
                  '${streak}d',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF97316)),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: levelColor, size: 18),
            ]),
            const SizedBox(height: 10),

            // XP progress bar
            Row(children: [
              Text(
                '${data.xp} XP',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.colText2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: levelColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(levelColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isMaxLevel ? 'MAX' : '${data.nextLevelXP} XP',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.colText2),
              ),
            ]),
            const SizedBox(height: 8),

            // Stats row
            Row(children: [
              Icon(Icons.emoji_events_rounded,
                  size: 12, color: context.colHint),
              const SizedBox(width: 4),
              Text(
                '$earnedCount badge${earnedCount != 1 ? "s" : ""} earned',
                style: GoogleFonts.inter(
                    fontSize: 11, color: context.colText2),
              ),
              const SizedBox(width: 14),
              Icon(Icons.task_alt_rounded,
                  size: 12, color: context.colHint),
              const SizedBox(width: 4),
              Text(
                '${data.totalTasksCompleted} tasks done',
                style: GoogleFonts.inter(
                    fontSize: 11, color: context.colText2),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Health banner ────────────────────────────────────────────────────────────

  List<dynamic> get _displayedTasks {
    final entry = _healthEntry;
    if (entry == null) return _todayTasks;
    final workload = HealthEngine.computeWorkload(entry);
    return HealthEngine.filteredTasks(_todayTasks, workload);
  }

  bool get _isWorkloadFiltered {
    final entry = _healthEntry;
    if (entry == null) return false;
    final workload = HealthEngine.computeWorkload(entry);
    return workload == WorkloadLevel.rest || workload == WorkloadLevel.light;
  }

  Widget _healthBanner() {
    const accent = Color(0xFF0D9488);
    final entry = _healthEntry;

    // No check-in yet — show a subtle prompt
    if (entry == null) {
      return GestureDetector(
        onTap: () => showHealthCheckInSheet(context)
            .then((_) => setState(() => _healthEntry = HealthEngine.todayEntry())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: context.colCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colDivider),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Color(0x120D9488), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded,
                  color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Check-in',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colText1)),
                  Text("Log sleep & energy for today's workload plan",
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.colText2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colIcon, size: 20),
          ]),
        ),
      );
    }

    // Check-in done — show status card
    final workload = HealthEngine.computeWorkload(entry);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HealthScreen()),
      ).then((_) => setState(() => _healthEntry = HealthEngine.todayEntry())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              workload.color.withValues(alpha: context.isDark ? 0.18 : 0.10),
              workload.color.withValues(alpha: context.isDark ? 0.05 : 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: workload.color.withValues(alpha: 0.28)),
        ),
        child: Row(children: [
          Text(workload.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${workload.label} · ${workload.emoji}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: workload.color)),
                const SizedBox(height: 2),
                Row(children: [
                  Text('😴 ${_sleepText(entry.sleepHours)}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: context.colText2)),
                  const SizedBox(width: 10),
                  Text('⚡ ${entry.energyLevel}/5',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: context.colText2)),
                  const SizedBox(width: 10),
                  Text(entry.mood.emoji,
                      style: const TextStyle(fontSize: 13)),
                ]),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: workload.color, size: 20),
        ]),
      ),
    );
  }

  // ── Deadline banner ──────────────────────────────────────────────────────────

  Widget _deadlineBanner() {
    final report = _deadlineReport;
    if (report == null || report.predictions.isEmpty || report.warningCount == 0) {
      return const SizedBox.shrink();
    }

    final worst = report.worstLevel;
    final c = worst.color;
    final count = report.warningCount;

    final subtitle = [
      if (report.overdueCount > 0) '${report.overdueCount} overdue',
      if (report.criticalCount > 0) '${report.criticalCount} critical',
      if (report.atRiskCount > 0) '${report.atRiskCount} at risk',
    ].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeadlineScreen()),
      ).then((_) => setState(() => _deadlineReport = DeadlinePredictor.analyze())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: c.withValues(alpha: context.isDark ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.30)),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Text(worst.emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 2.2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count deadline${count > 1 ? "s" : ""} need attention',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.colText1),
                ),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: c, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c, size: 20),
        ]),
      ),
    );
  }

  Widget _workloadFilterNotice() {
    final entry = _healthEntry!;
    final workload = HealthEngine.computeWorkload(entry);
    final hidden = _todayTasks.length - _displayedTasks.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: workload.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: workload.color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(workload.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hidden > 0
                ? '${workload.label}: showing priority tasks only · $hidden lower-priority task${hidden > 1 ? "s" : ""} hidden'
                : '${workload.label}: only high-priority tasks shown today',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: workload.color),
          ),
        ),
      ]),
    );
  }

  String _sleepText(double h) {
    final hrs = h.floor();
    final mins = ((h - hrs) * 60).round();
    if (mins == 0) return '${hrs}h';
    return '${hrs}h ${mins}m';
  }

  Widget _suggestionCard({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required bool filled,
    required VoidCallback onAction,
    int? durationMins,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: context.colPrimaryC,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const Spacer(),
            if (durationMins != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$durationMins min',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        const SizedBox(height: 5),
        Text(description,
            style: GoogleFonts.inter(
                fontSize: 13, color: context.colText2, height: 1.5)),
        const SizedBox(height: 14),
        if (filled)
          GestureDetector(
            onTap: onAction,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                  gradient: AppColors.darkButtonGradient,
                  borderRadius: BorderRadius.circular(22)),
              alignment: Alignment.center,
              child: Text(actionLabel,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          )
        else
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
            ),
            child: Text(actionLabel,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _taskItem({required Map<String, dynamic> task}) {
    final priority = task['priority'] ?? 'MEDIUM';
    final isCompleted = task['isCompleted'] == true;
    final priorityColor = priority == 'HIGH' || priority == 'URGENT'
        ? AppColors.priorityHigh
        : priority == 'MEDIUM'
            ? AppColors.priorityMedium
            : AppColors.priorityLow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted ? context.colTaskDone : context.colSurfaceVar,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
              color: isCompleted ? Colors.grey.shade300 : priorityColor,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task['title'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? context.colHint : context.colText1,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: context.colHint)),
              if (task['startTime'] != null)
                Text(
                  _formatTime(task['startTime']),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: context.colText2),
                ),
            ],
          ),
        ),
        // Complete toggle — moves to Completed Today section
        GestureDetector(
          onTap: () async {
            if (!isCompleted) {
              List<BadgeDef> newBadges = [];
              try {
                await _taskService.completeTask(task['id']);
                await LocalNotificationService.cancelAllReminders(task['id'] as String);
                newBadges = await GamificationEngine.onTaskCompleted(
                  task: Map<String, dynamic>.from(task as Map),
                );
              } catch (_) {}
              if (mounted) {
                setState(() {
                  _todayTasks.removeWhere((t) => t['id'] == task['id']);
                  _completedTasks.insert(0, {...task, 'isCompleted': true});
                  _gamData = GamificationEngine.load();
                });
                for (final badge in newBadges) {
                  await BadgeUnlockOverlay.show(context, badge);
                }
              }
            }
          },
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? AppColors.primary : AppColors.textHint,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
        // Delete button — safe, removes from both lists
        GestureDetector(
          onTap: () async {
            final taskId = task['id'] as String;
            setState(() {
              _todayTasks.removeWhere((t) => t['id'] == taskId);
              _completedTasks.removeWhere((t) => t['id'] == taskId);
            });
            try {
              await Future.wait([
                _taskService.deleteTask(taskId),
                LocalNotificationService.cancelAllReminders(taskId),
              ]);
            } catch (_) {}
          },
          child: Icon(Icons.delete_outline_rounded,
              color: context.colHint, size: 20),
        ),
      ]),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }
}
