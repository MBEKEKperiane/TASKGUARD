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
