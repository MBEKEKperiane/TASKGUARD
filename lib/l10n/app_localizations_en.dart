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
}
