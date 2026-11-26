import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/network_error.dart';
import 'login_error.dart';
import 'profil.dart';
import 'profil_exception.dart';

/// Access to Supabase Auth and to the current user's profile.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Upper bound for auth/profile requests, so a dead 3G connection ends on
  /// an error message instead of an endless loader.
  static const requestTimeout = Duration(seconds: 15);

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  /// Throws a [LoginException] whose [LoginError] says why it failed.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(requestTimeout);
    } catch (e, st) {
      Error.throwWithStackTrace(
        LoginException(classifyLoginError(e, st), e),
        st,
      );
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Reads `role, doit_changer_mdp` from `public.profils` for `auth.uid()`.
  ///
  /// The real protection is Row Level Security in Supabase; the role is
  /// only used to choose which screens the app shows.
  ///
  /// Throws a [ProfilException]; never falls back to a default role.
  Future<Profil> getProfil() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw const ProfilIntrouvable('No signed-in user');
    final Map<String, dynamic>? row;
    try {
      row = await _client
          .from('profils')
          .select('id, role, doit_changer_mdp')
          .eq('id', uid)
          .maybeSingle()
          .timeout(requestTimeout);
    } catch (e, st) {
      Error.throwWithStackTrace(classifyProfilError(e, st), st);
    }
    if (row == null) throw ProfilIntrouvable('No profils row for $uid');
    return Profil.fromRow(row);
  }
}

/// Maps a failure of the `profils` request to a [ProfilException].
///
/// Only real transport failures count as network errors, so a bug is never
/// shown to the user as "no internet". Unexpected errors are logged with
/// their stack trace.
@visibleForTesting
ProfilException classifyProfilError(Object error, StackTrace stackTrace) {
  if (error is ProfilException) return error;
  if (error is PostgrestException) return ProfilErreurServeur(error);
  if (isNetworkError(error)) return ProfilErreurReseau(error);
  developer.log(
    'Unexpected error while loading profils',
    name: 'AuthRepository',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  return ProfilErreurInconnue(error);
}
