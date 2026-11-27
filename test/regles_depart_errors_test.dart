import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:louage_live/features/chauffeur/data/file_error.dart';
import 'package:louage_live/features/chauffeur/presentation/file_error_message.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  setUpAll(initializeDateFormatting);

  final st = StackTrace.current;
  PostgrestException raised(String code, [String? details]) =>
      PostgrestException(message: code, code: 'P0001', details: details);

  group('booking / departure codes', () {
    const cases = {
      'RESERVATION_DEJA_EN_COURS': FileError.reservationDejaEnCours,
      'LOUAGE_PAS_EN_TETE': FileError.louagePasEnTete,
      'LOUAGE_PAS_COMPLET': FileError.louagePasComplet,
      'RESERVATION_EN_ATTENTE': FileError.reservationEnAttente,
      'PLACES_SOUS_RESERVATIONS': FileError.placesSousReservations,
    };
    cases.forEach((code, expected) {
      test('$code → ${expected.name}', () {
        expect(classifyFileError(raised(code), st), expected);
      });
    });

    test('every FileError has a FR and an AR message', () {
      for (final locale in const [Locale('fr'), Locale('ar')]) {
        final l10n = lookupAppLocalizations(locale);
        for (final e in FileError.values) {
          expect(
            fileErrorMessage(l10n, e),
            isNotEmpty,
            reason: '${locale.languageCode} ${e.name}',
          );
        }
      }
    });
  });

  group('RESERVATION_EN_ATTENTE expiry', () {
    const detail = '2026-11-27T14:20:00.000000Z';

    test('expiry is read from the error DETAIL (UTC)', () {
      final e = FileAttenteException(
        FileError.reservationEnAttente,
        raised('RESERVATION_EN_ATTENTE', detail),
      );
      expect(e.expiration, DateTime.utc(2026, 11, 27, 14, 20));
    });

    test('no / bad DETAIL → no expiry', () {
      expect(expirationOf(raised('RESERVATION_EN_ATTENTE')), isNull);
      expect(expirationOf(raised('RESERVATION_EN_ATTENTE', 'n/a')), isNull);
      expect(expirationOf(StateError('x')), isNull);
    });

    for (final lang in const ['fr', 'ar']) {
      test('$lang message shows the local time, LTR-isolated', () {
        final l10n = lookupAppLocalizations(Locale(lang));
        final at = DateTime.parse(detail);
        final heure = DateFormat.Hm(lang).format(at.toLocal());
        final msg = fileErrorMessage(
          l10n,
          FileError.reservationEnAttente,
          expiration: at,
        );
        expect(msg, contains('\u2066$heure\u2069'));
        expect(
          fileErrorMessage(l10n, FileError.reservationEnAttente),
          isNot(contains('\u2066')),
        );
      });
    }
  });
}
