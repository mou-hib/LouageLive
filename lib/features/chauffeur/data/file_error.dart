import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/network/network_error.dart';

/// Why a queue action (or loading its data) failed, as shown to the user.
enum FileError {
  accesRefuse,
  aucunLouage,
  qrStationInvalide,
  dejaEnFile,
  reseau,
  inconnue,
}

/// Thrown by `ChauffeurRepository`.
class FileAttenteException implements Exception {
  const FileAttenteException(this.error, [this.cause]);

  final FileError error;

  /// Underlying error, kept for logs.
  final Object? cause;

  @override
  String toString() => 'FileAttenteException(${error.name}: $cause)';
}

/// Codes raised by the queue RPCs (`raise exception '<CODE>'`).
const _codes = {
  'ACCES_REFUSE': FileError.accesRefuse,
  'AUCUN_LOUAGE': FileError.aucunLouage,
  'QR_STATION_INVALIDE': FileError.qrStationInvalide,
  'DEJA_EN_FILE': FileError.dejaEnFile,
};

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
