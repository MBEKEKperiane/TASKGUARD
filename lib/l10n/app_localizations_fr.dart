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
  String get enterEmailToReset =>
      'Saisissez l\'e-mail lié à votre compte. Nous vous enverrons un code à 6 chiffres.';

  @override
  String get close => 'Fermer';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get resetCodeSentCheckInbox =>
      'Code envoyé ! Vérifiez votre boîte de réception.';

  @override
  String get setNewPassword => 'Définir un nouveau mot de passe';

  @override
  String get chooseNewPasswordSubtitle =>
      'Choisissez un nouveau mot de passe pour votre compte.';

  @override
  String get newPassword => 'Nouveau mot de passe';

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

  @override
  String get tapThemeToApply =>
      'Appuyez sur un thème pour l\'appliquer instantanément.';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeLightDesc => 'Fond blanc épuré, agréable pour les yeux';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeDarkDesc =>
      'Fond sombre profond pour une utilisation nocturne';

  @override
  String get themePink => 'Précision rose';

  @override
  String get themePinkDesc =>
      'Accent rose vif — le look signature de TaskGuard';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get enablePushNotifications => 'Activer les notifications push';

  @override
  String get masterToggleAllAlerts =>
      'Interrupteur principal pour toutes les alertes';

  @override
  String get taskReminders => 'Rappels de tâches';

  @override
  String get getRemindedBeforeDue =>
      'Recevez un rappel avant l\'échéance des tâches';

  @override
  String get focusSessionAlerts => 'Alertes de session de concentration';

  @override
  String get timerStartEndNotifications =>
      'Notifications de début et fin de minuteur';

  @override
  String get burnoutWarnings => 'Alertes d\'épuisement';

  @override
  String get aiWellnessOverloadAlerts =>
      'Alertes IA de bien-être et de surcharge';

  @override
  String get alarmSound => 'Son de l\'alarme';

  @override
  String get changeAlarmRingtone => 'Changer la sonnerie d\'alarme';

  @override
  String get chooseAlarmSound =>
      'Choisissez le son joué pour les alarmes de tâches';

  @override
  String get summaries => 'Résumés';

  @override
  String get dailySummary => 'Résumé quotidien';

  @override
  String get morningBriefing => 'Bilan matinal du plan de votre journée';

  @override
  String get emailDigest => 'Résumé par e-mail';

  @override
  String get weeklyReportViaEmail =>
      'Rapport de productivité hebdomadaire par e-mail';

  @override
  String get notificationPreferencesSaved =>
      'Préférences de notification enregistrées.';

  @override
  String get savePreferences => 'Enregistrer les préférences';

  @override
  String get changeAlarmSound => 'Changer le son de l\'alarme';

  @override
  String get followStepsOnPhone => 'Suivez ces étapes sur votre téléphone :';

  @override
  String get ringtoneStep1 => '1. Ouvrez les Paramètres du téléphone';

  @override
  String get ringtoneStep2 => '2. Allez dans Applications → TaskGuard AI';

  @override
  String get ringtoneStep3 => '3. Appuyez sur Notifications';

  @override
  String get ringtoneStep4 => '4. Appuyez sur « Alarmes de tâches »';

  @override
  String get ringtoneStep5 => '5. Appuyez sur Son et choisissez votre sonnerie';

  @override
  String get checkAlarmVolumeNotMuted =>
      'Vérifiez aussi que le volume de l\'alarme n\'est pas coupé (utilisez les boutons de volume pendant qu\'une alarme sonne).';

  @override
  String get gotIt => 'J\'ai compris';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get aiAndData => 'IA et données';

  @override
  String get aiModelTraining => 'Entraînement du modèle IA';

  @override
  String get allowTaskGuardImproveAi =>
      'Autoriser TaskGuard à utiliser vos données pour améliorer les réponses IA';

  @override
  String get usageAnalytics => 'Analyses d\'utilisation';

  @override
  String get shareAnonymisedUsage =>
      'Partager des données d\'utilisation anonymisées pour améliorer l\'application';

  @override
  String get crashReports => 'Rapports de plantage';

  @override
  String get autoSendCrashLogs =>
      'Envoyer automatiquement les journaux de plantage à notre équipe';

  @override
  String get yourData => 'Vos données';

  @override
  String get dataExport => 'Exportation des données';

  @override
  String get includeDataInExports =>
      'Inclure vos données dans les exports périodiques';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get downloadAllYourData =>
      'Téléchargez toutes vos tâches, sessions et analyses';

  @override
  String get exportRequestedEmail =>
      'Exportation demandée. Vous recevrez un e-mail prochainement.';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String get permanentlyRemoveData =>
      'Supprimer définitivement toutes vos données de TaskGuard';

  @override
  String get privacySettingsSaved =>
      'Paramètres de confidentialité enregistrés.';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get deleteAccountQ => 'Supprimer le compte ?';

  @override
  String get deleteAccountWarning =>
      'Cela supprimera définitivement toutes vos données. Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get profile => 'Profil';

  @override
  String get save => 'Enregistrer';

  @override
  String get account => 'Compte';

  @override
  String get emailCannotBeChanged => 'L\'e-mail ne peut pas être modifié.';

  @override
  String get wellness => 'Bien-être';

  @override
  String get strengthLevel => 'Niveau de force';

  @override
  String get currentMood => 'Humeur actuelle';

  @override
  String get sleepHours => 'Heures de sommeil';

  @override
  String sleepHoursValue(int hours) {
    return '$hours h';
  }

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get nameCannotBeEmpty => 'Le nom ne peut pas être vide.';

  @override
  String get profileSaved => 'Profil enregistré.';

  @override
  String get savedOfflineWillSync =>
      'Enregistré hors ligne — synchronisation à la reconnexion.';
}
