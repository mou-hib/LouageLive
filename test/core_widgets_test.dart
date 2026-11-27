import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/dev/dev_gallery_screen.dart';
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/theme/app_theme.dart';
import 'package:louage_live/core/widgets/ll_button.dart';
import 'package:louage_live/core/widgets/seat_indicator.dart';
import 'package:louage_live/core/widgets/status_chip.dart';
import 'package:louage_live/core/widgets/status_view.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('fr'),
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

const _c = LLColors.light;

Color? _textColor(WidgetTester tester, Finder finder) {
  final text = tester.widget<Text>(finder);
  return text.style?.color ??
      DefaultTextStyle.of(tester.element(finder)).style.color;
}

Color? _dotFill(WidgetTester tester, int index) {
  final box = tester.widget<AnimatedContainer>(
    find.byKey(ValueKey('seat-$index')),
  );
  return (box.decoration! as BoxDecoration).color;
}

void main() {
  group('SeatIndicator', () {
    Future<void> pumpSeats(WidgetTester tester, int occupied) =>
        _pump(tester, SeatIndicator(occupied: occupied));

    testWidgets('0/8: all rings, count in ink', (tester) async {
      await pumpSeats(tester, 0);
      expect(find.text('0/8'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        expect(_dotFill(tester, i), const Color(0x00000000));
      }
      expect(_textColor(tester, find.text('0/8')), _c.ink);
      expect(find.bySemanticsLabel('0 place occupée sur 8'), findsOneWidget);
    });

    testWidgets('5/8: 5 seatOn dots, count in ink', (tester) async {
      await pumpSeats(tester, 5);
      expect(find.text('5/8'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        expect(
          _dotFill(tester, i),
          i < 5 ? _c.seatOn : const Color(0x00000000),
        );
      }
      expect(_textColor(tester, find.text('5/8')), _c.ink);
      expect(find.bySemanticsLabel('5 places occupées sur 8'), findsOneWidget);
    });

    testWidgets('7/8: only the count turns seatFew', (tester) async {
      await pumpSeats(tester, 7);
      expect(_textColor(tester, find.text('7/8')), _c.seatFew);
      expect(_dotFill(tester, 0), _c.seatOn);
      expect(_dotFill(tester, 6), _c.seatOn);
      expect(_dotFill(tester, 7), const Color(0x00000000));
    });

    testWidgets('8/8: dots brandRed, count seatFull', (tester) async {
      await pumpSeats(tester, 8);
      expect(_textColor(tester, find.text('8/8')), _c.seatFull);
      for (var i = 0; i < 8; i++) {
        expect(_dotFill(tester, i), _c.brandRed);
      }
      expect(find.bySemanticsLabel('8 places occupées sur 8'), findsOneWidget);
    });

    testWidgets('count stays LTR in Arabic', (tester) async {
      await _pump(
        tester,
        const SeatIndicator(occupied: 6),
        locale: const Locale('ar'),
      );
      expect(
        tester.widget<Text>(find.text('6/8')).textDirection,
        TextDirection.ltr,
      );
      expect(find.bySemanticsLabel('المقاعد المشغولة: 6 من 8'), findsOneWidget);
    });
  });

  group('StatusChip mapping', () {
    test('passage states', () {
      expect(ChipState.fromPassage('EN_ATTENTE'), ChipState.enAttente);
      expect(ChipState.fromPassage('COMPLET'), ChipState.complet);
      expect(ChipState.fromPassage('PARTI'), ChipState.parti);
      expect(ChipState.fromPassage('RETIRE'), ChipState.retire);
      expect(ChipState.fromPassage('EN_REMPLISSAGE'), ChipState.enRemplissage);
      expect(
        ChipState.fromPassage('EN_REMPLISSAGE', seatsLeft: 3),
        ChipState.enRemplissage,
      );
      expect(
        ChipState.fromPassage('EN_REMPLISSAGE', seatsLeft: 2),
        ChipState.presqueComplet,
      );
      expect(
        ChipState.fromPassage('EN_REMPLISSAGE', seatsLeft: 1),
        ChipState.presqueComplet,
      );
      expect(
        ChipState.fromPassage('EN_REMPLISSAGE', seatsLeft: 0),
        ChipState.complet,
      );
      expect(() => ChipState.fromPassage('X'), throwsFormatException);
    });

    test('reservation states', () {
      expect(
        ChipState.fromReservation('EN_ATTENTE'),
        ChipState.reservationEnAttente,
      );
      expect(
        ChipState.fromReservation('CONFIRMEE'),
        ChipState.reservationConfirmee,
      );
      expect(
        ChipState.fromReservation('ANNULEE'),
        ChipState.reservationAnnulee,
      );
      expect(
        ChipState.fromReservation('EXPIREE'),
        ChipState.reservationExpiree,
      );
      expect(() => ChipState.fromReservation('X'), throwsFormatException);
    });

    test('tints', () {
      expect(ChipState.enRemplissage.colors(_c), (_c.successTint, _c.success));
      expect(ChipState.presqueComplet.colors(_c), (_c.seatFewTint, _c.seatFew));
      expect(ChipState.complet.colors(_c), (_c.seatFullTint, _c.seatFull));
      expect(ChipState.enAttente.colors(_c), (_c.neutralTint, _c.inkMuted));
      expect(ChipState.reservationConfirmee.colors(_c), (
        _c.successTint,
        _c.success,
      ));
      expect(ChipState.reservationAnnulee.colors(_c), (
        _c.seatFullTint,
        _c.seatFull,
      ));
      expect(ChipState.reservationExpiree.colors(_c), (
        _c.seatFullTint,
        _c.seatFull,
      ));
      expect(ChipState.parti.colors(_c), (_c.neutralTint, _c.inkMuted));
      expect(ChipState.retire.colors(_c), (_c.neutralTint, _c.inkMuted));
    });

    final labels = {
      ChipState.enAttente: 'En attente',
      ChipState.enRemplissage: 'En remplissage',
      ChipState.presqueComplet: 'Presque complet',
      ChipState.complet: 'Complet',
      ChipState.parti: 'Parti',
      ChipState.retire: 'Retiré',
      ChipState.reservationEnAttente: 'En attente',
      ChipState.reservationConfirmee: 'Confirmée',
      ChipState.reservationAnnulee: 'Annulée',
      ChipState.reservationExpiree: 'Expirée',
    };
    for (final MapEntry(key: state, value: label) in labels.entries) {
      testWidgets('$state → "$label", live dot only while filling', (
        tester,
      ) async {
        await _pump(tester, StatusChip(state: state));
        expect(find.text(label), findsOneWidget);
        expect(
          find.byKey(const ValueKey('status-live-dot')),
          state == ChipState.enRemplissage || state == ChipState.presqueComplet
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.getSize(find.byType(StatusChip)).height, 28);
      });
    }

    testWidgets('StatusChip.passage uses seats left', (tester) async {
      await _pump(tester, StatusChip.passage('EN_REMPLISSAGE', occupied: 7));
      expect(find.text('Presque complet'), findsOneWidget);
    });
  });

  group('LLButton', () {
    testWidgets('loading keeps the width, shows spinner + label, ignores '
        'taps', (tester) async {
      var taps = 0;
      Widget button({required bool loading}) => LLButton(
        label: 'Rejoindre',
        loading: loading,
        onPressed: () => taps++,
      );

      await _pump(tester, button(loading: false));
      final idleSize = tester.getSize(find.byType(LLButton));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.byType(LLButton));
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Scaffold(body: Center(child: button(loading: true))),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The visible label + the invisible width-holder copy.
      expect(find.text('Rejoindre'), findsWidgets);
      expect(tester.getSize(find.byType(LLButton)), idleSize);

      await tester.tap(find.byType(LLButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(taps, 1);
      // Keeps the enabled colours (not the greyed-out disabled look).
      final filled = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filled.onPressed, isNotNull);
    });

    testWidgets('driver variant is 72px high', (tester) async {
      await _pump(
        tester,
        LLButton(label: 'Démarrer', driver: true, onPressed: () {}),
      );
      expect(tester.getSize(find.byType(FilledButton)).height, 72);
    });
  });

  testWidgets('StatusView error tone uses the seatFull pair', (tester) async {
    await _pump(
      tester,
      const StatusView(
        icon: Icons.error_outline,
        tone: StatusTone.error,
        title: 'Erreur',
      ),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.error_outline)).color,
      _c.seatFull,
    );
  });

  group('DevGalleryScreen', () {
    for (final (locale, dark) in [
      (const Locale('fr'), false),
      (const Locale('ar'), false),
      (const Locale('fr'), true),
    ]) {
      testWidgets('renders without layout errors ($locale, dark: $dark)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360 * 3, 780 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: const DevGalleryScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        // Scroll through the whole page so every section gets laid out.
        for (var i = 0; i < 25; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -600));
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
