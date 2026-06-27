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

  @override
  String get verifyYourEmail => 'Vérifiez votre e-mail';

  @override
  String get weSentCodeTo => 'Nous avons envoyé un code à 6 chiffres à';

  @override
  String get verify => 'Vérifier';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get checkSpamCodeExpires =>
      'Vérifiez votre dossier spam si l\'e-mail n\'arrive pas dans quelques minutes. Le code expire dans 10 minutes.';

  @override
  String get useDifferentAccount => 'Utiliser un autre compte';

  @override
  String get enterSixDigitCode => 'Veuillez saisir le code à 6 chiffres.';

  @override
  String get invalidOrExpiredCode =>
      'Code invalide ou expiré. Veuillez réessayer.';

  @override
  String get codeResentCheckInbox =>
      'Code renvoyé ! Vérifiez votre boîte de réception.';

  @override
  String get failedToResendCode =>
      'Échec de l\'envoi du code. Veuillez réessayer.';

  @override
  String get loginSuccessful => 'Connexion réussie !';

  @override
  String get settings => 'Paramètres';

  @override
  String get manageYourPreferences => 'Gérez vos préférences.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Alertes, préférences e-mail et push';

  @override
  String get theme => 'Thème';

  @override
  String get themeSubtitle => 'Options clair, sombre et couleur';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Langue d\'affichage de l\'application';

  @override
  String get privacySettings => 'Paramètres de confidentialité';

  @override
  String get privacySettingsSubtitle =>
      'Sécurité des données et contrôles d\'entraînement IA';

  @override
  String get accountSettings => 'Paramètres du compte';

  @override
  String get accountSettingsSubtitle => 'Profil, bien-être et déconnexion';

  @override
  String get selectPreferredLanguage => 'Sélectionnez votre langue préférée.';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name.';
  }

  @override
  String priorityTasksToday(int count) {
    return 'Vous avez $count tâches prioritaires aujourd\'hui.';
  }

  @override
  String get smartSuggestions => 'Suggestions intelligentes';

  @override
  String get productivityLabel => 'PRODUCTIVITÉ';

  @override
  String acceptDuration(int mins) {
    return 'Accepter · $mins min';
  }

  @override
  String get upcomingTasks => 'Tâches à venir';

  @override
  String get noPendingTasks => 'Aucune tâche en attente — excellent travail !';

  @override
  String get restUpUrgentOnly =>
      'Détendez-vous — seules les tâches urgentes sont affichées aujourd\'hui.';

  @override
  String get completedToday => 'Terminées aujourd\'hui';

  @override
  String get aiPowered => 'Propulsé par l\'IA';

  @override
  String get howAreYouFeeling => 'Comment vous sentez-vous aujourd\'hui ?';

  @override
  String get aiPriorityQueue => 'File de priorité IA';

  @override
  String seeWhichTasksFirst(int pending) {
    return 'Découvrez lesquelles de vos $pending tâches faire en premier';
  }

  @override
  String get productivityReports => 'Rapports de productivité';

  @override
  String get dailyWeeklyBreakdowns =>
      'Analyses quotidiennes et hebdomadaires avec graphiques';

  @override
  String get aiSchedule => 'Planning IA';

  @override
  String get optimisedDayPlan =>
      'Plan de journée optimisé à partir de vos tâches';

  @override
  String overdueTasksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches en retard',
      one: '1 tâche en retard',
    );
    return '$_temp0';
  }

  @override
  String get tapToRescheduleNow => 'Appuyez pour replanifier maintenant';

  @override
  String get teams => 'Équipes';

  @override
  String updatesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mises à jour en attente',
      one: '1 mise à jour en attente',
    );
    return '$_temp0';
  }

  @override
  String get shareAndAssignTasks =>
      'Partagez et assignez des tâches à d\'autres';

  @override
  String get studyMode => 'Mode étude';

  @override
  String itemsNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments nécessitent votre attention',
      one: '1 élément nécessite votre attention',
    );
    return '$_temp0';
  }

  @override
  String get assignmentsExamsRevision =>
      'Devoirs, examens et plans de révision';

  @override
  String levelShort(int level) {
    return 'Niv. $level';
  }

  @override
  String badgesEarned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges obtenus',
      one: '1 badge obtenu',
    );
    return '$_temp0';
  }

  @override
  String tasksDone(int count) {
    return '$count tâches terminées';
  }

  @override
  String get healthCheckIn => 'Bilan de santé';

  @override
  String get logSleepEnergy =>
      'Enregistrez le sommeil et l\'énergie pour le plan de charge du jour';

  @override
  String deadlinesNeedAttention(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échéances nécessitent votre attention',
      one: '1 échéance nécessite votre attention',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int mins) {
    return '$mins min';
  }
}
