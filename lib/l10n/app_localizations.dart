import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
    Locale('ar'),
    Locale('fr'),
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Louage Live'**
  String get appTitle;

  /// Titre de l'écran de connexion
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// Bouton de connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @voyageurHomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace voyageur'**
  String get voyageurHomeTitle;

  /// No description provided for @chauffeurHomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace chauffeur'**
  String get chauffeurHomeTitle;

  /// No description provided for @agentHomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace agent de station'**
  String get agentHomeTitle;

  /// No description provided for @adminHomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get adminHomeTitle;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer de langue'**
  String get changeLanguage;

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get genericError;

  /// No description provided for @loginFailed.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect.'**
  String get loginFailed;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get fieldRequired;

  /// Validation du champ e-mail (format)
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get emailInvalid;

  /// Connexion refusée : e-mail pas encore confirmé
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail non confirmée.'**
  String get loginEmailNotConfirmed;

  /// Connexion refusée : limite de tentatives (429)
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives, réessayez dans un moment.'**
  String get loginTooManyAttempts;

  /// Connexion impossible : pas de réseau ou délai dépassé
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet.'**
  String get loginNetworkError;

  /// Titre de l'écran d'inscription (B1) et bouton d'envoi
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// Lien de l'écran de connexion vers l'inscription
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? Créer un compte'**
  String get noAccountCreateOne;

  /// Note sous la connexion : seuls les voyageurs s'inscrivent eux-mêmes
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs et agents : votre compte est créé par l\'administrateur.'**
  String get staffAccountNote;

  /// Lien de l'inscription vers la connexion
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get alreadyHaveAccount;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// Exemple sous le champ téléphone
  ///
  /// In fr, this message translates to:
  /// **'Ex. 98 123 456'**
  String get phoneHint;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @phoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide : 8 chiffres, +216 facultatif.'**
  String get phoneInvalid;

  /// Validation : mot de passe trop court
  ///
  /// In fr, this message translates to:
  /// **'Au moins {min} caractères.'**
  String passwordTooShort(int min);

  /// No description provided for @passwordsDontMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get passwordsDontMatch;

  /// Inscription refusée : e-mail déjà utilisé
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cet e-mail.'**
  String get signUpEmailExists;

  /// Inscription refusée par Supabase : weak_password
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible (6 caractères minimum).'**
  String get signUpWeakPassword;

  /// Inscription refusée : limite d'envoi d'e-mails (429)
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives, réessayez plus tard.'**
  String get signUpTooManyAttempts;

  /// Après inscription quand la confirmation par e-mail est activée
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre e-mail'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Nous avons envoyé un lien de confirmation à :'**
  String get checkEmailSentTo;

  /// No description provided for @checkEmailNextStep.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez ce lien pour activer votre compte, puis connectez-vous.'**
  String get checkEmailNextStep;

  /// No description provided for @backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// C1 : le chauffeur n'a pas de louage actif
  ///
  /// In fr, this message translates to:
  /// **'Aucun louage associé, contactez l\'agent de station.'**
  String get chauffeurNoLouage;

  /// C1 : capacité du louage
  ///
  /// In fr, this message translates to:
  /// **'Capacité : {capacite, plural, =1{1 place} other{{capacite} places}}'**
  String louageCapacite(int capacite);

  /// C1 : le louage est déjà dans une file
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes dans la file : {station} → {ville}'**
  String chauffeurInQueue(String station, String ville);

  /// C1 : bouton principal, et titre de C2
  ///
  /// In fr, this message translates to:
  /// **'Scanner le QR de la station'**
  String get scanStationQr;

  /// No description provided for @scannerHint.
  ///
  /// In fr, this message translates to:
  /// **'Placez le QR code de la station dans le cadre.'**
  String get scannerHint;

  /// No description provided for @torchOn.
  ///
  /// In fr, this message translates to:
  /// **'Allumer la lampe'**
  String get torchOn;

  /// No description provided for @torchOff.
  ///
  /// In fr, this message translates to:
  /// **'Éteindre la lampe'**
  String get torchOff;

  /// C2 : permission caméra refusée
  ///
  /// In fr, this message translates to:
  /// **'Autorisez l\'accès à la caméra pour scanner le QR de la station.'**
  String get cameraPermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get openSettings;

  /// No description provided for @cameraUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'utiliser la caméra sur cet appareil.'**
  String get cameraUnavailable;

  /// No description provided for @chooseLine.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre ligne'**
  String get chooseLine;

  /// No description provided for @noActiveLine.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ligne active dans cette station.'**
  String get noActiveLine;

  /// Tarif officiel en dinars tunisiens
  ///
  /// In fr, this message translates to:
  /// **'{tarif} DT'**
  String tarifDt(String tarif);

  /// C2 : dialogue de confirmation
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la file {station} → {ville} ?'**
  String joinQueueConfirm(String station, String ville);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @joinQueue.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinQueue;

  /// No description provided for @joinedQueue.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez rejoint la file.'**
  String get joinedQueue;

  /// No description provided for @fileErrAccesRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les chauffeurs peuvent rejoindre une file.'**
  String get fileErrAccesRefuse;

  /// No description provided for @fileErrAucunLouage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun louage actif n\'est associé à votre compte.'**
  String get fileErrAucunLouage;

  /// No description provided for @fileErrQrInvalide.
  ///
  /// In fr, this message translates to:
  /// **'QR code non reconnu. Scannez le QR de la station.'**
  String get fileErrQrInvalide;

  /// No description provided for @fileErrDejaEnFile.
  ///
  /// In fr, this message translates to:
  /// **'Votre louage est déjà dans une file.'**
  String get fileErrDejaEnFile;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Les fonctionnalités arrivent dans les prochains sprints.'**
  String get comingSoon;

  /// Bouton qui relance le chargement du profil
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Écran d'erreur : profil introuvable, invalide ou erreur serveur
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre profil. Réessayez ou contactez l\'administrateur.'**
  String get profileErrorGeneric;

  /// Écran d'erreur : pas de réseau ou délai dépassé
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger votre profil. Vérifiez votre connexion internet.'**
  String get profileErrorNetwork;

  /// Affiché si SUPABASE_URL ou SUPABASE_ANON_KEY est vide
  ///
  /// In fr, this message translates to:
  /// **'Configuration Supabase manquante. Lancez l\'application avec --dart-define-from-file=config/env.json (voir README).'**
  String get configMissing;

  /// Lecteur d'écran : indicateur de places (ex. 6 places occupées sur 8)
  ///
  /// In fr, this message translates to:
  /// **'{occupied, plural, one{{occupied} place occupée} other{{occupied} places occupées}} sur {capacity}'**
  String seatsOccupiedA11y(int occupied, int capacity);

  /// Pastille d'état : louage en attente dans la file
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusEnAttente;

  /// Pastille d'état : louage en tête, des places restent
  ///
  /// In fr, this message translates to:
  /// **'En remplissage'**
  String get statusEnRemplissage;

  /// Pastille d'état : 1 ou 2 places restantes
  ///
  /// In fr, this message translates to:
  /// **'Presque complet'**
  String get statusPresqueComplet;

  /// No description provided for @statusComplet.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get statusComplet;

  /// No description provided for @statusParti.
  ///
  /// In fr, this message translates to:
  /// **'Parti'**
  String get statusParti;

  /// Pastille d'état : louage retiré de la file
  ///
  /// In fr, this message translates to:
  /// **'Retiré'**
  String get statusRetire;

  /// Pastille d'état : réservation pas encore confirmée
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get reservationEnAttente;

  /// No description provided for @reservationConfirmee.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get reservationConfirmee;

  /// No description provided for @reservationAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get reservationAnnulee;

  /// No description provided for @reservationExpiree.
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get reservationExpiree;

  /// Surtitre de la carte du louage en tête de file
  ///
  /// In fr, this message translates to:
  /// **'En tête de file'**
  String get queueHead;

  /// Lecteur d'écran : rang du louage dans la file
  ///
  /// In fr, this message translates to:
  /// **'Rang {rank}'**
  String queueRankA11y(int rank);

  /// No description provided for @etaLabel.
  ///
  /// In fr, this message translates to:
  /// **'Départ estimé'**
  String get etaLabel;

  /// No description provided for @fareLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tarif'**
  String get fareLabel;

  /// Badge temps réel connecté
  ///
  /// In fr, this message translates to:
  /// **'En direct'**
  String get liveNow;

  /// Badge temps réel déconnecté, moins d'une minute
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour il y a {seconds} s'**
  String liveUpdatedSecondsAgo(int seconds);

  /// Badge temps réel déconnecté, une minute ou plus
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour il y a {minutes} min'**
  String liveUpdatedMinutesAgo(int minutes);

  /// Badge temps réel déconnecté, aucune mise à jour reçue
  ///
  /// In fr, this message translates to:
  /// **'Hors connexion'**
  String get liveOffline;

  /// Lecteur d'écran : bouton en cours de chargement
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @seatStepperRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer une place'**
  String get seatStepperRemove;

  /// No description provided for @seatStepperAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une place'**
  String get seatStepperAdd;

  /// Lecteur d'écran : valeur du compteur de places
  ///
  /// In fr, this message translates to:
  /// **'Places : {value}'**
  String seatStepperValueA11y(int value);

  /// Écran de développement /dev/gallery (debug uniquement)
  ///
  /// In fr, this message translates to:
  /// **'Galerie des composants'**
  String get galleryTitle;

  /// No description provided for @gallerySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Louage blanc'**
  String get gallerySubtitle;

  /// No description provided for @galleryOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la galerie'**
  String get galleryOpen;

  /// No description provided for @galleryDarkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get galleryDarkMode;

  /// No description provided for @galleryArabic.
  ///
  /// In fr, this message translates to:
  /// **'Arabe (RTL)'**
  String get galleryArabic;

  /// No description provided for @galleryReduceMotion.
  ///
  /// In fr, this message translates to:
  /// **'Sans animations'**
  String get galleryReduceMotion;

  /// No description provided for @galleryConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get galleryConnected;

  /// No description provided for @galleryLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement'**
  String get galleryLoading;

  /// No description provided for @galleryButtons.
  ///
  /// In fr, this message translates to:
  /// **'Boutons'**
  String get galleryButtons;

  /// No description provided for @gallerySeats.
  ///
  /// In fr, this message translates to:
  /// **'Places'**
  String get gallerySeats;

  /// No description provided for @galleryChips.
  ///
  /// In fr, this message translates to:
  /// **'États'**
  String get galleryChips;

  /// No description provided for @galleryCards.
  ///
  /// In fr, this message translates to:
  /// **'Cartes louage'**
  String get galleryCards;

  /// No description provided for @galleryBanners.
  ///
  /// In fr, this message translates to:
  /// **'Bandeaux'**
  String get galleryBanners;

  /// No description provided for @galleryFields.
  ///
  /// In fr, this message translates to:
  /// **'Champs'**
  String get galleryFields;

  /// No description provided for @galleryStepper.
  ///
  /// In fr, this message translates to:
  /// **'Compteur chauffeur'**
  String get galleryStepper;

  /// No description provided for @galleryStatusView.
  ///
  /// In fr, this message translates to:
  /// **'Écran d\'état'**
  String get galleryStatusView;

  /// No description provided for @gallerySkeleton.
  ///
  /// In fr, this message translates to:
  /// **'Chargement (squelette)'**
  String get gallerySkeleton;

  /// No description provided for @galleryTypography.
  ///
  /// In fr, this message translates to:
  /// **'Typographie'**
  String get galleryTypography;

  /// No description provided for @galleryAppBar.
  ///
  /// In fr, this message translates to:
  /// **'Barre d\'application'**
  String get galleryAppBar;

  /// No description provided for @galleryLive.
  ///
  /// In fr, this message translates to:
  /// **'Temps réel'**
  String get galleryLive;

  /// No description provided for @galleryPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Principal'**
  String get galleryPrimary;

  /// No description provided for @gallerySecondary.
  ///
  /// In fr, this message translates to:
  /// **'Secondaire'**
  String get gallerySecondary;

  /// No description provided for @galleryOutline.
  ///
  /// In fr, this message translates to:
  /// **'Contour'**
  String get galleryOutline;

  /// No description provided for @galleryText.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get galleryText;

  /// No description provided for @galleryDestructive.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get galleryDestructive;

  /// No description provided for @galleryDriver.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer le départ'**
  String get galleryDriver;

  /// No description provided for @galleryRoute.
  ///
  /// In fr, this message translates to:
  /// **'Bab Saadoun → Sousse'**
  String get galleryRoute;

  /// No description provided for @galleryEta.
  ///
  /// In fr, this message translates to:
  /// **'≈ 10 min'**
  String get galleryEta;

  /// No description provided for @galleryBannerOffline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion. Les places affichées peuvent être anciennes.'**
  String get galleryBannerOffline;

  /// No description provided for @galleryBannerError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de mettre à jour la file.'**
  String get galleryBannerError;

  /// No description provided for @galleryBannerWarn.
  ///
  /// In fr, this message translates to:
  /// **'Plus que 2 places dans ce louage.'**
  String get galleryBannerWarn;

  /// No description provided for @galleryBannerOk.
  ///
  /// In fr, this message translates to:
  /// **'Réservation confirmée.'**
  String get galleryBannerOk;

  /// No description provided for @galleryStatusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun louage en file'**
  String get galleryStatusTitle;

  /// No description provided for @galleryStatusMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les louages apparaîtront ici dès qu\'un chauffeur rejoint la file.'**
  String get galleryStatusMessage;
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
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
