import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/network_error.dart';

/// Why a queue action (or loading its data) failed, as shown to the user.
enum FileError {
  accesRefuse,
  aucunLouage,
  qrStationInvalide,
  dejaEnFile,
  reservationDejaEnCours,
  louagePasEnTete,
  louagePasComplet,
  reservationEnAttente,
  placesSousReservations,
  louageComplet,
  quitterImpossibleEnTete,
  passageDejaTermine,
  reseau,
  inconnue,
}

/// Thrown by `ChauffeurRepository`.
class FileAttenteException implements Exception {
  const FileAttenteException(this.error, [this.cause]);

  final FileError error;

  /// Underlying error, kept for logs.
  final Object? cause;

  /// For [FileError.reservationEnAttente]: when the last pending reservation
  /// expires (the RPC sends it as ISO 8601 UTC in the error DETAIL).
  DateTime? get expiration => expirationOf(cause);

  @override
  String toString() => 'FileAttenteException(${error.name}: $cause)';
}

/// Codes raised by the queue RPCs (`raise exception '<CODE>'`).
const _codes = {
  'ACCES_REFUSE': FileError.accesRefuse,
  'AUCUN_LOUAGE': FileError.aucunLouage,
  'QR_STATION_INVALIDE': FileError.qrStationInvalide,
  'DEJA_EN_FILE': FileError.dejaEnFile,
  'RESERVATION_DEJA_EN_COURS': FileError.reservationDejaEnCours,
  'LOUAGE_PAS_EN_TETE': FileError.louagePasEnTete,
  'LOUAGE_PAS_COMPLET': FileError.louagePasComplet,
  'RESERVATION_EN_ATTENTE': FileError.reservationEnAttente,
  'PLACES_SOUS_RESERVATIONS': FileError.placesSousReservations,
  'LOUAGE_COMPLET': FileError.louageComplet,
  'QUITTER_IMPOSSIBLE_EN_TETE': FileError.quitterImpossibleEnTete,
  'PASSAGE_DEJA_TERMINE': FileError.passageDejaTermine,
};

/// Expiry time carried in the DETAIL of a `RESERVATION_EN_ATTENTE` error,
/// or null if [error] has none.
DateTime? expirationOf(Object? error) {
  if (error is! PostgrestException) return null;
  final details = error.details;
  return details is String ? DateTime.tryParse(details) : null;
}

/// Maps a failure to a [FileError]. RPC errors are matched on the exact
/// code the database raises. Unexpected errors are logged with their stack
/// trace.
FileError classifyFileError(Object error, StackTrace stackTrace) {
  if (error is FileAttenteException) return error.error;
  if (isNetworkError(error)) return FileError.reseau;
  if (error is PostgrestException) {
    final known = _codes[error.message.trim()];
    if (known != null) return known;
  }
  developer.log(
    'Unexpected queue error',
    name: 'ChauffeurRepository',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  return FileError.inconnue;
}
