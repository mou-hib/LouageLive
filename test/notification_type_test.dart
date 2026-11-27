import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/notifications/notification_message.dart';
import 'package:louage_live/core/notifications/notification_type.dart';
import 'package:louage_live/l10n/app_localizations.dart';

void main() {
  test('database codes → NotificationType', () {
    expect(
      notificationTypeOf('TOUR_DE_REMPLIR'),
      NotificationType.tourDeRemplir,
    );
    expect(
      notificationTypeOf('RESERVATION_EXPIREE'),
      NotificationType.reservationExpiree,
    );
    expect(
      notificationTypeOf('RESERVATION_ANNULEE'),
      NotificationType.reservationAnnulee,
    );
    expect(
      notificationTypeOf('RESERVATION_ANNULEE_AGENT'),
      NotificationType.reservationAnnuleeAgent,
    );
  });

  test('old lower-case name and unknown codes → inconnue', () {
    expect(
      notificationTypeOf('reservation_annulee_agent'),
      NotificationType.inconnue,
    );
    expect(notificationTypeOf('AUTRE'), NotificationType.inconnue);
    expect(notificationTypeOf(null), NotificationType.inconnue);
  });

  test('every NotificationType has a distinct FR and AR text', () {
    for (final locale in const [Locale('fr'), Locale('ar')]) {
      final l10n = lookupAppLocalizations(locale);
      final texts = NotificationType.values
          .map((t) => notificationMessage(l10n, t))
          .toList();
      expect(texts.every((t) => t.isNotEmpty), isTrue);
      expect(texts.toSet().length, texts.length, reason: locale.languageCode);
    }
  });
}
