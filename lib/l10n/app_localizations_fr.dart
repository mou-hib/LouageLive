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
  String signUpWeakPassword(int min) {
    return 'Mot de passe trop faible ($min caractères minimum).';
  }

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
  String get fileErrReservationDejaEnCours =>
      'Vous avez déjà une réservation en cours.';

  @override
  String get fileErrLouagePasEnTete =>
      'Seul le louage en tête de file peut être réservé.';

  @override
  String get fileErrLouagePasComplet =>
      'Le louage doit être complet pour partir.';

  @override
  String get fileErrReservationEnAttente =>
      'Des réservations ne sont pas encore scannées.';

  @override
  String fileErrReservationEnAttenteJusqua(DateTime heure) {
    final intl.DateFormat heureDateFormat = intl.DateFormat.Hm(localeName);
    final String heureString = heureDateFormat.format(heure);

    return 'Une réservation n\'est pas encore scannée. Elle expire à ⁦$heureString⁩.';
  }

  @override
  String get fileErrPlacesSousReservations =>
      'Impossible : moins de places que de réservations.';

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

  @override
  String seatsOccupiedA11y(int occupied, int capacity) {
    String _temp0 = intl.Intl.pluralLogic(
      occupied,
      locale: localeName,
      other: '$occupied places occupées',
      one: '$occupied place occupée',
    );
    return '$_temp0 sur $capacity';
  }

  @override
  String get statusEnAttente => 'En attente';

  @override
  String get statusEnRemplissage => 'En remplissage';

  @override
  String get statusPresqueComplet => 'Presque complet';

  @override
  String get statusComplet => 'Complet';

  @override
  String get statusParti => 'Parti';

  @override
  String get statusRetire => 'Retiré';

  @override
  String get reservationEnAttente => 'En attente';

  @override
  String get reservationConfirmee => 'Confirmée';

  @override
  String get reservationAnnulee => 'Annulée';

  @override
  String get reservationExpiree => 'Expirée';

  @override
  String get queueHead => 'En tête de file';

  @override
  String queueRankA11y(int rank) {
    return 'Rang $rank';
  }

  @override
  String get etaLabel => 'Départ estimé';

  @override
  String get fareLabel => 'Tarif';

  @override
  String get liveNow => 'En direct';

  @override
  String liveUpdatedSecondsAgo(int seconds) {
    return 'Mis à jour il y a $seconds s';
  }

  @override
  String liveUpdatedMinutesAgo(int minutes) {
    return 'Mis à jour il y a $minutes min';
  }

  @override
  String get liveOffline => 'Hors connexion';

  @override
  String get loading => 'Chargement…';

  @override
  String get seatStepperRemove => 'Retirer une place';

  @override
  String get seatStepperAdd => 'Ajouter une place';

  @override
  String seatStepperValueA11y(int value) {
    return 'Places : $value';
  }

  @override
  String get galleryTitle => 'Galerie des composants';

  @override
  String get gallerySubtitle => 'Louage blanc';

  @override
  String get galleryOpen => 'Ouvrir la galerie';

  @override
  String get galleryDarkMode => 'Mode sombre';

  @override
  String get galleryArabic => 'Arabe (RTL)';

  @override
  String get galleryReduceMotion => 'Sans animations';

  @override
  String get galleryConnected => 'Connecté';

  @override
  String get galleryLoading => 'Chargement';

  @override
  String get galleryButtons => 'Boutons';

  @override
  String get gallerySeats => 'Places';

  @override
  String get galleryChips => 'États';

  @override
  String get galleryCards => 'Cartes louage';

  @override
  String get galleryBanners => 'Bandeaux';

  @override
  String get galleryFields => 'Champs';

  @override
  String get galleryStepper => 'Compteur chauffeur';

  @override
  String get galleryStatusView => 'Écran d\'état';

  @override
  String get gallerySkeleton => 'Chargement (squelette)';

  @override
  String get galleryTypography => 'Typographie';

  @override
  String get galleryAppBar => 'Barre d\'application';

  @override
  String get galleryLive => 'Temps réel';

  @override
  String get galleryPrimary => 'Principal';

  @override
  String get gallerySecondary => 'Secondaire';

  @override
  String get galleryOutline => 'Contour';

  @override
  String get galleryText => 'Texte';

  @override
  String get galleryDestructive => 'Supprimer';

  @override
  String get galleryDriver => 'Démarrer le départ';

  @override
  String get galleryRoute => 'Bab Saadoun → Sousse';

  @override
  String get galleryEta => '≈ 10 min';

  @override
  String get galleryBannerOffline =>
      'Pas de connexion. Les places affichées peuvent être anciennes.';

  @override
  String get galleryBannerError => 'Impossible de mettre à jour la file.';

  @override
  String get galleryBannerWarn => 'Plus que 2 places dans ce louage.';

  @override
  String get galleryBannerOk => 'Réservation confirmée.';

  @override
  String get galleryStatusTitle => 'Aucun louage en file';

  @override
  String get galleryStatusMessage =>
      'Les louages apparaîtront ici dès qu\'un chauffeur rejoint la file.';

  @override
  String get splashTagline => 'Le louage en direct';

  @override
  String get otherLanguageName => 'العربية';

  @override
  String get loginSubtitle => 'Suivez votre louage en direct.';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordInfo =>
      'Pour réinitialiser votre mot de passe, contactez l\'agent de station ou l\'administrateur.';

  @override
  String get signingIn => 'Connexion…';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get createTravelerAccount => 'Créer un compte voyageur';

  @override
  String get loginOfflineBanner =>
      'Pas de connexion internet. Vous pourrez vous connecter dès le retour du réseau.';

  @override
  String get loginFieldCheckCredentials =>
      'Vérifiez l\'e-mail et le mot de passe.';

  @override
  String get loginFieldEmailNotConfirmed =>
      'Ouvrez le lien reçu par e-mail pour confirmer cette adresse.';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get alreadyHaveAccountQuestion => 'Déjà un compte ?';

  @override
  String get back => 'Retour';

  @override
  String get profileErrorTitle => 'Profil introuvable';

  @override
  String get changePasswordTitle => 'Nouveau mot de passe';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get changePasswordTempBanner =>
      'Votre compte a été créé avec un mot de passe temporaire. Choisissez-en un nouveau pour continuer.';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get confirmShort => 'Confirmer';

  @override
  String ruleMinLength(int min) {
    return 'Au moins $min caractères';
  }

  @override
  String get ruleDigit => 'Au moins un chiffre';

  @override
  String get ruleMatch => 'Les deux mots de passe sont identiques';

  @override
  String ruleMetA11y(String rule) {
    return '$rule : respecté';
  }

  @override
  String ruleNotMetA11y(String rule) {
    return '$rule : non respecté';
  }

  @override
  String get saveAndContinue => 'Enregistrer et continuer';

  @override
  String get saving => 'Enregistrement…';

  @override
  String get changePwdErrWeak =>
      'Mot de passe trop faible ou trop courant. Choisissez-en un autre.';

  @override
  String get changePwdErrSame =>
      'Le nouveau mot de passe doit être différent du mot de passe temporaire.';

  @override
  String get changePwdErrSession =>
      'Votre session a expiré. Reconnectez-vous puis recommencez.';

  @override
  String ligneLabel(String depart, String arrivee) {
    return '$depart → $arrivee';
  }

  @override
  String get statusHorsFile => 'Hors file';

  @override
  String chauffeurGreeting(String prenom) {
    return 'Bonjour $prenom';
  }

  @override
  String get chauffeurGreetingNoName => 'Bonjour';

  @override
  String get myLouage => 'Mon louage';

  @override
  String louagePlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get arrivedAtStation => 'Arrivé à la station ?';

  @override
  String get arrivedAtStationHint =>
      'Scannez le QR code affiché au guichet pour rejoindre la file.';

  @override
  String get joinTheQueue => 'Rejoindre la file';

  @override
  String get myDepartures => 'Mes départs';

  @override
  String get chauffeurOfflineBanner =>
      'Pas de connexion. Les chiffres affichés peuvent être anciens.';

  @override
  String get close => 'Fermer';

  @override
  String get enterCode => 'Saisir le code';

  @override
  String get enterCodeTitle => 'Code de la station';

  @override
  String get enterCodeHint => 'Code imprimé sous le QR';

  @override
  String get validate => 'Valider';

  @override
  String stationRecognized(String nom) {
    return 'Station $nom reconnue';
  }

  @override
  String louagesAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count louages devant vous',
      one: '1 louage devant vous',
      zero: 'Aucun louage devant vous',
    );
    return '$_temp0';
  }

  @override
  String get enterQueue => 'Entrer dans la file';

  @override
  String get scanAnother => 'Scanner un autre QR';

  @override
  String get queueYourPlace => 'Votre place dans la file';

  @override
  String queueRankOrdinal(int rank) {
    String _temp0 = intl.Intl.pluralLogic(
      rank,
      locale: localeName,
      other: '${rank}e',
      one: '1er',
    );
    return '$_temp0';
  }

  @override
  String yourLouage(String plaque) {
    return 'Votre louage : $plaque';
  }

  @override
  String get queueTitle => 'La file';

  @override
  String get queueYou => 'Vous';

  @override
  String get queueStayNear =>
      'Restez près de votre louage. Le téléphone sonne quand vous passez en tête.';

  @override
  String get leaveQueue => 'Quitter la file';

  @override
  String get leaveQueueConfirmTitle => 'Quitter la file ?';

  @override
  String leaveQueueConfirmBody(String plaque) {
    return '$plaque perdra sa place dans la file.';
  }

  @override
  String get headAlertTitle => 'C\'est votre tour !';

  @override
  String headAlertBody(String ligne) {
    return 'Votre louage est en tête de la file $ligne.';
  }

  @override
  String get headAlertChannel => 'Tête de file';

  @override
  String headOfQueueSubtitle(String plaque) {
    return '$plaque · en tête de file';
  }

  @override
  String seatsFree(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places libres',
      one: '1 place libre',
      zero: 'Aucune place libre',
    );
    return '$_temp0';
  }

  @override
  String reservationsToScan(int count, DateTime heure) {
    final intl.DateFormat heureDateFormat = intl.DateFormat.Hm(localeName);
    final String heureString = heureDateFormat.format(heure);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réservations à scanner',
      one: '1 réservation à scanner',
    );
    return '$_temp0 · expire à ⁦$heureString⁩';
  }

  @override
  String get scanReservation => 'Scanner une réservation';

  @override
  String get completTitle => 'Louage complet';

  @override
  String get completPlaceholder =>
      'L\'écran de départ arrive à la prochaine étape.';

  @override
  String get retireTitle => 'Louage retiré de la file';

  @override
  String retireMessage(
    String station,
    String plaque,
    String ligne,
    DateTime heure,
  ) {
    final intl.DateFormat heureDateFormat = intl.DateFormat.Hm(localeName);
    final String heureString = heureDateFormat.format(heure);

    return 'L\'agent de la station $station a retiré $plaque de la file $ligne à ⁦$heureString⁩.';
  }

  @override
  String retireMessageNoTime(String station, String plaque, String ligne) {
    return 'L\'agent de la station $station a retiré $plaque de la file $ligne.';
  }

  @override
  String get retireTalkToAgent => 'Parlez à l\'agent au guichet.';

  @override
  String get joinAQueue => 'Rejoindre une file';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get comingSoonTitle => 'Bientôt disponible';

  @override
  String get fileErrLouageComplet => 'Le louage est déjà complet.';

  @override
  String get statusQuitte => 'Sorti de la file';

  @override
  String get leftQueue => 'Vous avez quitté la file.';

  @override
  String get fileErrQuitterImpossibleEnTete =>
      'Votre louage est en tête de file : il ne peut plus la quitter. Parlez à l\'agent.';

  @override
  String get fileErrPassageDejaTermine =>
      'Votre louage n\'est plus dans cette file.';
}
