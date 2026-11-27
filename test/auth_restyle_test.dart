import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/l10n/locale_provider.dart';
import 'package:louage_live/core/network/connectivity.dart';
import 'package:louage_live/core/router/app_router.dart';
import 'package:louage_live/core/theme/app_theme.dart';
import 'package:louage_live/core/widgets/ll_banner.dart';
import 'package:louage_live/core/widgets/ll_button.dart';
import 'package:louage_live/core/widgets/ll_logo.dart';
import 'package:louage_live/features/auth/data/change_password_error.dart';
import 'package:louage_live/features/auth/data/login_error.dart';
import 'package:louage_live/features/auth/data/profil.dart';
import 'package:louage_live/features/auth/data/user_role.dart';
import 'package:louage_live/features/auth/logic/auth_providers.dart';
import 'package:louage_live/features/auth/logic/auth_validators.dart';
import 'package:louage_live/features/auth/presentation/change_password_screen.dart';
import 'package:louage_live/features/auth/presentation/login_screen.dart';
import 'package:louage_live/features/auth/presentation/profile_error_screen.dart';
import 'package:louage_live/features/auth/presentation/signup_screen.dart';
import 'package:louage_live/features/auth/presentation/splash_screen.dart';
import 'package:louage_live/features/voyageur/presentation/voyageur_home_screen.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthApiException,
        AuthChangeEvent,
        AuthRetryableFetchException,
        AuthSessionMissingException;

import 'support/fake_auth_repository.dart';

/// Container with a fake repository and a controllable connectivity.
Future<ProviderContainer> _container(
  FakeAuthRepository repo, {
  Stream<bool>? online,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repo),
      isOnlineProvider.overrideWith((ref) => online ?? Stream.value(true)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _pumpHome(
  WidgetTester tester,
  ProviderContainer container,
  Widget home,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _fields => find.byType(TextFormField);

bool _fieldEnabled(WidgetTester tester, int i) =>
    tester.widget<TextFormField>(_fields.at(i)).enabled;

String? _fieldError(WidgetTester tester, int i) => tester
    .widget<InputDecorator>(
      find.descendant(of: _fields.at(i), matching: find.byType(InputDecorator)),
    )
    .decoration
    .errorText;

LLButton _primaryButton(WidgetTester tester) => tester
    .widgetList<LLButton>(find.byType(LLButton))
    .firstWhere((b) => b.variant == LLButtonVariant.primary);

void main() {
  group('A2 login — 4 states', () {
    testWidgets('normal: header, title, fields, links, black button', (
      tester,
    ) async {
      final container = await _container(FakeAuthRepository());
      await _pumpHome(tester, container, const LoginScreen());

      expect(find.byType(LLLogo), findsOneWidget);
      expect(find.text('Louage Live'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget); // language pill
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
      expect(find.text('Créer un compte voyageur'), findsOneWidget);
      expect(find.byType(LLBanner), findsNothing);

      final button = _primaryButton(tester);
      expect(button.label, 'Se connecter');
      expect(button.onPressed, isNotNull);
      expect(button.loading, isFalse);
      expect(_fieldEnabled(tester, 0), isTrue);
    });

    testWidgets('loading: fields read-only, "Connexion…", no double submit', (
      tester,
    ) async {
      final repo = FakeAuthRepository()..signInGate = Completer<void>();
      final container = await _container(repo);
      await _pumpHome(tester, container, const LoginScreen());

      await tester.enterText(_fields.at(0), 'voyageur@louage.tn');
      await tester.enterText(_fields.at(1), 'secret1');
      await tester.tap(find.text('Se connecter'));
      await tester.pump();

      final button = _primaryButton(tester);
      expect(button.loading, isTrue);
      expect(button.label, 'Connexion…');
      expect(_fieldEnabled(tester, 0), isFalse);
      expect(_fieldEnabled(tester, 1), isFalse);

      // Second tap and keyboard "done" while loading: ignored.
      await tester.tap(find.byType(LLButton).first, warnIfMissed: false);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.signInCalls, 1);

      repo.signInGate!.complete();
      await tester.pumpAndSettle();
      expect(_primaryButton(tester).loading, isFalse);
      expect(_fieldEnabled(tester, 0), isTrue);
    });

    testWidgets('error: banner + red field with helper, cleared on edit', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..signInError = LoginError.identifiantsInvalides;
      final container = await _container(repo);
      await _pumpHome(tester, container, const LoginScreen());

      await tester.enterText(_fields.at(0), 'voyageur@louage.tn');
      await tester.enterText(_fields.at(1), 'mauvais');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      final banner = tester.widget<LLBanner>(find.byType(LLBanner));
      expect(banner.kind, LLBannerKind.error);
      expect(banner.message, 'E-mail ou mot de passe incorrect.');
      expect(_fieldError(tester, 1), "Vérifiez l'e-mail et le mot de passe.");
      expect(_fieldError(tester, 0), isNull);

      await tester.enterText(_fields.at(1), 'autre');
      await tester.pump();
      expect(find.byType(LLBanner), findsNothing);
      expect(_fieldError(tester, 1), isNull);
    });

    testWidgets('error: unconfirmed e-mail marks the e-mail field', (
      tester,
    ) async {
      final repo = FakeAuthRepository()
        ..signInError = LoginError.emailNonConfirme;
      final container = await _container(repo);
      await _pumpHome(tester, container, const LoginScreen());

      await tester.enterText(_fields.at(0), 'voyageur@louage.tn');
      await tester.enterText(_fields.at(1), 'secret1');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Adresse e-mail non confirmée.'), findsOneWidget);
      expect(_fieldError(tester, 0), isNotNull);
      expect(_fieldError(tester, 1), isNull);
    });

    testWidgets('offline: banner, button disabled until the network is back', (
      tester,
    ) async {
      final network = StreamController<bool>();
      addTearDown(network.close);
      final repo = FakeAuthRepository();
      final container = await _container(repo, online: network.stream);
      network.add(false);
      await _pumpHome(tester, container, const LoginScreen());

      final banner = tester.widget<LLBanner>(find.byType(LLBanner));
      expect(banner.kind, LLBannerKind.offline);
      expect(_primaryButton(tester).onPressed, isNull);

      await tester.enterText(_fields.at(0), 'voyageur@louage.tn');
      await tester.enterText(_fields.at(1), 'secret1');
      await tester.tap(find.text('Se connecter'), warnIfMissed: false);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.signInCalls, 0);

      network.add(true);
      await tester.pumpAndSettle();
      expect(find.byType(LLBanner), findsNothing);
      expect(_primaryButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(repo.signInCalls, 1);
    });
  });

  group('A8 checklist', () {
    test('rules', () {
      var r = newPasswordRules('', '');
      expect(
        (r.longEnough, r.hasDigit, r.matches, r.allPass),
        (false, false, false, false),
      );
      r = newPasswordRules('abcdefgh', 'abcdefgh');
      expect((r.longEnough, r.hasDigit, r.matches), (true, false, true));
      r = newPasswordRules('abcdef1', 'abcdef1');
      expect((r.longEnough, r.hasDigit, r.matches), (false, true, true));
      r = newPasswordRules('abcdefg1', 'abcdefg2');
      expect((r.longEnough, r.hasDigit, r.matches), (true, true, false));
      expect(newPasswordRules('abcdefg1', 'abcdefg1').allPass, isTrue);
      expect(minNewPasswordLength, 8);
    });

    Color iconColor(WidgetTester tester, String key) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(Icon),
          ),
        )
        .color!;

    testWidgets('live colours and button enabled only when all pass', (
      tester,
    ) async {
      final container = await _container(FakeAuthRepository());
      await _pumpHome(tester, container, const ChangePasswordScreen());
      const c = LLColors.light;

      expect(find.text('Nouveau mot de passe'), findsNWidgets(2));
      expect(
        find.text('Connecté en tant que \u2068chauffeur3@louage.tn\u2069'),
        findsOneWidget,
      );
      expect(
        tester.widget<LLBanner>(find.byType(LLBanner).first).kind,
        LLBannerKind.warn,
      );
      for (final k in ['rule-length', 'rule-digit', 'rule-match']) {
        expect(iconColor(tester, k), c.seatFull, reason: k);
      }
      expect(_primaryButton(tester).onPressed, isNull);

      await tester.enterText(_fields.at(0), 'abcdefgh');
      await tester.pump();
      expect(iconColor(tester, 'rule-length'), c.success);
      expect(iconColor(tester, 'rule-digit'), c.seatFull);
      expect(iconColor(tester, 'rule-match'), c.seatFull);
      expect(_primaryButton(tester).onPressed, isNull);

      await tester.enterText(_fields.at(0), 'abcdefg1');
      await tester.enterText(_fields.at(1), 'abcdefg1');
      await tester.pump();
      for (final k in ['rule-length', 'rule-digit', 'rule-match']) {
        expect(iconColor(tester, k), c.success, reason: k);
      }
      expect(_primaryButton(tester).onPressed, isNotNull);

      await tester.enterText(_fields.at(1), 'abcdefg2');
      await tester.pump();
      expect(iconColor(tester, 'rule-match'), c.seatFull);
      expect(_primaryButton(tester).onPressed, isNull);
    });

    testWidgets('no back button, sign-out available', (tester) async {
      final repo = FakeAuthRepository();
      final container = await _container(repo);
      await _pumpHome(tester, container, const ChangePasswordScreen());

      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(BackButtonIcon), findsNothing);
      await tester.tap(find.text('Se déconnecter'));
      expect(repo.signOutCalls, 1);
    });

    testWidgets('Supabase errors are mapped to ARB strings', (tester) async {
      final repo = FakeAuthRepository()
        ..updatePasswordError = ChangePasswordError.memeMotDePasse;
      final container = await _container(repo);
      await _pumpHome(tester, container, const ChangePasswordScreen());

      await tester.enterText(_fields.at(0), 'abcdefg1');
      await tester.enterText(_fields.at(1), 'abcdefg1');
      await tester.pump();
      await tester.tap(find.text('Enregistrer et continuer'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Le nouveau mot de passe doit être différent du mot de passe '
          'temporaire.',
        ),
        findsOneWidget,
      );
      expect(repo.markPasswordChangedCalls, 0);
    });
  });

  group('classifyChangePasswordError', () {
    final st = StackTrace.current;
    ChangePasswordError classify(Object e) =>
        classifyChangePasswordError(e, st);
    AuthApiException api(String code) =>
        AuthApiException('message ignoré', statusCode: '422', code: code);

    test('codes', () {
      expect(
        classify(api('weak_password')),
        ChangePasswordError.motDePasseFaible,
      );
      expect(
        classify(api('same_password')),
        ChangePasswordError.memeMotDePasse,
      );
      expect(
        classify(api('reauthentication_needed')),
        ChangePasswordError.sessionExpiree,
      );
      expect(
        classify(AuthSessionMissingException()),
        ChangePasswordError.sessionExpiree,
      );
      expect(
        classify(const AuthApiException('x', statusCode: '429')),
        ChangePasswordError.tropDeTentatives,
      );
      expect(classify(api('other')), ChangePasswordError.inconnue);
    });

    test('network vs server', () {
      expect(
        classify(AuthRetryableFetchException(message: 'reset')),
        ChangePasswordError.reseau,
      );
      expect(classify(TimeoutException('slow')), ChangePasswordError.reseau);
      expect(
        classify(AuthRetryableFetchException(message: 'x', statusCode: '503')),
        ChangePasswordError.inconnue,
      );
    });
  });

  group('AuthSession.changePassword', () {
    test('updateUser, then RPC, then profile reload', () async {
      var mustChange = true;
      final repo = FakeAuthRepository()
        ..next = () async => Profil(
          id: 'u1',
          role: UserRole.chauffeur,
          doitChangerMdp: mustChange,
        );
      final session = AuthSession(repo);
      addTearDown(session.dispose);
      repo.emit(AuthChangeEvent.signedIn);
      await pumpEventQueue();
      expect(session.mustChangePassword, isTrue);

      mustChange = false;
      await session.changePassword('abcdefg1');
      expect(repo.updatePasswordCalls, ['abcdefg1']);
      expect(repo.markPasswordChangedCalls, 1);
      expect(session.status, AuthStatus.signedIn);
      expect(session.mustChangePassword, isFalse);
    });

    test('RPC failed: retry with the same password skips updateUser', () async {
      final repo = FakeAuthRepository()
        ..markPasswordChangedError = ChangePasswordError.reseau;
      final session = AuthSession(repo);
      addTearDown(session.dispose);

      await expectLater(
        session.changePassword('abcdefg1'),
        throwsA(isA<ChangePasswordException>()),
      );
      repo.markPasswordChangedError = null;
      await session.changePassword('abcdefg1');
      expect(repo.updatePasswordCalls, ['abcdefg1']);
      expect(repo.markPasswordChangedCalls, 2);
    });
  });

  group('A8 redirect', () {
    test('redirectFor sends doit_changer_mdp to /changer-mdp first', () {
      for (final role in UserRole.values) {
        for (final location in [
          '/login',
          '/chargement',
          role.homePath,
          '/chauffeur/scanner',
        ]) {
          expect(
            redirectFor(
              AuthStatus.signedIn,
              role,
              location,
              mustChangePassword: true,
            ),
            '/changer-mdp',
            reason: '${role.name} on $location',
          );
        }
        expect(
          redirectFor(
            AuthStatus.signedIn,
            role,
            '/changer-mdp',
            mustChangePassword: true,
          ),
          isNull,
        );
        // Once changed, A8 is no longer reachable.
        expect(
          redirectFor(AuthStatus.signedIn, role, '/changer-mdp'),
          role.homePath,
        );
      }
      expect(redirectFor(AuthStatus.signedOut, null, '/changer-mdp'), '/login');
      expect(
        redirectFor(
          AuthStatus.signedIn,
          null,
          '/changer-mdp',
          mustChangePassword: true,
        ),
        '/erreur-profil',
      );
    });

    testWidgets('router: A8 before the role home, then the home after save', (
      tester,
    ) async {
      var mustChange = true;
      final repo = FakeAuthRepository()
        ..next = () async => Profil(
          id: 'u1',
          role: UserRole.voyageur,
          doitChangerMdp: mustChange,
        );
      final container = await _container(repo);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      repo.emit(AuthChangeEvent.signedIn);
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.byType(VoyageurHomeScreen), findsNothing);

      // Cannot be skipped by navigating to the home.
      router.go('/voyageur');
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/changer-mdp',
      );

      await tester.enterText(_fields.at(0), 'abcdefg1');
      await tester.enterText(_fields.at(1), 'abcdefg1');
      await tester.pump();
      mustChange = false;
      await tester.tap(find.text('Enregistrer et continuer'));
      await tester.pump(); // save → session loading (splash animates)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(repo.updatePasswordCalls, ['abcdefg1']);
      expect(repo.markPasswordChangedCalls, 1);
      expect(find.byType(VoyageurHomeScreen), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsNothing);
    });
  });

  testWidgets('LLLogo renders its 3 variants', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            LLLogo(variant: LLLogoVariant.onLight),
            LLLogo(variant: LLLogoVariant.onDark),
            LLLogo(variant: LLLogoVariant.onRed, size: 96),
            LLLogo(),
          ],
        ),
      ),
    );
    expect(find.byType(LLLogo), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Splash: brandRed background, name and tagline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: const SplashScreen(),
      ),
    );
    await tester.pump();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, LLColors.light.brandRed);
    expect(find.text('Louage Live'), findsOneWidget);
    expect(find.text('Le louage en direct'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  group('small phone, FR/AR, light/dark: no overflow', () {
    for (final lang in ['fr', 'ar']) {
      for (final dark in [false, true]) {
        for (final (name, screen) in <(String, Widget)>[
          ('login', const LoginScreen()),
          ('signup', const SignUpScreen()),
          ('A8', const ChangePasswordScreen()),
          ('profile error', const ProfileErrorScreen()),
          ('splash', const SplashScreen()),
        ]) {
          testWidgets('$name ($lang, dark: $dark)', (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final container = await _container(
              FakeAuthRepository(),
              online: Stream.value(false), // offline banner = tallest layout
            );
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: dark ? AppTheme.dark() : AppTheme.light(),
                  locale: Locale(lang),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: appLocalizationsDelegates,
                  home: screen,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
