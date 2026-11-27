import '../../l10n/app_localizations.dart';
import 'notification_type.dart';

/// User-facing text of a notification.
String notificationMessage(AppLocalizations l10n, NotificationType type) =>
    switch (type) {
      NotificationType.tourDeRemplir => l10n.notifTourDeRemplir,
      NotificationType.reservationExpiree => l10n.notifReservationExpiree,
      NotificationType.reservationAnnulee => l10n.notifReservationAnnulee,
      NotificationType.reservationAnnuleeAgent =>
        l10n.notifReservationAnnuleeAgent,
      NotificationType.inconnue => l10n.notifInconnue,
    };
