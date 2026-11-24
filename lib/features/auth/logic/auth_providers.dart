import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/auth_repository.dart';
import '../data/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

enum AuthStatus { loading, signedOut, signedIn }

/// Session state (status + role), listened to by go_router through
/// `refreshListenable` so login/logout redirect immediately.
class AuthSession extends ChangeNotifier {
  AuthSession(this._repository) {
    _subscription = _repository.authStateChanges().listen(_onAuthEvent);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _subscription;
  int _generation = 0;

  AuthStatus status = AuthStatus.loading;
  UserRole? role;

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

  Future<void> _refresh() async {
    final generation = ++_generation;
    if (_repository.currentSession == null) {
      _set(AuthStatus.signedOut, null);
      return;
    }
    _set(AuthStatus.loading, null);
    final resolved = await _repository.getRole();
    if (generation != _generation) return; // a newer event won the race
    _set(AuthStatus.signedIn, resolved);
  }

  void _set(AuthStatus newStatus, UserRole? newRole) {
    status = newStatus;
    role = newRole;
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
