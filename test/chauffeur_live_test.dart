import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/theme/app_theme.dart';
import 'package:louage_live/core/widgets/ll_banner.dart';
import 'package:louage_live/core/widgets/plate_text.dart';
import 'package:louage_live/features/chauffeur/data/chauffeur_repository.dart';
import 'package:louage_live/features/chauffeur/data/file_error.dart';
import 'package:louage_live/features/chauffeur/data/passage.dart';
import 'package:louage_live/features/chauffeur/logic/chauffeur_providers.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_chauffeur_repository.dart';

final _plate = PlateText.isolate('123 TU 4567');

ChauffeurAccueil _accueil({Passage? passage, String? retraitVuId}) =>
    ChauffeurAccueil(
      louage: testLouage,
      passage: passage,
      retraitVuId: retraitVuId,
      chargeA: DateTime(2026),
    );

String _stepperValue(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('seat-stepper-value'))).data!;

void main() {
  group('ecranPour (state → screen)', () {
    final now = DateTime(2026, 11, 27, 12);

    test('every passage state maps to one screen', () {
      expect(
        ecranPour(ChauffeurAccueil(louage: null, passage: null, chargeA: now)),
        ChauffeurEcran.aucunLouage,
      );
      expect(ecranPour(_accueil()), ChauffeurEcran.horsFile);
      final cases = {
        EtatPassage.enAttente: ChauffeurEcran.enAttente,
        EtatPassage.enRemplissage: ChauffeurEcran.remplissage,
        EtatPassage.complet: ChauffeurEcran.complet,
        EtatPassage.parti: ChauffeurEcran.horsFile,
        EtatPassage.quitte: ChauffeurEcran.horsFile,
      };
      cases.forEach((etat, ecran) {
        expect(
          ecranPour(_accueil(passage: copyPassage(testPassage, etat: etat))),
          ecran,
          reason: etat.name,
        );
      });
    });

    test('RETIRE → C8 until acknowledged, and only while recent', () {
      Passage retire(Duration ago) => copyPassage(
        testPassage,
        etat: EtatPassage.retire,
        heureRetrait: now.subtract(ago),
      );
      expect(
        ecranPour(
          _accueil(passage: retire(const Duration(minutes: 5))),
          now: now,
        ),
        ChauffeurEcran.retire,
      );
      expect(
        ecranPour(
          _accueil(
            passage: retire(const Duration(minutes: 5)),
            retraitVuId: 'p1',
          ),
          now: now,
        ),
        ChauffeurEcran.horsFile,
      );
      expect(
        ecranPour(
          _accueil(passage: retire(const Duration(hours: 8))),
          now: now,
        ),
        ChauffeurEcran.horsFile,
      );
    });

    test('live badge goes stale 30 s after the last sign of life', () {
      ChauffeurAccueil at(Duration ago, {bool abonne = true}) =>
          ChauffeurAccueil(
            louage: testLouage,
            passage: testPassage,
            chargeA: now,
            abonne: abonne,
            dernierSigne: now.subtract(ago),
          );
      expect(at(const Duration(seconds: 5)).enDirect(now), isTrue);
      expect(at(const Duration(seconds: 31)).enDirect(now), isFalse);
      expect(
        at(const Duration(seconds: 1), abonne: false).enDirect(now),
        isFalse,
      );
    });
  });

  group('chauffeurAccueilProvider (live)', () {
    test('Realtime events move the screen C3 → C4 → C8, and ring once at '
        'the head', () async {
      final repo = FakeChauffeurRepository(
        louage: testLouage,
        passage: testPassage,
        file: testFile(rang: 2),
      );
      final alert = FakeHeadOfQueueAlert();
      final container = await makeChauffeurContainer(repo, alert: alert);
      addTearDown(container.dispose);
      container.listen(chauffeurEcranProvider, (_, _) {});
      await container.read(chauffeurAccueilProvider.future);

      expect(
        container.read(chauffeurEcranProvider).value,
        ChauffeurEcran.enAttente,
      );
      expect(alert.prepareCalls, 1);
      expect(container.read(chauffeurAccueilProvider).value!.devant, 1);

      // The head leaves: my louage becomes the head.
      repo.passage = copyPassage(testPassage, etat: EtatPassage.enRemplissage);
      repo.file = testFile(rang: 1);
      repo.signals.add(FileSignal.changement);
      await pumpEventQueue();
      expect(
        container.read(chauffeurEcranProvider).value,
        ChauffeurEcran.remplissage,
      );
      expect(alert.rings, hasLength(1));
      expect(alert.rings.single, contains('Tunis → Sousse'));

      // An agent removes it.
      repo.passage = copyPassage(
        testPassage,
        etat: EtatPassage.retire,
        heureRetrait: DateTime.now(),
      );
      repo.file = const [];
      repo.signals.add(FileSignal.changement);
      await pumpEventQueue();
      expect(
        container.read(chauffeurEcranProvider).value,
        ChauffeurEcran.retire,
      );
      expect(alert.rings, hasLength(1), reason: 'rings only on C3 → C4');

      await container
          .read(chauffeurAccueilProvider.notifier)
          .marquerRetraitVu();
      expect(
        container.read(chauffeurEcranProvider).value,
        ChauffeurEcran.horsFile,
      );
    });

    test(
      'reconnect refetches; a failed refetch keeps the last snapshot',
      () async {
        final repo = FakeChauffeurRepository(
          louage: testLouage,
          passage: testPassage,
          file: testFile(),
        );
        final container = await makeChauffeurContainer(repo);
        addTearDown(container.dispose);
        container.listen(chauffeurAccueilProvider, (_, _) {});
        await container.read(chauffeurAccueilProvider.future);
        final loads = repo.loads;

        repo.signals.add(FileSignal.connecte);
        await pumpEventQueue();
        expect(repo.loads, greaterThan(loads));
        expect(container.read(chauffeurAccueilProvider).value!.abonne, isTrue);

        repo.signals.add(FileSignal.deconnecte);
        repo.error = FileError.reseau;
        repo.signals.add(FileSignal.changement);
        await pumpEventQueue();
        final state = container.read(chauffeurAccueilProvider);
        expect(state.value, isNotNull);
        expect(state.value!.abonne, isFalse);
        expect(state.value!.maPlace!.rang, 3);
      },
    );
  });

  group('C3 — waiting in the queue', () {
    testWidgets('rank 3e, louages ahead, my row highlighted, red head badge', (
      tester,
    ) async {
      await pumpChauffeurHome(
        tester,
        FakeChauffeurRepository(
          louage: testLouage,
          passage: testPassage,
          file: testFile(rang: 3),
        ),
      );

      expect(find.text('Tunis → Sousse'), findsOneWidget);
      expect(find.text('VOTRE PLACE DANS LA FILE'), findsOneWidget);
      expect(find.text('3e'), findsOneWidget);
      expect(find.text('2 louages devant vous'), findsOneWidget);
      expect(find.text('Votre louage : $_plate'), findsOneWidget);
      expect(find.byKey(const ValueKey('ll-app-bar-stripe')), findsOneWidget);
      expect(find.byKey(const ValueKey('queue-row-mine')), findsOneWidget);

      final headBadge = tester.widget<Container>(
        find
            .ancestor(of: find.text('1'), matching: find.byType(Container))
            .first,
      );
      expect(
        (headBadge.decoration! as BoxDecoration).color,
        LLColors.light.brandRed,
      );

      await tester.scrollUntilVisible(find.text('Quitter la file'), 200);
      expect(
        find.text(
          'Restez près de votre louage. Le téléphone sonne quand vous passez '
          'en tête.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Quitter la file → confirm → quitter_file → C1', (
      tester,
    ) async {
      final repo = FakeChauffeurRepository(
        louage: testLouage,
        passage: testPassage,
        file: testFile(rang: 3),
      );
      await pumpChauffeurHome(tester, repo);

      await tester.scrollUntilVisible(find.text('Quitter la file'), 200);
      await tester.tap(find.text('Quitter la file'));
      await tester.pumpAndSettle();
      expect(find.text('Quitter la file ?'), findsOneWidget);
      expect(
        find.text('$_plate perdra sa place dans la file.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('c3-quitter-confirmer')));
      await tester.pumpAndSettle();

      expect(repo.quitterCalls, ['p1']);
      expect(find.text('Quitter la file ?'), findsNothing);
      expect(find.text('Vous avez quitté la file.'), findsOneWidget);
      expect(find.text('Arrivé à la station ?'), findsOneWidget, reason: 'C1');
    });

    testWidgets('refused at the head: error stays in the sheet', (
      tester,
    ) async {
      final repo = FakeChauffeurRepository(
        louage: testLouage,
        passage: testPassage,
        file: testFile(rang: 3),
      )..quitterError = FileError.quitterImpossibleEnTete;
      await pumpChauffeurHome(tester, repo);

      await tester.scrollUntilVisible(find.text('Quitter la file'), 200);
      await tester.tap(find.text('Quitter la file'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c3-quitter-confirmer')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Votre louage est en tête de file : il ne peut plus la quitter. "
          "Parlez à l'agent.",
        ),
        findsOneWidget,
      );
      expect(find.text('Quitter la file ?'), findsOneWidget);
    });

    testWidgets('Arabic: RTL, rank in Latin digits, my edge on the right', (
      tester,
    ) async {
      await pumpChauffeurHome(
        tester,
        FakeChauffeurRepository(
          louage: testLouage,
          passage: testPassage,
          file: testFile(rang: 3),
        ),
        locale: const Locale('ar'),
      );

      expect(find.byKey(const ValueKey('c3-rang')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('c3-rang'))).data,
        '3',
      );
      expect(find.text('لواجان أمامك'), findsOneWidget);
      final edge = tester.getCenter(
        find.byKey(const ValueKey('queue-row-mine')),
      );
      expect(
        edge.dx,
        greaterThan(tester.getSize(find.byType(MaterialApp)).width / 2),
      );
    });
  });

  group('C4 — filling', () {
    FakeChauffeurRepository remplissage({int places = 3}) =>
        FakeChauffeurRepository(
          louage: testLouage,
          passage: copyPassage(
            testPassage,
            etat: EtatPassage.enRemplissage,
            placesOccupees: places,
          ),
          file: testFile(rang: 1),
        );

    testWidgets('+1 is optimistic and rolls back with a banner on failure', (
      tester,
    ) async {
      final repo = remplissage();
      final rpc = Completer<int>();
      repo.onModifier = (_) => rpc.future;
      await pumpChauffeurHome(tester, repo);

      expect(_stepperValue(tester), '3');
      expect(find.text('5 places libres'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('seat-stepper-plus')));
      await tester.pump();
      expect(
        _stepperValue(tester),
        '4',
        reason: 'shown before the RPC answers',
      );
      expect(find.text('4 places libres'), findsOneWidget);
      expect(repo.modifierCalls, [1]);

      rpc.completeError(const FileAttenteException(FileError.louageComplet));
      await tester.pumpAndSettle();

      expect(_stepperValue(tester), '3');
      expect(find.text('5 places libres'), findsOneWidget);
      expect(
        find.widgetWithText(LLBanner, 'Le louage est déjà complet.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '−1 under the reservations rolls back (PLACES_SOUS_RESERVATIONS)',
      (tester) async {
        final repo = remplissage(places: 2)
          ..reservations = [DateTime(2026, 11, 27, 14, 20)];
        repo.onModifier = (_) async =>
            throw const FileAttenteException(FileError.placesSousReservations);
        await pumpChauffeurHome(tester, repo);

        expect(
          find.text('1 réservation à scanner · expire à \u206614:20\u2069'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('seat-stepper-minus')));
        await tester.pumpAndSettle();
        expect(_stepperValue(tester), '2');
        expect(
          find.text('Impossible : moins de places que de réservations.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('three +1 taps → three modifier_places calls in order', (
      tester,
    ) async {
      final repo = remplissage();
      await pumpChauffeurHome(tester, repo);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('seat-stepper-plus')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(repo.modifierCalls, [1, 1, 1]);
      expect(_stepperValue(tester), '6');
      expect(repo.passage!.placesOccupees, 6);
    });

    testWidgets('offline: banner, keys disabled, last numbers kept', (
      tester,
    ) async {
      final repo = remplissage();
      await pumpChauffeurHome(tester, repo, online: false);

      expect(
        find.text(
          'Pas de connexion. Les chiffres affichés peuvent être anciens.',
        ),
        findsOneWidget,
      );
      expect(_stepperValue(tester), '3');
      await tester.tap(find.byKey(const ValueKey('seat-stepper-plus')));
      await tester.pumpAndSettle();
      expect(repo.modifierCalls, isEmpty);
    });

    testWidgets('Arabic: −1 on the right, +1 on the left', (tester) async {
      await pumpChauffeurHome(
        tester,
        remplissage(),
        locale: const Locale('ar'),
      );
      final minus = tester.getCenter(
        find.byKey(const ValueKey('seat-stepper-minus')),
      );
      final plus = tester.getCenter(
        find.byKey(const ValueKey('seat-stepper-plus')),
      );
      expect(minus.dx, greaterThan(plus.dx));
    });
  });

  group('C8 — removed from the queue', () {
    testWidgets('explains who removed it, back home goes to C1', (
      tester,
    ) async {
      final retireA = DateTime.now().subtract(const Duration(minutes: 2));
      await pumpChauffeurHome(
        tester,
        FakeChauffeurRepository(
          louage: testLouage,
          passage: copyPassage(
            testPassage,
            etat: EtatPassage.retire,
            heureRetrait: retireA,
          ),
        ),
      );

      final hm =
          '${retireA.hour.toString().padLeft(2, '0')}:'
          '${retireA.minute.toString().padLeft(2, '0')}';
      expect(find.text('Louage retiré de la file'), findsOneWidget);
      expect(
        find.text(
          "L'agent de la station Bab Saadoun a retiré $_plate de la file "
          'Tunis → Sousse à \u2066$hm\u2069.',
        ),
        findsOneWidget,
      );
      expect(find.text("Parlez à l'agent au guichet."), findsOneWidget);
      expect(find.text('Rejoindre une file'), findsOneWidget);

      await tester.tap(find.text("Retour à l'accueil"));
      await tester.pumpAndSettle();
      expect(find.text('Arrivé à la station ?'), findsOneWidget);
    });
  });

  group('small phone, FR/AR, light/dark: no overflow', () {
    final etats = <String, FakeChauffeurRepository Function()>{
      'C1': () =>
          FakeChauffeurRepository(louage: testLouage, prenom: 'Mohamed'),
      'C3': () => FakeChauffeurRepository(
        louage: testLouage,
        passage: testPassage,
        file: testFile(rang: 5),
      ),
      'C4': () => FakeChauffeurRepository(
        louage: testLouage,
        passage: copyPassage(
          testPassage,
          etat: EtatPassage.enRemplissage,
          placesOccupees: 7,
        ),
        file: testFile(rang: 1),
        reservations: [DateTime(2026, 11, 27, 14, 20)],
      ),
      'complet': () => FakeChauffeurRepository(
        louage: testLouage,
        passage: copyPassage(
          testPassage,
          etat: EtatPassage.complet,
          placesOccupees: 8,
        ),
        file: testFile(rang: 1),
      ),
      'C8': () => FakeChauffeurRepository(
        louage: testLouage,
        passage: copyPassage(
          testPassage,
          etat: EtatPassage.retire,
          heureRetrait: DateTime.now(),
        ),
      ),
    };
    for (final lang in ['fr', 'ar']) {
      for (final dark in [false, true]) {
        for (final MapEntry(key: name, value: repo) in etats.entries) {
          testWidgets('$name ($lang, dark: $dark, offline)', (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await pumpChauffeurHome(
              tester,
              repo(),
              locale: Locale(lang),
              dark: dark,
              online: false,
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
