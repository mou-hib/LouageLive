// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Louage Live';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get voyageurHomeTitle => 'Espace voyageur';

  @override
  String get chauffeurHomeTitle => 'Espace chauffeur';

  @override
  String get agentHomeTitle => 'Espace agent de station';

  @override
  String get adminHomeTitle => 'Administration';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get genericError => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get loginFailed => 'E-mail ou mot de passe incorrect.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get emailInvalid => 'Adresse e-mail invalide.';

  @override
  String get loginEmailNotConfirmed => 'Adresse e-mail non confirmée.';

  @override
  String get loginTooManyAttempts =>
      'Trop de tentatives, réessayez dans un moment.';

  @override
  String get loginNetworkError => 'Pas de connexion internet.';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get noAccountCreateOne => 'Pas encore de compte ? Créer un compte';

  @override
  String get staffAccountNote =>
      'Chauffeurs et agents : votre compte est créé par l\'administrateur.';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get phone => 'Téléphone';

  @override
  String get phoneHint => 'Ex. 98 123 456';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get phoneInvalid => 'Numéro invalide : 8 chiffres, +216 facultatif.';

  @override
  String passwordTooShort(int min) {
    return 'Au moins $min caractères.';
  }

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas.';

  @override
  String get signUpEmailExists => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get signUpWeakPassword =>
      'Mot de passe trop faible (6 caractères minimum).';

  @override
  String get signUpTooManyAttempts =>
      'Trop de tentatives, réessayez plus tard.';

  @override
  String get checkEmailTitle => 'Vérifiez votre e-mail';

  @override
  String get checkEmailSentTo =>
      'Nous avons envoyé un lien de confirmation à :';

  @override
  String get checkEmailNextStep =>
      'Ouvrez ce lien pour activer votre compte, puis connectez-vous.';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get chauffeurNoLouage =>
      'Aucun louage associé, contactez l\'agent de station.';

  @override
  String louageCapacite(int capacite) {
    String _temp0 = intl.Intl.pluralLogic(
      capacite,
      locale: localeName,
      other: '$capacite places',
      one: '1 place',
    );
    return 'Capacité : $_temp0';
  }

  @override
  String chauffeurInQueue(String station, String ville) {
    return 'Vous êtes dans la file : $station → $ville';
  }

  @override
  String get scanStationQr => 'Scanner le QR de la station';

  @override
  String get scannerHint => 'Placez le QR code de la station dans le cadre.';

  @override
  String get torchOn => 'Allumer la lampe';

  @override
  String get torchOff => 'Éteindre la lampe';

  @override
  String get cameraPermissionDenied =>
      'Autorisez l\'accès à la caméra pour scanner le QR de la station.';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get cameraUnavailable =>
      'Impossible d\'utiliser la caméra sur cet appareil.';

  @override
  String get chooseLine => 'Choisissez votre ligne';

  @override
  String get noActiveLine => 'Aucune ligne active dans cette station.';

  @override
  String tarifDt(String tarif) {
    return '$tarif DT';
  }

  @override
  String joinQueueConfirm(String station, String ville) {
    return 'Rejoindre la file $station → $ville ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get joinQueue => 'Rejoindre';

  @override
  String get joinedQueue => 'Vous avez rejoint la file.';

  @override
  String get fileErrAccesRefuse =>
      'Seuls les chauffeurs peuvent rejoindre une file.';

  @override
  String get fileErrAucunLouage =>
      'Aucun louage actif n\'est associé à votre compte.';

  @override
  String get fileErrQrInvalide =>
      'QR code non reconnu. Scannez le QR de la station.';

  @override
  String get fileErrDejaEnFile => 'Votre louage est déjà dans une file.';

  @override
  String get comingSoon =>
      'Les fonctionnalités arrivent dans les prochains sprints.';

  @override
  String get retry => 'Réessayer';

  @override
  String get profileErrorGeneric =>
      'Impossible de charger votre profil. Réessayez ou contactez l\'administrateur.';

  @override
  String get profileErrorNetwork =>
      'Impossible de charger votre profil. Vérifiez votre connexion internet.';

  @override
  String get configMissing =>
      'Configuration Supabase manquante. Lancez l\'application avec --dart-define-from-file=config/env.json (voir README).';
}
