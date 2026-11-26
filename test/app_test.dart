import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/l10n/locale_provider.dart';
import 'package:louage_live/core/router/app_router.dart';

import 'dart:io' show HandshakeException, SocketException;

import 'package:http/http.dart' as http;
import 'package:louage_live/features/auth/data/auth_repository.dart';
import 'package:louage_live/features/auth/data/login_error.dart';
import 'package:louage_live/features/auth/data/profil.dart';
import 'package:louage_live/features/auth/data/profil_exception.dart';
import 'package:louage_live/features/auth/data/user_role.dart';
import 'package:louage_live/features/auth/logic/auth_providers.dart';
import 'package:louage_live/features/auth/logic/auth_validators.dart';
import 'package:louage_live/features/auth/presentation/login_screen.dart';
import 'package:louage_live/features/auth/presentation/profile_error_screen.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fake_auth_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthApiException,
        AuthChangeEvent,
        AuthException,
        AuthRetryableFetchException,
        PostgrestException;

Future<ProviderContainer> _pumpLogin(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const LoginScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Login screen is in French (LTR) by default', (tester) async {
    await _pumpLogin(tester);

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LoginScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('Switching to Arabic flips the layout to RTL', (tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pumpAndSettle();

    expect(find.text('دخول'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LoginScreen))),
      TextDirection.rtl,
    );
  });

  group('redirectFor', () {
    test('signed out goes to /login', () {
      expect(redirectFor(AuthStatus.signedOut, null, '/admin'), '/login');
      expect(redirectFor(AuthStatus.signedOut, null, '/voyageur'), '/login');
      expect(
        redirectFor(AuthStatus.signedOut, null, '/erreur-profil'),
        '/login',
      );
      expect(redirectFor(AuthStatus.signedOut, null, '/login'), isNull);
    });

    test('/inscription is reachable only when signed out', () {
      expect(redirectFor(AuthStatus.signedOut, null, '/inscription'), isNull);
      expect(
        redirectFor(AuthStatus.loading, null, '/inscription'),
        '/chargement',
      );
      expect(
        redirectFor(AuthStatus.profileError, null, '/inscription'),
        '/erreur-profil',
      );
      for (final role in UserRole.values) {
        expect(
          redirectFor(AuthStatus.signedIn, role, '/inscription'),
          role.homePath,
        );
      }
    });

    test('loading goes to splash', () {
      expect(redirectFor(AuthStatus.loading, null, '/login'), '/chargement');
    });

    test('signed in with each role goes to its own home', () {
      for (final role in UserRole.values) {
        expect(redirectFor(AuthStatus.signedIn, role, '/login'), role.homePath);
        expect(
          redirectFor(AuthStatus.signedIn, role, '/chargement'),
          role.homePath,
        );
        expect(redirectFor(AuthStatus.signedIn, role, role.homePath), isNull);
      }
    });

    test("signed in on another role's path is redirected to its own home", () {
      for (final role in UserRole.values) {
        for (final other in UserRole.values.where((r) => r != role)) {
          expect(
            redirectFor(AuthStatus.signedIn, role, other.homePath),
            role.homePath,
            reason: '${role.name} must not stay on ${other.homePath}',
          );
        }
      }
    });

    test('profile error goes to the error screen, never a role home', () {
      expect(
        redirectFor(AuthStatus.profileError, null, '/voyageur'),
        '/erreur-profil',
      );
      expect(
        redirectFor(AuthStatus.profileError, null, '/login'),
        '/erreur-profil',
      );
      expect(
        redirectFor(AuthStatus.profileError, null, '/erreur-profil'),
        isNull,
      );
    });

    test('signed in without a role goes to the error screen, not voyageur', () {
      expect(
        redirectFor(AuthStatus.signedIn, null, '/login'),
        '/erreur-profil',
      );
      expect(
        redirectFor(AuthStatus.signedIn, null, '/voyageur'),
        '/erreur-profil',
      );
    });
  });

  group('UserRole.fromValue', () {
    test('parses the 4 roles', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromValue(role.name), role);
      }
    });

    test('unknown or null role is an error, not voyageur', () {
      expect(
        () => UserRole.fromValue('hacker'),
        throwsA(isA<ProfilInvalide>()),
      );
      expect(() => UserRole.fromValue(null), throwsA(isA<ProfilInvalide>()));
    });
  });

  group('Profil.fromRow', () {
    test('reads id, role and doit_changer_mdp', () {
      expect(
        Profil.fromRow({'id': 'u1', 'role': 'agent', 'doit_changer_mdp': true}),
        const Profil(id: 'u1', role: UserRole.agent, doitChangerMdp: true),
      );
    });

    test('malformed rows throw ProfilInvalide', () {
      expect(
        () => Profil.fromRow({
          'id': 'u1',
          'role': null,
          'doit_changer_mdp': false,
        }),
        throwsA(isA<ProfilInvalide>()),
      );
      expect(
        () => Profil.fromRow({'id': 'u1', 'role': 'admin'}),
        throwsA(isA<ProfilInvalide>()),
      );
    });
  });

  group('AuthSession', () {
    test('profile error, then retry succeeds', () async {
      final repo = FakeAuthRepository()
        ..next = () => throw const ProfilErreurReseau();
      final session = AuthSession(repo);
      addTearDown(session.dispose);

      repo.emit(AuthChangeEvent.initialSession);
      await pumpEventQueue();
      expect(session.status, AuthStatus.profileError);
      expect(session.error, isA<ProfilErreurReseau>());
      expect(session.role, isNull);

      repo.next = () async => const Profil(
        id: 'u1',
        role: UserRole.chauffeur,
        doitChangerMdp: false,
      );
      await session.retry();
      expect(session.status, AuthStatus.signedIn);
      expect(session.role, UserRole.chauffeur);
      expect(session.error, isNull);
    });

    test('missing profile is a profile error, not voyageur', () async {
      final repo = FakeAuthRepository()
        ..next = () => throw const ProfilIntrouvable();
      final session = AuthSession(repo);
      addTearDown(session.dispose);

      repo.emit(AuthChangeEvent.signedIn);
      await pumpEventQueue();
      expect(session.status, AuthStatus.profileError);
      expect(session.role, isNull);
    });

    test('no session is signed out', () async {
      final repo = FakeAuthRepository()..hasSession = false;
      final session = AuthSession(repo);
      addTearDown(session.dispose);

      repo.emit(AuthChangeEvent.signedOut);
      await pumpEventQueue();
      expect(session.status, AuthStatus.signedOut);
    });
  });

  group('classifyLoginError', () {
    final st = StackTrace.current;
    LoginError classify(Object e) => classifyLoginError(e, st);

    test('invalid_credentials → identifiantsInvalides', () {
      expect(
        classify(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        LoginError.identifiantsInvalides,
      );
    });

    test('email_not_confirmed → emailNonConfirme', () {
      expect(
        classify(
          const AuthApiException(
            'Email not confirmed',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
        ),
        LoginError.emailNonConfirme,
      );
    });

    test('over_request_rate_limit → tropDeTentatives', () {
      expect(
        classify(
          const AuthApiException(
            'Rate limit',
            statusCode: '429',
            code: 'over_request_rate_limit',
          ),
        ),
        LoginError.tropDeTentatives,
      );
    });

    test('status 429 without a known code → tropDeTentatives', () {
      expect(
        classify(const AuthApiException('Too many', statusCode: '429')),
        LoginError.tropDeTentatives,
      );
    });

    test('the code decides, not the message text', () {
      expect(
        classify(
          const AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'user_banned',
          ),
        ),
        LoginError.inconnue,
      );
    });

    test('transport failures → reseau', () {
      for (final e in <Object>[
        const SocketException('down'),
        const HandshakeException('tls'),
        TimeoutException('slow'),
        http.ClientException('reset'),
        AuthRetryableFetchException(message: 'ClientException: reset'),
      ]) {
        expect(classify(e), LoginError.reseau, reason: '$e');
      }
    });

    test('server error 5xx is not a network error', () {
      expect(
        classify(AuthRetryableFetchException(message: 'x', statusCode: '503')),
        LoginError.inconnue,
      );
    });

    test('unknown AuthException code → inconnue', () {
      expect(
        classify(const AuthException('?', statusCode: '400', code: 'weird')),
        LoginError.inconnue,
      );
    });

    test('StateError → inconnue', () {
      expect(classify(StateError('bug')), LoginError.inconnue);
    });
  });

  group('isValidEmail', () {
    test('accepts simple addresses', () {
      expect(isValidEmail('a@b.tn'), isTrue);
      expect(isValidEmail('  chauffeur.1@louage-live.tn '), isTrue);
    });

    test('rejects malformed addresses', () {
      for (final v in ['', 'abc', 'a@b', '@b.tn', 'a b@c.tn', 'a@b.']) {
        expect(isValidEmail(v), isFalse, reason: v);
      }
    });
  });

  testWidgets('Login shows the mapped error and validates the e-mail', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeAuthRepository()..signInError = LoginError.reseau;
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'pas-un-email');
    await tester.enterText(fields.at(1), 'secret');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse e-mail invalide.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'voyageur@louage.tn');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse e-mail invalide.'), findsNothing);
    expect(find.text('Pas de connexion internet.'), findsOneWidget);
  });

  test('only transport failures are classified as network errors', () {
    final st = StackTrace.current;
    for (final e in <Object>[
      const SocketException('down'),
      TimeoutException('slow'),
      http.ClientException('reset'),
    ]) {
      expect(classifyProfilError(e, st), isA<ProfilErreurReseau>());
    }
    expect(
      classifyProfilError(const PostgrestException(message: 'x'), st),
      isA<ProfilErreurServeur>(),
    );
    expect(
      classifyProfilError(StateError('bug'), st),
      isA<ProfilErreurInconnue>(),
    );
    expect(
      classifyProfilError(const FormatException(), st),
      isA<ProfilErreurInconnue>(),
    );
  });

  testWidgets('Unexpected StateError shows the generic message, not network', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeAuthRepository()..next = () => throw StateError('bug');
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider);
    repo.emit(AuthChangeEvent.initialSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const ProfileErrorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final session = container.read(authSessionProvider);
    expect(session.status, AuthStatus.profileError);
    expect(session.error, isA<ProfilErreurInconnue>());
    expect(find.textContaining('contactez l\'administrateur'), findsOneWidget);
    expect(find.textContaining('connexion internet'), findsNothing);
  });

  testWidgets('Profile error screen shows message, retry and logout (FR)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeAuthRepository()
      ..next = () => throw const ProfilIntrouvable();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider);
    repo.emit(AuthChangeEvent.initialSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const ProfileErrorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Impossible de charger votre profil'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);

    repo.next = () async =>
        const Profil(id: 'u1', role: UserRole.admin, doitChangerMdp: false);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(container.read(authSessionProvider).status, AuthStatus.signedIn);

    await tester.tap(find.text('Se déconnecter'));
    expect(repo.signOutCalls, 1);
  });
}
