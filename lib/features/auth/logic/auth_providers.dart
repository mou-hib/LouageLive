import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';
import '../data/profil.dart';
import '../data/profil_exception.dart';
import '../data/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

enum AuthStatus {
  loading,
  signedOut,
  signedIn,

  /// Signed in, but the profile (and so the role) could not be loaded.
  profileError,
}

/// Session state (status + profile), listened to by go_router through
/// `refreshListenable` so login/logout redirect immediately.
class AuthSession extends ChangeNotifier {
  AuthSession(this._repository) {
    _subscription = _repository.authStateChanges().listen(_onAuthEvent);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;
  int _generation = 0;

  AuthStatus status = AuthStatus.loading;

  /// Set only when [status] is [AuthStatus.signedIn].
  Profil? profil;

  /// Set only when [status] is [AuthStatus.profileError].
  ProfilException? error;

  UserRole? get role => profil?.role;

  void _onAuthEvent(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.signedOut:
      case AuthChangeEvent.userUpdated:
        _refresh();
      default:
        break; // tokenRefreshed, passwordRecovery, ...: no redirect needed.
    }
  }

  /// Reloads the profile (the "Réessayer" button of the error screen).
  Future<void> retry() => _refresh();

  Future<void> _refresh() async {
    final generation = ++_generation;
    if (_repository.currentSession == null) {
      _set(AuthStatus.signedOut);
      return;
    }
    _set(AuthStatus.loading);
    try {
      final loaded = await _repository.getProfil();
      if (generation != _generation) return; // a newer event won the race
      _set(AuthStatus.signedIn, profil: loaded);
    } on ProfilException catch (e) {
      if (generation != _generation) return;
      developer.log(
        'Could not load profils row',
        name: 'AuthSession',
        level: 1000, // SEVERE
        error: e,
      );
      _set(AuthStatus.profileError, error: e);
    } catch (e, st) {
      // Not a ProfilException: a bug somewhere. Still no default role.
      if (generation != _generation) return;
      developer.log(
        'Unexpected error while loading the profile',
        name: 'AuthSession',
        level: 1000, // SEVERE
        error: e,
        stackTrace: st,
      );
      _set(AuthStatus.profileError, error: ProfilErreurInconnue(e));
    }
  }

  void _set(AuthStatus newStatus, {Profil? profil, ProfilException? error}) {
    status = newStatus;
    this.profil = profil;
    this.error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(ref.watch(authRepositoryProvider));
  ref.onDispose(session.dispose);
  return session;
});
