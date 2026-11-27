import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_error.dart';

/// Why the forced password change (A8) failed, as shown to the user.
enum ChangePasswordError {
  /// `weak_password`: too short, or found in a leaked-password list.
  motDePasseFaible,

  /// `same_password`: the new password is the temporary one.
  memeMotDePasse,

  /// `reauthentication_needed` / expired session: sign in again.
  sessionExpiree,
  tropDeTentatives,
  reseau,
  inconnue,
}

/// Thrown by `AuthRepository.updatePassword` / `markPasswordChanged`.
class ChangePasswordException implements Exception {
  const ChangePasswordException(this.error, [this.cause]);

  final ChangePasswordError error;

  /// Underlying error, kept for logs.
  final Object? cause;

  @override
  String toString() => 'ChangePasswordException(${error.name}: $cause)';
}

/// Maps a failure of `auth.updateUser` or of the `marquer_mdp_change` RPC to
/// a [ChangePasswordError], using `AuthException.code` and the HTTP status —
/// never the message text. Unexpected errors are logged.
ChangePasswordError classifyChangePasswordError(
  Object error,
  StackTrace stackTrace,
) {
  if (error is ChangePasswordException) return error.error;
  if (isAuthNetworkError(error)) return ChangePasswordError.reseau;
  if (error is AuthException) {
    switch (error.code) {
      case 'weak_password':
        return ChangePasswordError.motDePasseFaible;
      case 'same_password':
        return ChangePasswordError.memeMotDePasse;
      case 'reauthentication_needed':
      case 'session_not_found':
      case 'session_expired':
        return ChangePasswordError.sessionExpiree;
      case 'over_request_rate_limit':
        return ChangePasswordError.tropDeTentatives;
    }
    if (error is AuthSessionMissingException) {
      return ChangePasswordError.sessionExpiree;
    }
    if (error.statusCode == '429') return ChangePasswordError.tropDeTentatives;
  }
  developer.log(
    'Unexpected password change error',
    name: 'AuthRepository',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  return ChangePasswordError.inconnue;
}
