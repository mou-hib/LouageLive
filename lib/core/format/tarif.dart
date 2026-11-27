import 'package:intl/intl.dart' show NumberFormat;

import '../../l10n/app_localizations.dart';

/// A fare in TND, ready to show: "12 DT" for a whole amount, otherwise the
/// 3 decimals of the dinar ("12,500 DT"). "12,000" is never shown: many
/// readers take it for twelve thousand.
///
/// The one place fares are formatted; the result reads left-to-right in
/// Arabic too (wrap it in a bidi isolate inside a sentence).
String formatTarif(AppLocalizations l10n, num tarif) {
  // Compare in millimes: 12.000 stored as numeric may arrive as 11.9999…
  final millimes = (tarif * 1000).round();
  final pattern = millimes % 1000 == 0 ? '#,##0' : '#,##0.000';
  final amount = NumberFormat(pattern, l10n.localeName).format(millimes / 1000);
  return l10n.tarifDt(amount);
}
