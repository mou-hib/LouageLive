import '../../../l10n/app_localizations.dart';
import '../data/file_error.dart';

/// User-facing text of a [FileError].
String fileErrorMessage(AppLocalizations l10n, FileError error) =>
    switch (error) {
      FileError.accesRefuse => l10n.fileErrAccesRefuse,
      FileError.aucunLouage => l10n.fileErrAucunLouage,
      FileError.qrStationInvalide => l10n.fileErrQrInvalide,
      FileError.dejaEnFile => l10n.fileErrDejaEnFile,
      FileError.reseau => l10n.loginNetworkError,
      FileError.inconnue => l10n.genericError,
    };

/// [FileError] of any error thrown by the chauffeur repository.
FileError fileErrorOf(Object error) =>
    error is FileAttenteException ? error.error : FileError.inconnue;
