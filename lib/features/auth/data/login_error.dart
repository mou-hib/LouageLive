import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_error.dart';

/// Why a sign-in failed, as shown to the user.
enum LoginError {
  identifiantsInvalides,
  emailNonConfirme,
  tropDeTentatives,
  reseau,
  inconnue,
}

/// Thrown by `AuthRepository.signIn`.
class LoginException implements Exception {
  const LoginException(this.error, [this.cause]);

  final LoginError error;

  /// Underlying error, kept for logs.
  final Object? cause;

  @override
  String toString() => 'LoginException(${error.name}: $cause)';
}

/// Maps a sign-in failure to a [LoginError], using `AuthException.code` and
/// the HTTP status — never the message text. Unexpected errors are logged
/// with their stack trace.
LoginError classifyLoginError(Object error, StackTrace stackTrace) {
  if (isNetworkError(error)) return LoginError.reseau;
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return LoginError.identifiantsInvalides;
      case 'email_not_confirmed':
        return LoginError.emailNonConfirme;
      case 'over_request_rate_limit':
        return LoginError.tropDeTentatives;
    }
    if (error.statusCode == '429') return LoginError.tropDeTentatives;
    // gotrue wraps transport failures (Socket/ClientException...) in
    // AuthRetryableFetchException without a status code. With a status code
    // (5xx) it is a server error, not a network one.
    if (error is AuthRetryableFetchException && error.statusCode == null) {
      return LoginError.reseau;
    }
  }
  developer.log(
    'Unexpected sign-in error',
    name: 'AuthRepository',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  return LoginError.inconnue;
}
