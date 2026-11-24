import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show HandshakeException, SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profil.dart';
import 'profil_exception.dart';

/// Access to Supabase Auth and to the current user's profile.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Upper bound for the profile request, so a dead 3G connection ends on
  /// the error screen instead of an endless splash.
  static const profilTimeout = Duration(seconds: 15);

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
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
          .timeout(profilTimeout);
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
  if (error is SocketException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return ProfilErreurReseau(error);
  }
  developer.log(
    'Unexpected error while loading profils',
    name: 'AuthRepository',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  return ProfilErreurInconnue(error);
}
