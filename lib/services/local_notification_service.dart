import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/mood/models/mood_entry.dart';

/// Manages all local (offline-capable) notifications for TaskGuard AI.
///
/// Notification types per task:
///   +0  5-minute warning before startTime
///   +1  Start-time alert
///   +2  1-hour deadline warning (only when dueDate ≠ startTime)
///   +3  At-deadline alert
///   +4–+13  Overdue batch: 10 alerts every 30 min (5 hours total)
///
/// ID scheme: base = (taskId.hashCode.abs() % 5000) × 20
/// Allocating 20 slots per task keeps IDs well within Android's int32 range.
class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _reminderChannelId = 'task_reminders_v1';
  static const _deadlineChannelId = 'task_deadline_v1';
  static const _overdueChannelId = 'task_overdue_v1';

  static const _i5min = 0;
  static const _iStart = 1;
  static const _iDeadlineApproach = 2;
  static const _iDeadline = 3;
  static const _iOverdueFirst = 4;
  static const _overdueCount = 10; // every 30 min for the first 5 hours
  static const _iOverdueLongTailFirst = 14;
  static const _overdueLongTailCount = 60; // every 2 hours for ~5 more days
  static const _overdueLongTailIntervalMins = 120;

  static int _base(String taskId) => taskId.hashCode.abs() % 5000 * 100;

  // ── Initialisation ────────────────────────────────────────────────────────

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      _reminderChannelId,
      'Task Reminders',
      description: 'Alerts before tasks begin',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ));
    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      _deadlineChannelId,
      'Deadline Alerts',
      description: 'Notifications when task deadlines are approaching or reached',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ));
    await impl?.createNotificationChannel(const AndroidNotificationChannel(
      _overdueChannelId,
      'Overdue Tasks',
      description: 'Persistent alerts for overdue incomplete tasks',
      importance: Importance.max,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      showBadge: true,
    ));
  }

  /// Call from HomeScreen.initState — needs an active Activity.
  static Future<void> requestPermissions() async {
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
    await impl?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ── Notification detail builders ──────────────────────────────────────────

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _reminderChannelId,
      'Task Reminders',
      channelDescription: 'Alerts before tasks begin',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const _deadlineDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _deadlineChannelId,
      'Deadline Alerts',
      channelDescription: 'Notifications when task deadlines are approaching or reached',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const _overdueDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _overdueChannelId,
      'Overdue Tasks',
      channelDescription: 'Persistent alerts for overdue incomplete tasks',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Core scheduling helper ────────────────────────────────────────────────

  static tz.TZDateTime _toTz(DateTime dt) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, dt.millisecondsSinceEpoch);

  /// Schedules a notification only if [fireAt] is still in the future.
  static Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime fireAt,
    NotificationDetails details,
  ) async {
    if (!fireAt.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _toTz(fireAt),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Schedule all applicable reminders for a task.
  ///
  /// - 5-minute warning before [startTime]
  /// - Alert at [startTime]
  /// - 1-hour warning before [dueDate] (skipped when dueDate ≈ startTime)
  /// - Alert at [dueDate]
  /// - 10 overdue alerts every 30 min (5 hours) anchored at [dueDate] or [startTime]
  static Future<void> scheduleAllReminders({
    required String taskId,
    required String taskTitle,
    DateTime? startTime,
    DateTime? dueDate,
  }) async {
    final base = _base(taskId);
    final futures = <Future<void>>[];

    // ── Start-time reminders ──────────────────────────────────────────────
    if (startTime != null) {
      futures.add(_schedule(
        base + _i5min,
        '⏰ Starting Soon',
        '"$taskTitle" begins in 5 minutes',
        startTime.subtract(const Duration(minutes: 5)),
        _reminderDetails,
      ));
      futures.add(_schedule(
        base + _iStart,
        '🚀 Task Starting Now',
        '"$taskTitle" is starting — open TaskGuard to begin',
        startTime,
        _reminderDetails,
      ));
    }

    // ── Deadline reminders ────────────────────────────────────────────────
    if (dueDate != null) {
      // Only fire separate deadline alerts when dueDate meaningfully differs from startTime
      final distinct = startTime == null ||
          dueDate.difference(startTime).abs() > const Duration(minutes: 2);

      if (distinct) {
        futures.add(_schedule(
          base + _iDeadlineApproach,
          '⚠️ Deadline in 1 Hour',
          '"$taskTitle" is due soon — wrap it up',
          dueDate.subtract(const Duration(hours: 1)),
          _deadlineDetails,
        ));
        futures.add(_schedule(
          base + _iDeadline,
          '🔴 Deadline Reached',
          '"$taskTitle" is due now — mark it done or reschedule',
          dueDate,
          _deadlineDetails,
        ));
      }
    }

    // ── Overdue batch ─────────────────────────────────────────────────────
    // Anchors at dueDate when provided, otherwise at startTime. Keeps
    // nudging every 30 min for 5 hours, then every 2 hours for ~5 more
    // days — all scheduled up front so it keeps firing even if the app
    // is never reopened. cancelAllReminders stops it the moment the task
    // is marked done.
    final anchor = dueDate ?? startTime;
    if (anchor != null) {
      for (int i = 0; i < _overdueCount; i++) {
        final delayMins = (i + 1) * 30;
        futures.add(_schedule(
          base + _iOverdueFirst + i,
          '🚨 Task Overdue',
          '"$taskTitle" is $delayMins min overdue — still needs attention',
          anchor.add(Duration(minutes: delayMins)),
          _overdueDetails,
        ));
      }
      final firstTailDelay = _overdueCount * 30;
      for (int i = 0; i < _overdueLongTailCount; i++) {
        final delayMins = firstTailDelay + (i + 1) * _overdueLongTailIntervalMins;
        futures.add(_schedule(
          base + _iOverdueLongTailFirst + i,
          '🚨 Task Still Overdue',
          '"$taskTitle" is still not done — mark it complete to stop these reminders',
          anchor.add(Duration(minutes: delayMins)),
          _overdueDetails,
        ));
      }
    }

    await Future.wait(futures);
  }

  /// Re-schedules fresh overdue batches for tasks whose original 5-hour window
  /// has fully expired. Call on every home-screen load so alerts keep firing
  /// until the task is marked done, even after days of being overdue.
  static Future<void> rescheduleOverdueAlerts(
    List<Map<String, dynamic>> pendingTasks,
  ) async {
    final now = DateTime.now();
    final futures = <Future<void>>[];

    for (final task in pendingTasks) {
      if (task['isCompleted'] == true) continue;
      final taskId = task['id'] as String?;
      final title = task['title'] as String? ?? 'Task';
      final anchorStr = (task['dueDate'] ?? task['startTime']) as String?;
      if (taskId == null || anchorStr == null) continue;

      final anchor = DateTime.tryParse(anchorStr);
      if (anchor == null || anchor.isAfter(now)) continue;

      // The upfront batch already covers 5 hours + ~5 days. Only re-batch
      // once that entire window has elapsed.
      final batchEnd = anchor.add(Duration(
          minutes: _overdueCount * 30 +
              _overdueLongTailCount * _overdueLongTailIntervalMins));
      if (batchEnd.isAfter(now)) continue;

      // Every slot has fired — schedule a fresh window from now.
      final base = _base(taskId);
      final hoursSince = now.difference(anchor).inHours;
      for (int i = 0; i < _overdueCount; i++) {
        final delayMins = (i + 1) * 30;
        futures.add(_schedule(
          base + _iOverdueFirst + i,
          '🚨 Task Still Overdue',
          '"$title" is ~${hoursSince}h overdue — open TaskGuard to resolve',
          now.add(Duration(minutes: delayMins)),
          _overdueDetails,
        ));
      }
      final firstTailDelay = _overdueCount * 30;
      for (int i = 0; i < _overdueLongTailCount; i++) {
        final delayMins = firstTailDelay + (i + 1) * _overdueLongTailIntervalMins;
        futures.add(_schedule(
          base + _iOverdueLongTailFirst + i,
          '🚨 Task Still Overdue',
          '"$title" is ~${hoursSince}h overdue — mark it complete to stop these reminders',
          now.add(Duration(minutes: delayMins)),
          _overdueDetails,
        ));
      }
    }

    await Future.wait(futures);
  }

  /// Cancel every scheduled notification for [taskId].
  /// Call when a task is completed, deleted, or rescheduled.
  static Future<void> cancelAllReminders(String taskId) async {
    final base = _base(taskId);
    await Future.wait([
      for (int i = 0; i < _iOverdueLongTailFirst + _overdueLongTailCount; i++)
        _plugin.cancel(base + i),
    ]);
  }

  /// Cancel everything — call on logout.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Break reminders ───────────────────────────────────────────────────────

  static const _kBreakNotifId = 99001;
  static const _breakChannelId = 'break_reminders_v1';

  static const _breakDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _breakChannelId,
      'Break Reminders',
      channelDescription: 'Friendly reminders to take a break',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: false,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    ),
  );

  static String _breakBody(MoodType? mood) => switch (mood) {
        MoodType.tired =>
          'You\'re tired — step away and rest for a few minutes.',
        MoodType.stressed =>
          'A short break clears stress better than pushing through.',
        MoodType.motivated =>
          'Even peak performers need recovery. Take 5 minutes.',
        _ => 'Time for a quick break to keep your focus sharp.',
      };

  /// Schedule a break reminder notification at [fireAt].
  static Future<void> scheduleBreakReminder(
    DateTime fireAt, {
    MoodType? mood,
  }) async {
    await cancelBreakReminder(); // Replace any existing one
    await _schedule(
      _kBreakNotifId,
      '☕  Break time',
      _breakBody(mood),
      fireAt,
      _breakDetails,
    );
  }

  /// Cancel any pending break reminder.
  static Future<void> cancelBreakReminder() =>
      _plugin.cancel(_kBreakNotifId);

  // ── Backward-compat aliases ───────────────────────────────────────────────

  static Future<int> scheduleTaskAlarm({
    required String taskId,
    required String taskTitle,
    required DateTime remindAt,
  }) async {
    await scheduleAllReminders(
      taskId: taskId,
      taskTitle: taskTitle,
      startTime: remindAt,
    );
    return 1;
  }

  static Future<void> cancelTaskAlarm(String taskId) =>
      cancelAllReminders(taskId);
}
