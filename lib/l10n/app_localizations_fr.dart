// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get onboardingOptimized => 'OPTIMISÉ';

  @override
  String get onboardingDeepWorkFound => 'Travail intense trouvé';

  @override
  String get onboardingWellness => 'BIEN-ÊTRE';

  @override
  String get onboardingStressMinimized => 'Stress minimisé';

  @override
  String get onboardingTitle => 'L\'IA pour votre\ntranquillité d\'esprit.';

  @override
  String get onboardingSubtitle =>
      'Laissez notre moteur neuronal gérer le chaos\npendant que vous vous concentrez sur l\'essentiel.\nPlanification de précision, automatisée.';

  @override
  String get getStarted => 'Commencer';

  @override
  String get alreadyHaveAccount => 'J\'ai déjà un compte';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get emailHint => 'nom@entreprise.com';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get logIn => 'Connexion';

  @override
  String get or => 'OU';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get newHere => 'Nouveau ici ? ';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get securedByEncryption => 'Sécurisé par le chiffrement TaskGuard';

  @override
  String get stressFreePrecision =>
      'Précision sans stress pour votre flux de travail.';

  @override
  String get enterEmailAndPassword =>
      'Veuillez saisir votre e-mail et mot de passe.';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String resetLinkSentTo(String email) {
    return 'Un lien de réinitialisation a été envoyé à $email.';
  }

  @override
  String get enterEmailForResetLink =>
      'Saisissez votre e-mail et nous vous envoyons un lien de réinitialisation.';

  @override
  String get close => 'Fermer';

  @override
  String get sendLink => 'Envoyer le lien';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get beginWorkflowJourney =>
      'Commencez votre parcours de travail alimenté par l\'IA.';

  @override
  String get fullName => 'Nom complet';

  @override
  String get fullNameHint => 'Jean Dupont';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get alreadyHaveAccountQ => 'Vous avez déjà un compte ? ';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères.';
}
