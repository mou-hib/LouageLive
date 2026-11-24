/// Why the current user's profile (`public.profils`) could not be loaded.
///
/// There is deliberately no fallback role: if the profile cannot be read,
/// the app shows an error screen instead of guessing.
sealed class ProfilException implements Exception {
  const ProfilException([this.cause]);

  /// Underlying error, kept for logs.
  final Object? cause;

  @override
  String toString() => '$runtimeType${cause == null ? '' : ': $cause'}';
}

/// No `profils` row is visible for `auth.uid()` (missing row, or hidden by RLS).
final class ProfilIntrouvable extends ProfilException {
  const ProfilIntrouvable([super.cause]);
}

/// The request did not reach Supabase or got no answer (offline, 3G drop, timeout).
final class ProfilErreurReseau extends ProfilException {
  const ProfilErreurReseau([super.cause]);
}

/// Supabase answered with an error (PostgREST / database error).
final class ProfilErreurServeur extends ProfilException {
  const ProfilErreurServeur([super.cause]);
}

/// Unexpected failure (most likely a bug), not a network problem. Logged
/// with its stack trace where it is caught.
final class ProfilErreurInconnue extends ProfilException {
  const ProfilErreurInconnue([super.cause]);
}

/// The row exists but its content is not usable (e.g. unknown or null role).
final class ProfilInvalide extends ProfilException {
  const ProfilInvalide([super.cause]);
}
