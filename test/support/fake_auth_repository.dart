import 'dart:async';

import 'package:louage_live/features/auth/data/auth_repository.dart';
import 'package:louage_live/features/auth/data/login_error.dart';
import 'package:louage_live/features/auth/data/profil.dart';
import 'package:louage_live/features/auth/data/sign_up_error.dart';
import 'package:louage_live/features/auth/data/user_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session, User;

/// Arguments of a [FakeAuthRepository.signUp] call.
typedef SignUpCall = ({
  String email,
  String password,
  String nom,
  String prenom,
  String telephone,
});

/// AuthRepository without Supabase: [next] decides what getProfil returns.
class FakeAuthRepository implements AuthRepository {
  final _events = StreamController<AuthState>.broadcast();
  bool hasSession = true;
  Future<Profil> Function() next = () async =>
      const Profil(id: 'u1', role: UserRole.voyageur, doitChangerMdp: false);
  int signOutCalls = 0;

  /// When set, signIn fails with this error.
  LoginError? signInError;

  /// When set, signUp fails with this error; otherwise returns [signUpOutcome].
  SignUpError? signUpError;
  SignUpOutcome signUpOutcome = SignUpOutcome.confirmationEmail;
  final signUpCalls = <SignUpCall>[];

  void emit(AuthChangeEvent event) => _events.add(AuthState(event, null));

  @override
  Stream<AuthState> authStateChanges() => _events.stream;

  @override
  Session? get currentSession => hasSession
      ? Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: const User(
            id: 'u1',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-01-01T00:00:00Z',
          ),
        )
      : null;

  @override
  Future<Profil> getProfil() => next();

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError case final error?) throw LoginException(error);
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    signUpCalls.add((
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
      telephone: telephone,
    ));
    if (signUpError case final error?) throw SignUpException(error);
    return signUpOutcome;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
