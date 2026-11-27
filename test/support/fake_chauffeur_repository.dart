import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/l10n/locale_provider.dart';
import 'package:louage_live/core/network/connectivity.dart';
import 'package:louage_live/core/notifications/head_of_queue_alert.dart';
import 'package:louage_live/core/theme/app_theme.dart';
import 'package:louage_live/features/chauffeur/data/chauffeur_repository.dart';
import 'package:louage_live/features/chauffeur/data/file_error.dart';
import 'package:louage_live/features/chauffeur/data/louage.dart';
import 'package:louage_live/features/chauffeur/data/passage.dart';
import 'package:louage_live/features/chauffeur/data/station.dart';
import 'package:louage_live/features/chauffeur/logic/chauffeur_providers.dart';
import 'package:louage_live/features/chauffeur/presentation/chauffeur_home_screen.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ChauffeurRepository without Supabase. Tests drive Realtime through
/// [signals] and the database through the public fields.
class FakeChauffeurRepository implements ChauffeurRepository {
  FakeChauffeurRepository({
    this.louage,
    this.passage,
    this.error,
    this.prenom,
    this.file = const [],
    this.reservations = const [],
  });

  Louage? louage;
  Passage? passage;
  String? prenom;
  List<FileEntree> file;
  List<DateTime> reservations;

  /// When set, every read fails with it.
  FileError? error;

  /// Realtime: what `ecouter` streams.
  final signals = StreamController<FileSignal>.broadcast();
  int ecouterCalls = 0;
  int loads = 0;

  /// Deltas sent to `modifier_places`, in order.
  final modifierCalls = <int>[];

  /// Overrides `modifier_places` (e.g. to make it wait or fail). Default:
  /// applies the delta to [passage].
  Future<int> Function(int delta)? onModifier;

  void _maybeFail() {
    if (error case final e?) throw FileAttenteException(e);
  }

  @override
  Future<Louage?> monLouage() async {
    loads++;
    _maybeFail();
    return louage;
  }

  @override
  Future<String?> monPrenom() async {
    _maybeFail();
    return prenom;
  }

  @override
  Future<Passage?> monPassageActif() async {
    _maybeFail();
    final p = passage;
    return p != null && EtatPassage.actifs.contains(p.etat) ? p : null;
  }

  @override
  Future<Passage?> dernierPassage(String louageId) async {
    _maybeFail();
    return passage;
  }

  @override
  Future<List<FileEntree>> fileDeLigne(String ligneId) async {
    _maybeFail();
    return file;
  }

  @override
  Future<List<DateTime>> reservationsAScanner(String passageId) async {
    _maybeFail();
    return reservations;
  }

  @override
  Future<int> modifierPlaces(String passageId, int delta) async {
    modifierCalls.add(delta);
    if (onModifier case final f?) return f(delta);
    final p = passage!;
    passage = copyPassage(p, placesOccupees: p.placesOccupees + delta);
    return passage!.placesOccupees;
  }

  /// Passages sent to `quitter_file`.
  final quitterCalls = <String>[];

  /// When set, `quitter_file` fails with it; otherwise the passage → QUITTE.
  FileError? quitterError;

  @override
  Future<void> quitterFile(String passageId) async {
    quitterCalls.add(passageId);
    if (quitterError case final e?) throw FileAttenteException(e);
    passage = copyPassage(
      passage!,
      etat: EtatPassage.quitte,
      heureRetrait: DateTime.now(),
    );
    file = [
      for (final e in file)
        if (e.passageId != passageId) e,
    ];
  }

  @override
  Stream<FileSignal> ecouter({
    required String louageId,
    String? ligneId,
    String? passageId,
  }) {
    ecouterCalls++;
    return signals.stream;
  }

  @override
  Future<Station> lignesDeStation(String codeQr) async {
    _maybeFail();
    return const Station(
      id: 's1',
      nom: 'Bab Saadoun',
      ville: 'Tunis',
      lignes: [],
    );
  }

  @override
  Future<void> rejoindreFile(String codeQr, String ligneId) async =>
      _maybeFail();
}

class FakeHeadOfQueueAlert implements HeadOfQueueAlert {
  int prepareCalls = 0;
  final rings = <String>[];

  @override
  Future<void> prepare() async => prepareCalls++;

  @override
  Future<void> ring({
    required String title,
    required String body,
    required String channelName,
  }) async => rings.add('$title|$body');
}

Passage copyPassage(
  Passage p, {
  EtatPassage? etat,
  int? placesOccupees,
  DateTime? heureRetrait,
}) => Passage(
  id: p.id,
  etat: etat ?? p.etat,
  placesOccupees: placesOccupees ?? p.placesOccupees,
  capacite: p.capacite,
  ligneId: p.ligneId,
  stationNom: p.stationNom,
  stationVille: p.stationVille,
  villeArrivee: p.villeArrivee,
  heureRetrait: heureRetrait ?? p.heureRetrait,
);

const testLouage = Louage(
  id: 'l1',
  immatriculation: '123 TU 4567',
  capacite: 8,
);

const testPassage = Passage(
  id: 'p1',
  etat: EtatPassage.enAttente,
  placesOccupees: 0,
  capacite: 8,
  ligneId: 'g1',
  stationNom: 'Bab Saadoun',
  stationVille: 'Tunis',
  villeArrivee: 'Sousse',
);

/// Queue of Tunis → Sousse with my louage (p1) at [rang].
List<FileEntree> testFile({int rang = 3}) => [
  for (var r = 1; r <= rang; r++)
    FileEntree(
      passageId: r == rang ? 'p1' : 'other$r',
      immatriculation: r == rang ? '123 TU 4567' : '${200 + r} TU 1000',
      etat: r == 1 && rang > 1
          ? EtatPassage.enRemplissage
          : EtatPassage.enAttente,
      placesOccupees: r == 1 && rang > 1 ? 5 : 0,
      capacite: 8,
      rang: r,
    ),
];

Future<ProviderContainer> makeChauffeurContainer(
  FakeChauffeurRepository repo, {
  FakeHeadOfQueueAlert? alert,
  bool online = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      chauffeurRepositoryProvider.overrideWithValue(repo),
      headOfQueueAlertProvider.overrideWithValue(
        alert ?? FakeHeadOfQueueAlert(),
      ),
      isOnlineProvider.overrideWith((ref) => Stream.value(online)),
    ],
  );
}

Future<ProviderContainer> pumpChauffeurHome(
  WidgetTester tester,
  FakeChauffeurRepository repo, {
  Locale locale = const Locale('fr'),
  bool online = true,
  bool dark = false,
  FakeHeadOfQueueAlert? alert,
}) async {
  final container = await makeChauffeurContainer(
    repo,
    alert: alert,
    online: online,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: const ChauffeurHomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
