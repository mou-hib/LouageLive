import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:louage_live/core/widgets/ll_button.dart';
import 'package:louage_live/core/widgets/plate_text.dart';
import 'package:louage_live/features/chauffeur/data/file_error.dart';
import 'package:louage_live/features/chauffeur/data/louage.dart';
import 'package:louage_live/features/chauffeur/data/passage.dart';
import 'package:louage_live/features/chauffeur/data/station.dart';
import 'package:louage_live/features/chauffeur/presentation/chauffeur_home_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'support/fake_chauffeur_repository.dart';

const _louage = testLouage;
final _plate = PlateText.isolate('123 TU 4567');

Future<void> _pumpHome(
  WidgetTester tester,
  FakeChauffeurRepository repo, {
  Locale locale = const Locale('fr'),
}) => pumpChauffeurHome(tester, repo, locale: locale);

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
        'ligne_id': 'g1',
        'heure_retrait': null,
        'lignes': {
          'ville_arrivee': 'Sousse',
          'stations': {'nom': 'Bab Saadoun', 'ville': 'Tunis'},
        },
        'louages': {'chauffeur_id': 'u1', 'actif': true},
      });
      expect(p.etat, EtatPassage.enRemplissage);
      expect(p.stationNom, 'Bab Saadoun');
      expect(p.villeArrivee, 'Sousse');
      expect(p.stationVille, 'Tunis');
      expect(p.ligneId, 'g1');
      expect(p.heureRetrait, isNull);
    });

    test('Passage.fromRow reads heure_retrait (RETIRE)', () {
      final p = Passage.fromRow({
        'id': 'p1',
        'etat': 'RETIRE',
        'places_occupees': 0,
        'capacite': 8,
        'ligne_id': 'g1',
        'heure_retrait': '2026-11-27T10:15:00+00:00',
        'lignes': {
          'ville_arrivee': 'Sousse',
          'stations': {'nom': 'Bab Saadoun', 'ville': 'Tunis'},
        },
      });
      expect(p.heureRetrait, DateTime.utc(2026, 11, 27, 10, 15));
    });

    test('FileEntree.fromRow reads a file_attente row', () {
      final e = FileEntree.fromRow({
        'passage_id': 'p1',
        'immatriculation': '123 TU 4567',
        'etat': 'EN_ATTENTE',
        'places_occupees': 0,
        'capacite': 8,
        'rang': 3,
      });
      expect(e.rang, 3);
      expect(e.etat, EtatPassage.enAttente);
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
      expect(EtatPassage.fromValue('QUITTE'), EtatPassage.quitte);
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
      expect(find.text('Rejoindre la file'), findsNothing);
    });

    testWidgets('louage not in a queue → C1: greeting, louage card, join', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        FakeChauffeurRepository(louage: _louage, prenom: 'Mohamed'),
      );

      expect(find.text('Bonjour Mohamed'), findsOneWidget);
      expect(find.text('MON LOUAGE'), findsOneWidget);
      expect(find.text(_plate), findsOneWidget);
      expect(find.text('8 places'), findsOneWidget);
      expect(find.text('Hors file'), findsOneWidget);
      expect(find.text('Arrivé à la station ?'), findsOneWidget);
      expect(
        find.widgetWithText(LLButton, 'Rejoindre la file'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('Mes départs'), 200);
      expect(find.widgetWithText(LLButton, 'Mes départs'), findsOneWidget);
    });

    testWidgets('louage in a queue → C3, no join button', (tester) async {
      await _pumpHome(
        tester,
        FakeChauffeurRepository(
          louage: _louage,
          passage: testPassage,
          file: testFile(rang: 2),
        ),
      );

      expect(find.text('Tunis → Sousse'), findsOneWidget);
      expect(find.text('Rejoindre la file'), findsNothing);
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
      expect(find.text(_plate), findsOneWidget);
    });

    testWidgets('Arabic: RTL with Arabic plural', (tester) async {
      await _pumpHome(
        tester,
        FakeChauffeurRepository(louage: _louage),
        locale: const Locale('ar'),
      );

      expect(find.text('8 مقاعد'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(ChauffeurHomeScreen))),
        TextDirection.rtl,
      );
    });
  });
}
