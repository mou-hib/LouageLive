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
  String get comingSoon =>
      'Les fonctionnalités arrivent dans les prochains sprints.';

  @override
  String get configMissing =>
      'Configuration Supabase manquante. Lancez l\'application avec --dart-define-from-file=config/env.json (voir README).';
}
