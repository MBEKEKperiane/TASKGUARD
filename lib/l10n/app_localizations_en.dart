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
  String resetLinkSentTo(String email) {
    return 'A password reset link has been sent to $email.';
  }

  @override
  String get enterEmailForResetLink =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get close => 'Close';

  @override
  String get sendLink => 'Send Link';

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
}
