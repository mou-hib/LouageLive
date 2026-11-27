/// Kind of a row in `public.notifications`. The database stores no text,
/// only `type` (an upper-case code) and `donnees`; the app translates it.
enum NotificationType {
  /// The chauffeur's louage became head of the queue.
  tourDeRemplir,

  /// A pending reservation expired before it was scanned.
  reservationExpiree,

  /// A pending reservation was cancelled because the louage left the queue.
  reservationAnnulee,

  /// A pending reservation was cancelled when the line's agent authorised
  /// the departure (`autoriser_depart`).
  reservationAnnuleeAgent,

  /// A code this version of the app does not know.
  inconnue,
}

/// Codes written by the RPCs into `notifications.type`.
const _codes = {
  'TOUR_DE_REMPLIR': NotificationType.tourDeRemplir,
  'RESERVATION_EXPIREE': NotificationType.reservationExpiree,
  'RESERVATION_ANNULEE': NotificationType.reservationAnnulee,
  'RESERVATION_ANNULEE_AGENT': NotificationType.reservationAnnuleeAgent,
};

/// Maps `notifications.type` to a [NotificationType] (exact code only).
NotificationType notificationTypeOf(String? code) =>
    _codes[code?.trim()] ?? NotificationType.inconnue;
