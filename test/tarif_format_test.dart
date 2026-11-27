import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:louage_live/core/format/tarif.dart';
import 'package:louage_live/l10n/app_localizations.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final fr = lookupAppLocalizations(const Locale('fr'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  group('formatTarif', () {
    test('whole amounts have no decimals', () {
      expect(formatTarif(fr, 12), '12 DT');
      expect(formatTarif(fr, 12.000), '12 DT');
      expect(formatTarif(fr, 6), '6 DT');
      expect(formatTarif(fr, 0), '0 DT');
    });

    test('other amounts keep the 3 decimals of the dinar', () {
      expect(formatTarif(fr, 12.5), '12,500 DT');
      expect(formatTarif(fr, 9.75), '9,750 DT');
      expect(formatTarif(fr, 7.125), '7,125 DT');
    });

    test('float noise from numeric(7,3) does not add decimals', () {
      expect(formatTarif(fr, 11.9999999), '12 DT');
      expect(formatTarif(fr, 12.5000001), '12,500 DT');
    });

    test('Arabic uses the Arabic currency label', () {
      expect(formatTarif(ar, 12), endsWith('د.ت'));
      expect(formatTarif(ar, 12), isNot(contains('000')));
      expect(formatTarif(ar, 12.5), isNot(equals(formatTarif(ar, 12))));
    });
  });
}
