import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_role.dart';

/// Access to Supabase Auth and to the current user's role.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Reads `profiles.role` for `auth.uid()`.
  ///
  /// The real protection is Row Level Security in Supabase; this role is
  /// only used to choose which screens the app shows.
  Future<UserRole> getRole() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return UserRole.voyageur;
    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      return UserRole.fromValue(row['role'] as String?);
    } catch (e) {
      // TODO(US-01): the `profiles` table does not exist yet. Remove this
      // fallback (or turn it into an error screen) once US-01 creates it.
      developer.log(
        'Could not read profiles.role, falling back to voyageur',
        name: 'AuthRepository',
        level: 900, // WARNING
        error: e,
      );
      return UserRole.voyageur;
    }
  }
}
