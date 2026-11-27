import '../../../l10n/app_localizations.dart';
import '../data/file_error.dart';

/// User-facing text of a [FileError]. [expiration] (see
/// [FileAttenteException.expiration]) is shown for
/// [FileError.reservationEnAttente] when known.
String fileErrorMessage(
  AppLocalizations l10n,
  FileError error, {
  DateTime? expiration,
}) => switch (error) {
  FileError.accesRefuse => l10n.fileErrAccesRefuse,
  FileError.aucunLouage => l10n.fileErrAucunLouage,
  FileError.qrStationInvalide => l10n.fileErrQrInvalide,
  FileError.dejaEnFile => l10n.fileErrDejaEnFile,
  FileError.reservationDejaEnCours => l10n.fileErrReservationDejaEnCours,
  FileError.louagePasEnTete => l10n.fileErrLouagePasEnTete,
  FileError.louagePasComplet => l10n.fileErrLouagePasComplet,
  FileError.reservationEnAttente =>
    expiration == null
        ? l10n.fileErrReservationEnAttente
        : l10n.fileErrReservationEnAttenteJusqua(expiration.toLocal()),
  FileError.placesSousReservations => l10n.fileErrPlacesSousReservations,
  FileError.reseau => l10n.loginNetworkError,
  FileError.inconnue => l10n.genericError,
};

/// [FileError] of any error thrown by the chauffeur repository.
FileError fileErrorOf(Object error) =>
    error is FileAttenteException ? error.error : FileError.inconnue;
