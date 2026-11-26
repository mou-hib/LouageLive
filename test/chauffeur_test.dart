import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/l10n/locale_provider.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// ChauffeurRepository without Supabase.
class FakeChauffeurRepository implements ChauffeurRepository {
  FakeChauffeurRepository({this.louage, this.passage, this.error});

  Louage? louage;
  Passage? passage;

  /// When set, every call fails with it.
  FileError? error;

  void _maybeFail() {
    if (error case final e?) throw FileAttenteException(e);
  }

  @override
  Future<Louage?> monLouage() async {
    _maybeFail();
    return louage;
  }

  @override
  Future<Passage?> monPassageActif() async {
    _maybeFail();
    return passage;
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

const _louage = Louage(id: 'l1', immatriculation: '123 TU 4567', capacite: 8);
const _passage = Passage(
  id: 'p1',
  etat: EtatPassage.enAttente,
  placesOccupees: 0,
  capacite: 8,
  stationNom: 'Bab Saadoun',
  villeArrivee: 'Sousse',
);

Future<void> _pumpHome(
  WidgetTester tester,
  FakeChauffeurRepository repo, {
  Locale locale = const Locale('fr'),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      chauffeurRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: const ChauffeurHomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('classifyFileError', () {
    final st = StackTrace.current;
    FileError classify(Object e) => classifyFileError(e, st);
    PostgrestException raised(String code) =>
        PostgrestException(message: code, code: 'P0001');

    test('ACCES_REFUSE → accesRefuse', () {
      expect(classify(raised('ACCES_REFUSE')), FileError.accesRefuse);
    });

    test('AUCUN_LOUAGE → aucunLouage', () {
      expect(classify(raised('AUCUN_LOUAGE')), FileError.aucunLouage);
    });

    test('QR_STATION_INVALIDE → qrStationInvalide', () {
      expect(
        classify(raised('QR_STATION_INVALIDE')),
        FileError.qrStationInvalide,
      );
    });

    test('DEJA_EN_FILE → dejaEnFile', () {
      expect(classify(raised('DEJA_EN_FILE')), FileError.dejaEnFile);
    });

    test('network failures → reseau', () {
      for (final e in <Object>[
        const SocketException('down'),
        TimeoutException('slow'),
        http.ClientException('reset'),
      ]) {
        expect(classify(e), FileError.reseau, reason: '$e');
      }
    });

    test('unknown database error → inconnue', () {
      expect(
        classify(const PostgrestException(message: 'boom', code: '42P01')),
        FileError.inconnue,
      );
      // Only the exact code counts, not a message that merely contains it.
      expect(
        classify(raised('erreur: DEJA_EN_FILE quelque part')),
        FileError.inconnue,
      );
    });

    test('bug (StateError, FormatException) → inconnue', () {
      expect(classify(StateError('bug')), FileError.inconnue);
      expect(classify(const FormatException('bad row')), FileError.inconnue);
    });
  });

  group('row parsing', () {
    test('Passage.fromRow reads the embedded line and station', () {
      final p = Passage.fromRow({
        'id': 'p1',
        'etat': 'EN_REMPLISSAGE',
        'places_occupees': 3,
        'capacite': 8,
        'lignes': {
          'ville_arrivee': 'Sousse',
          'stations': {'nom': 'Bab Saadoun'},
        },
        'louages': {'chauffeur_id': 'u1', 'actif': true},
      });
      expect(p.etat, EtatPassage.enRemplissage);
      expect(p.stationNom, 'Bab Saadoun');
      expect(p.villeArrivee, 'Sousse');
    });

    test('Station.fromRow reads lines and numeric fares', () {
      final s = Station.fromRow({
        'id': 's1',
        'nom': 'Bab Saadoun',
        'ville': 'Tunis',
        'lignes': [
          {'id': 'g1', 'ville_arrivee': 'Bizerte', 'tarif': 6},
          {'id': 'g2', 'ville_arrivee': 'Sousse', 'tarif': 12.5},
        ],
      });
      expect(s.lignes.map((l) => l.tarif), [6.0, 12.5]);
    });

    test('malformed rows throw FormatException', () {
      expect(
        () => Louage.fromRow({'id': 'l1', 'immatriculation': 'x'}),
        throwsFormatException,
      );
      expect(
        () => Passage.fromRow({'id': 'p1', 'etat': 'INCONNU'}),
        throwsFormatException,
      );
    });
  });

  group('C1 chauffeur home', () {
    testWidgets('no louage → contact the station agent', (tester) async {
      await _pumpHome(tester, FakeChauffeurRepository());

      expect(
        find.text("Aucun louage associé, contactez l'agent de station."),
        findsOneWidget,
      );
      expect(find.text('Scanner le QR de la station'), findsNothing);
    });

    testWidgets('louage not in a queue → louage card + scan button', (
      tester,
    ) async {
      await _pumpHome(tester, FakeChauffeurRepository(louage: _louage));

      expect(find.text('123 TU 4567'), findsOneWidget);
      expect(find.text('Capacité : 8 places'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Scanner le QR de la station'),
        findsOneWidget,
      );
      expect(find.textContaining('Vous êtes dans la file'), findsNothing);
    });

    testWidgets('louage in a queue → queue card, no scan button', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        FakeChauffeurRepository(louage: _louage, passage: _passage),
      );

      expect(find.text('123 TU 4567'), findsOneWidget);
      expect(
        find.text('Vous êtes dans la file : Bab Saadoun → Sousse'),
        findsOneWidget,
      );
      expect(find.text('Scanner le QR de la station'), findsNothing);
    });

    testWidgets('load error → message and retry', (tester) async {
      final repo = FakeChauffeurRepository(
        louage: _louage,
        error: FileError.reseau,
      );
      await _pumpHome(tester, repo);

      expect(find.text('Pas de connexion internet.'), findsOneWidget);

      repo.error = null;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.text('123 TU 4567'), findsOneWidget);
    });

    testWidgets('Arabic: RTL with Arabic plural', (tester) async {
      await _pumpHome(
        tester,
        FakeChauffeurRepository(louage: _louage),
        locale: const Locale('ar'),
      );

      expect(find.text('السعة: 8 مقاعد'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(ChauffeurHomeScreen))),
        TextDirection.rtl,
      );
    });
  });
}
