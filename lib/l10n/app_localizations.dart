import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @onboardingOptimized.
  ///
  /// In en, this message translates to:
  /// **'OPTIMIZED'**
  String get onboardingOptimized;

  /// No description provided for @onboardingDeepWorkFound.
  ///
  /// In en, this message translates to:
  /// **'Deep Work Found'**
  String get onboardingDeepWorkFound;

  /// No description provided for @onboardingWellness.
  ///
  /// In en, this message translates to:
  /// **'WELLNESS'**
  String get onboardingWellness;

  /// No description provided for @onboardingStressMinimized.
  ///
  /// In en, this message translates to:
  /// **'Stress Minimized'**
  String get onboardingStressMinimized;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI for your Peace\nof Mind.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let our neural engine handle the chaos\nwhile you focus on what truly matters.\nPrecision scheduling, automated.'**
  String get onboardingSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get alreadyHaveAccount;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@company.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get newHere;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @securedByEncryption.
  ///
  /// In en, this message translates to:
  /// **'Secured by TaskGuard Encryption'**
  String get securedByEncryption;

  /// No description provided for @stressFreePrecision.
  ///
  /// In en, this message translates to:
  /// **'Stress-free precision for your workflow.'**
  String get stressFreePrecision;

  /// No description provided for @enterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get enterEmailAndPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'A password reset link has been sent to {email}.'**
  String resetLinkSentTo(String email);

  /// No description provided for @enterEmailForResetLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get enterEmailForResetLink;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendLink;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @beginWorkflowJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your AI-powered workflow journey.'**
  String get beginWorkflowJourney;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccountQ;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fillAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @weSentCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to'**
  String get weSentCodeTo;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @checkSpamCodeExpires.
  ///
  /// In en, this message translates to:
  /// **'Check your spam or junk folder if the email doesn\'t arrive within a few minutes. The code expires in 10 minutes.'**
  String get checkSpamCodeExpires;

  /// No description provided for @useDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get useDifferentAccount;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code.'**
  String get enterSixDigitCode;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get invalidOrExpiredCode;

  /// No description provided for @codeResentCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Code resent! Check your inbox.'**
  String get codeResentCheckInbox;

  /// No description provided for @failedToResendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code. Please try again.'**
  String get failedToResendCode;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccessful;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @manageYourPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your preferences.'**
  String get manageYourPreferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts, email & push preferences'**
  String get notificationsSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark & colour options'**
  String get themeSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get languageSubtitle;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @privacySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data security & AI training controls'**
  String get privacySettingsSubtitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @accountSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile, wellness & sign out'**
  String get accountSettingsSubtitle;

  /// No description provided for @selectPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language.'**
  String get selectPreferredLanguage;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}.'**
  String greetingWithName(String greeting, String name);

  /// No description provided for @priorityTasksToday.
  ///
  /// In en, this message translates to:
  /// **'You have {count} priority tasks today.'**
  String priorityTasksToday(int count);

  /// No description provided for @smartSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get smartSuggestions;

  /// No description provided for @productivityLabel.
  ///
  /// In en, this message translates to:
  /// **'PRODUCTIVITY'**
  String get productivityLabel;

  /// No description provided for @acceptDuration.
  ///
  /// In en, this message translates to:
  /// **'Accept · {mins} min'**
  String acceptDuration(int mins);

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @noPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks — great job!'**
  String get noPendingTasks;

  /// No description provided for @restUpUrgentOnly.
  ///
  /// In en, this message translates to:
  /// **'Rest up — only urgent tasks shown today.'**
  String get restUpUrgentOnly;

  /// No description provided for @completedToday.
  ///
  /// In en, this message translates to:
  /// **'Completed Today'**
  String get completedToday;

  /// No description provided for @aiPowered.
  ///
  /// In en, this message translates to:
  /// **'AI Powered'**
  String get aiPowered;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howAreYouFeeling;

  /// No description provided for @aiPriorityQueue.
  ///
  /// In en, this message translates to:
  /// **'AI Priority Queue'**
  String get aiPriorityQueue;

  /// No description provided for @seeWhichTasksFirst.
  ///
  /// In en, this message translates to:
  /// **'See which of your {pending} tasks to do first'**
  String seeWhichTasksFirst(int pending);

  /// No description provided for @productivityReports.
  ///
  /// In en, this message translates to:
  /// **'Productivity Reports'**
  String get productivityReports;

  /// No description provided for @dailyWeeklyBreakdowns.
  ///
  /// In en, this message translates to:
  /// **'Daily & weekly breakdowns with charts'**
  String get dailyWeeklyBreakdowns;

  /// No description provided for @aiSchedule.
  ///
  /// In en, this message translates to:
  /// **'AI Schedule'**
  String get aiSchedule;

  /// No description provided for @optimisedDayPlan.
  ///
  /// In en, this message translates to:
  /// **'Optimised day plan from your tasks'**
  String get optimisedDayPlan;

  /// No description provided for @overdueTasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 overdue task} other{{count} overdue tasks}}'**
  String overdueTasksCount(int count);

  /// No description provided for @tapToRescheduleNow.
  ///
  /// In en, this message translates to:
  /// **'Tap to reschedule now'**
  String get tapToRescheduleNow;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @updatesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 update waiting} other{{count} updates waiting}}'**
  String updatesWaiting(int count);

  /// No description provided for @shareAndAssignTasks.
  ///
  /// In en, this message translates to:
  /// **'Share and assign tasks with others'**
  String get shareAndAssignTasks;

  /// No description provided for @studyMode.
  ///
  /// In en, this message translates to:
  /// **'Study Mode'**
  String get studyMode;

  /// No description provided for @itemsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item needs attention} other{{count} items need attention}}'**
  String itemsNeedAttention(int count);

  /// No description provided for @assignmentsExamsRevision.
  ///
  /// In en, this message translates to:
  /// **'Assignments, exams & revision plans'**
  String get assignmentsExamsRevision;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String levelShort(int level);

  /// No description provided for @badgesEarned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 badge earned} other{{count} badges earned}}'**
  String badgesEarned(int count);

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks done'**
  String tasksDone(int count);

  /// No description provided for @healthCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Health Check-in'**
  String get healthCheckIn;

  /// No description provided for @logSleepEnergy.
  ///
  /// In en, this message translates to:
  /// **'Log sleep & energy for today\'s workload plan'**
  String get logSleepEnergy;

  /// No description provided for @deadlinesNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 deadline needs attention} other{{count} deadlines need attention}}'**
  String deadlinesNeedAttention(int count);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{mins} min'**
  String minutesShort(int mins);

  /// No description provided for @tapThemeToApply.
  ///
  /// In en, this message translates to:
  /// **'Tap a theme to apply it instantly.'**
  String get tapThemeToApply;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean white background, easy on the eyes'**
  String get themeLightDesc;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep dark background for night use'**
  String get themeDarkDesc;

  /// No description provided for @themePink.
  ///
  /// In en, this message translates to:
  /// **'Pink Precision'**
  String get themePink;

  /// No description provided for @themePinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrant pink accent — the TaskGuard signature look'**
  String get themePinkDesc;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @enablePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Push Notifications'**
  String get enablePushNotifications;

  /// No description provided for @masterToggleAllAlerts.
  ///
  /// In en, this message translates to:
  /// **'Master toggle for all alerts'**
  String get masterToggleAllAlerts;

  /// No description provided for @taskReminders.
  ///
  /// In en, this message translates to:
  /// **'Task Reminders'**
  String get taskReminders;

  /// No description provided for @getRemindedBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'Get reminded before tasks are due'**
  String get getRemindedBeforeDue;

  /// No description provided for @focusSessionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Focus Session Alerts'**
  String get focusSessionAlerts;

  /// No description provided for @timerStartEndNotifications.
  ///
  /// In en, this message translates to:
  /// **'Timer start and end notifications'**
  String get timerStartEndNotifications;

  /// No description provided for @burnoutWarnings.
  ///
  /// In en, this message translates to:
  /// **'Burnout Warnings'**
  String get burnoutWarnings;

  /// No description provided for @aiWellnessOverloadAlerts.
  ///
  /// In en, this message translates to:
  /// **'AI wellness & overload alerts'**
  String get aiWellnessOverloadAlerts;

  /// No description provided for @alarmSound.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get alarmSound;

  /// No description provided for @changeAlarmRingtone.
  ///
  /// In en, this message translates to:
  /// **'Change Alarm Ringtone'**
  String get changeAlarmRingtone;

  /// No description provided for @chooseAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Choose the sound that plays for task alarms'**
  String get chooseAlarmSound;

  /// No description provided for @summaries.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get summaries;

  /// No description provided for @dailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// No description provided for @morningBriefing.
  ///
  /// In en, this message translates to:
  /// **'Morning briefing of your day\'s plan'**
  String get morningBriefing;

  /// No description provided for @emailDigest.
  ///
  /// In en, this message translates to:
  /// **'Email Digest'**
  String get emailDigest;

  /// No description provided for @weeklyReportViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Weekly productivity report via email'**
  String get weeklyReportViaEmail;

  /// No description provided for @notificationPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences saved.'**
  String get notificationPreferencesSaved;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @changeAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Change Alarm Sound'**
  String get changeAlarmSound;

  /// No description provided for @followStepsOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Follow these steps on your phone:'**
  String get followStepsOnPhone;

  /// No description provided for @ringtoneStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Open phone Settings'**
  String get ringtoneStep1;

  /// No description provided for @ringtoneStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Go to Apps → TaskGuard AI'**
  String get ringtoneStep2;

  /// No description provided for @ringtoneStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Tap Notifications'**
  String get ringtoneStep3;

  /// No description provided for @ringtoneStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Tap \"Task Alarms\"'**
  String get ringtoneStep4;

  /// No description provided for @ringtoneStep5.
  ///
  /// In en, this message translates to:
  /// **'5. Tap Sound and choose your ringtone'**
  String get ringtoneStep5;

  /// No description provided for @checkAlarmVolumeNotMuted.
  ///
  /// In en, this message translates to:
  /// **'Also check that your Alarm volume is not muted (use volume buttons while an alarm plays).'**
  String get checkAlarmVolumeNotMuted;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @aiAndData.
  ///
  /// In en, this message translates to:
  /// **'AI & Data'**
  String get aiAndData;

  /// No description provided for @aiModelTraining.
  ///
  /// In en, this message translates to:
  /// **'AI Model Training'**
  String get aiModelTraining;

  /// No description provided for @allowTaskGuardImproveAi.
  ///
  /// In en, this message translates to:
  /// **'Allow TaskGuard to use your data to improve AI responses'**
  String get allowTaskGuardImproveAi;

  /// No description provided for @usageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage Analytics'**
  String get usageAnalytics;

  /// No description provided for @shareAnonymisedUsage.
  ///
  /// In en, this message translates to:
  /// **'Share anonymised usage data to improve the app'**
  String get shareAnonymisedUsage;

  /// No description provided for @crashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash Reports'**
  String get crashReports;

  /// No description provided for @autoSendCrashLogs.
  ///
  /// In en, this message translates to:
  /// **'Automatically send crash logs to our team'**
  String get autoSendCrashLogs;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your Data'**
  String get yourData;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @includeDataInExports.
  ///
  /// In en, this message translates to:
  /// **'Include your data in periodic export packages'**
  String get includeDataInExports;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @downloadAllYourData.
  ///
  /// In en, this message translates to:
  /// **'Download all your tasks, sessions and insights'**
  String get downloadAllYourData;

  /// No description provided for @exportRequestedEmail.
  ///
  /// In en, this message translates to:
  /// **'Export requested. You\'ll receive an email shortly.'**
  String get exportRequestedEmail;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccount;

  /// No description provided for @permanentlyRemoveData.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove all your data from TaskGuard'**
  String get permanentlyRemoveData;

  /// No description provided for @privacySettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings saved.'**
  String get privacySettingsSaved;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @deleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountQ;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your data. This action cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed.'**
  String get emailCannotBeChanged;

  /// No description provided for @wellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellness;

  /// No description provided for @strengthLevel.
  ///
  /// In en, this message translates to:
  /// **'Strength Level'**
  String get strengthLevel;

  /// No description provided for @currentMood.
  ///
  /// In en, this message translates to:
  /// **'Current Mood'**
  String get currentMood;

  /// No description provided for @sleepHours.
  ///
  /// In en, this message translates to:
  /// **'Sleep Hours'**
  String get sleepHours;

  /// No description provided for @sleepHoursValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} hrs'**
  String sleepHoursValue(int hours);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get nameCannotBeEmpty;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @savedOfflineWillSync.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when connected.'**
  String get savedOfflineWillSync;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
