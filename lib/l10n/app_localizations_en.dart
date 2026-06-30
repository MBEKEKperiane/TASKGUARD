// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingOptimized => 'OPTIMIZED';

  @override
  String get onboardingDeepWorkFound => 'Deep Work Found';

  @override
  String get onboardingWellness => 'WELLNESS';

  @override
  String get onboardingStressMinimized => 'Stress Minimized';

  @override
  String get onboardingTitle => 'AI for your Peace\nof Mind.';

  @override
  String get onboardingSubtitle =>
      'Let our neural engine handle the chaos\nwhile you focus on what truly matters.\nPrecision scheduling, automated.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailHint => 'name@company.com';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get logIn => 'Log In';

  @override
  String get or => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get newHere => 'New here? ';

  @override
  String get signUp => 'Sign Up';

  @override
  String get securedByEncryption => 'Secured by TaskGuard Encryption';

  @override
  String get stressFreePrecision => 'Stress-free precision for your workflow.';

  @override
  String get enterEmailAndPassword => 'Please enter your email and password.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterEmailToReset =>
      'Enter the email address linked to your account. We\'ll send you a 6-digit code.';

  @override
  String get close => 'Close';

  @override
  String get sendCode => 'Send Code';

  @override
  String get resetCodeSentCheckInbox => 'Code sent! Check your inbox.';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get chooseNewPasswordSubtitle =>
      'Choose a new password for your account.';

  @override
  String get newPassword => 'New Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get beginWorkflowJourney => 'Begin your AI-powered workflow journey.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccountQ => 'Already have an account? ';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters.';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get weSentCodeTo => 'We sent a 6-digit code to';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get checkSpamCodeExpires =>
      'Check your spam or junk folder if the email doesn\'t arrive within a few minutes. The code expires in 10 minutes.';

  @override
  String get useDifferentAccount => 'Use a different account';

  @override
  String get enterSixDigitCode => 'Please enter the 6-digit code.';

  @override
  String get invalidOrExpiredCode =>
      'Invalid or expired code. Please try again.';

  @override
  String get codeResentCheckInbox => 'Code resent! Check your inbox.';

  @override
  String get failedToResendCode => 'Failed to resend code. Please try again.';

  @override
  String get loginSuccessful => 'Login successful!';

  @override
  String get settings => 'Settings';

  @override
  String get manageYourPreferences => 'Manage your preferences.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Alerts, email & push preferences';

  @override
  String get theme => 'Theme';

  @override
  String get themeSubtitle => 'Light, dark & colour options';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'App display language';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get privacySettingsSubtitle => 'Data security & AI training controls';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get accountSettingsSubtitle => 'Profile, wellness & sign out';

  @override
  String get selectPreferredLanguage => 'Select your preferred language.';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name.';
  }

  @override
  String priorityTasksToday(int count) {
    return 'You have $count priority tasks today.';
  }

  @override
  String get smartSuggestions => 'Smart Suggestions';

  @override
  String get productivityLabel => 'PRODUCTIVITY';

  @override
  String acceptDuration(int mins) {
    return 'Accept · $mins min';
  }

  @override
  String get upcomingTasks => 'Upcoming Tasks';

  @override
  String get noPendingTasks => 'No pending tasks — great job!';

  @override
  String get restUpUrgentOnly => 'Rest up — only urgent tasks shown today.';

  @override
  String get completedToday => 'Completed Today';

  @override
  String get aiPowered => 'AI Powered';

  @override
  String get howAreYouFeeling => 'How are you feeling today?';

  @override
  String get aiPriorityQueue => 'AI Priority Queue';

  @override
  String seeWhichTasksFirst(int pending) {
    return 'See which of your $pending tasks to do first';
  }

  @override
  String get productivityReports => 'Productivity Reports';

  @override
  String get dailyWeeklyBreakdowns => 'Daily & weekly breakdowns with charts';

  @override
  String get aiSchedule => 'AI Schedule';

  @override
  String get optimisedDayPlan => 'Optimised day plan from your tasks';

  @override
  String overdueTasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue tasks',
      one: '1 overdue task',
    );
    return '$_temp0';
  }

  @override
  String get tapToRescheduleNow => 'Tap to reschedule now';

  @override
  String get teams => 'Teams';

  @override
  String updatesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updates waiting',
      one: '1 update waiting',
    );
    return '$_temp0';
  }

  @override
  String get shareAndAssignTasks => 'Share and assign tasks with others';

  @override
  String get studyMode => 'Study Mode';

  @override
  String itemsNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need attention',
      one: '1 item needs attention',
    );
    return '$_temp0';
  }

  @override
  String get assignmentsExamsRevision => 'Assignments, exams & revision plans';

  @override
  String levelShort(int level) {
    return 'Lv. $level';
  }

  @override
  String badgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges earned',
      one: '1 badge earned',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int count) {
    return '$count tasks done';
  }

  @override
  String get healthCheckIn => 'Health Check-in';

  @override
  String get logSleepEnergy => 'Log sleep & energy for today\'s workload plan';

  @override
  String deadlinesNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deadlines need attention',
      one: '1 deadline needs attention',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int mins) {
    return '$mins min';
  }

  @override
  String get tapThemeToApply => 'Tap a theme to apply it instantly.';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDesc => 'Clean white background, easy on the eyes';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDesc => 'Deep dark background for night use';

  @override
  String get themePink => 'Pink Precision';

  @override
  String get themePinkDesc =>
      'Vibrant pink accent — the TaskGuard signature look';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get enablePushNotifications => 'Enable Push Notifications';

  @override
  String get masterToggleAllAlerts => 'Master toggle for all alerts';

  @override
  String get taskReminders => 'Task Reminders';

  @override
  String get getRemindedBeforeDue => 'Get reminded before tasks are due';

  @override
  String get focusSessionAlerts => 'Focus Session Alerts';

  @override
  String get timerStartEndNotifications => 'Timer start and end notifications';

  @override
  String get burnoutWarnings => 'Burnout Warnings';

  @override
  String get aiWellnessOverloadAlerts => 'AI wellness & overload alerts';

  @override
  String get alarmSound => 'Alarm Sound';

  @override
  String get changeAlarmRingtone => 'Change Alarm Ringtone';

  @override
  String get chooseAlarmSound => 'Choose the sound that plays for task alarms';

  @override
  String get summaries => 'Summaries';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get morningBriefing => 'Morning briefing of your day\'s plan';

  @override
  String get emailDigest => 'Email Digest';

  @override
  String get weeklyReportViaEmail => 'Weekly productivity report via email';

  @override
  String get notificationPreferencesSaved => 'Notification preferences saved.';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get changeAlarmSound => 'Change Alarm Sound';

  @override
  String get followStepsOnPhone => 'Follow these steps on your phone:';

  @override
  String get ringtoneStep1 => '1. Open phone Settings';

  @override
  String get ringtoneStep2 => '2. Go to Apps → TaskGuard AI';

  @override
  String get ringtoneStep3 => '3. Tap Notifications';

  @override
  String get ringtoneStep4 => '4. Tap \"Task Alarms\"';

  @override
  String get ringtoneStep5 => '5. Tap Sound and choose your ringtone';

  @override
  String get checkAlarmVolumeNotMuted =>
      'Also check that your Alarm volume is not muted (use volume buttons while an alarm plays).';

  @override
  String get gotIt => 'Got it';

  @override
  String get privacy => 'Privacy';

  @override
  String get aiAndData => 'AI & Data';

  @override
  String get aiModelTraining => 'AI Model Training';

  @override
  String get allowTaskGuardImproveAi =>
      'Allow TaskGuard to use your data to improve AI responses';

  @override
  String get usageAnalytics => 'Usage Analytics';

  @override
  String get shareAnonymisedUsage =>
      'Share anonymised usage data to improve the app';

  @override
  String get crashReports => 'Crash Reports';

  @override
  String get autoSendCrashLogs => 'Automatically send crash logs to our team';

  @override
  String get yourData => 'Your Data';

  @override
  String get dataExport => 'Data Export';

  @override
  String get includeDataInExports =>
      'Include your data in periodic export packages';

  @override
  String get exportMyData => 'Export My Data';

  @override
  String get downloadAllYourData =>
      'Download all your tasks, sessions and insights';

  @override
  String get exportRequestedEmail =>
      'Export requested. You\'ll receive an email shortly.';

  @override
  String get deleteMyAccount => 'Delete My Account';

  @override
  String get permanentlyRemoveData =>
      'Permanently remove all your data from TaskGuard';

  @override
  String get privacySettingsSaved => 'Privacy settings saved.';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get deleteAccountQ => 'Delete Account?';

  @override
  String get deleteAccountWarning =>
      'This will permanently delete all your data. This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get profile => 'Profile';

  @override
  String get save => 'Save';

  @override
  String get account => 'Account';

  @override
  String get emailCannotBeChanged => 'Email cannot be changed.';

  @override
  String get wellness => 'Wellness';

  @override
  String get strengthLevel => 'Strength Level';

  @override
  String get currentMood => 'Current Mood';

  @override
  String get sleepHours => 'Sleep Hours';

  @override
  String sleepHoursValue(int hours) {
    return '$hours hrs';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty.';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get savedOfflineWillSync =>
      'Saved offline — will sync when connected.';
}
