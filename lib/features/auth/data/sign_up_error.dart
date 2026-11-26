import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_error.dart';

/// Why a voyageur sign-up failed, as shown to the user.
enum SignUpError {
  compteExistant,
  motDePasseFaible,
  tropDeTentatives,
  reseau,
  inconnue,
}

/// Thrown by `AuthRepository.signUp`.
class SignUpException implements Exception {
  const SignUpException(this.error, [this.cause]);

  final SignUpError error;

  /// Underlying error, kept for logs.
  final Object? cause;

  @override
  String toString() => 'SignUpException(${error.name}: $cause)';
}

/// Maps a sign-up failure to a [SignUpError], using `AuthException.code` and
/// the HTTP status — never the message text. Unexpected errors are logged
/// with their stack trace.
SignUpError classifySignUpError(Object error, StackTrace stackTrace) {
  if (error is SignUpException) return error.error;
  if (isAuthNetworkError(error)) return SignUpError.reseau;
  if (error is AuthException) {
    switch (error.code) {
      case 'user_already_exists':
      case 'email_exists':
        return SignUpError.compteExistant;
      case 'weak_password':
        return SignUpError.motDePasseFaible;
      case 'over_email_send_rate_limit':
        return SignUpError.tropDeTentatives;
    }
    if (error.statusCode == '429') return SignUpError.tropDeTentatives;
  }
  developer.log(
    'Unexpected sign-up error',
    name: 'AuthRepository',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  return SignUpError.inconnue;
}
