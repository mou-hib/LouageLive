import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/l10n/locale_provider.dart';
import 'package:louage_live/features/auth/data/auth_repository.dart';
import 'package:louage_live/features/auth/data/sign_up_error.dart';
import 'package:louage_live/features/auth/logic/auth_providers.dart';
import 'package:louage_live/features/auth/logic/auth_validators.dart';
import 'package:louage_live/features/auth/presentation/signup_screen.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthApiException,
        AuthResponse,
        AuthRetryableFetchException,
        Session,
        User,
        UserIdentity;

import 'support/fake_auth_repository.dart';

User _user({List<UserIdentity>? identities}) => User(
  id: 'u1',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
  identities: identities,
);

const _identity = UserIdentity(
  id: 'u1',
  userId: 'u1',
  identityData: {},
  identityId: 'i1',
  provider: 'email',
  createdAt: '2026-01-01T00:00:00Z',
  lastSignInAt: '2026-01-01T00:00:00Z',
);

Future<FakeAuthRepository> _pumpSignUp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = FakeAuthRepository()..hasSession = false;
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
        home: const SignUpScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Fields in screen order: prénom, nom, téléphone, e-mail, mdp, confirmation.
Future<void> _fill(
  WidgetTester tester, {
  String prenom = 'Amel',
  String nom = 'Ben Salah',
  String telephone = '98 123 456',
  String email = 'amel@exemple.tn',
  String password = 'secret1',
  String? confirmation,
}) async {
  final fields = find.byType(TextFormField);
  final values = [
    prenom,
    nom,
    telephone,
    email,
    password,
    confirmation ?? password,
  ];
  for (var i = 0; i < values.length; i++) {
    await tester.enterText(fields.at(i), values[i]);
  }
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Créer mon compte');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('classifySignUpError', () {
    final st = StackTrace.current;
    SignUpError classify(Object e) => classifySignUpError(e, st);
    AuthApiException api(String code, [String status = '400']) =>
        AuthApiException('message ignoré', statusCode: status, code: code);

    test('user_already_exists → compteExistant', () {
      expect(classify(api('user_already_exists')), SignUpError.compteExistant);
    });

    test('email_exists → compteExistant', () {
      expect(classify(api('email_exists', '422')), SignUpError.compteExistant);
    });

    test('weak_password → motDePasseFaible', () {
      expect(
        classify(api('weak_password', '422')),
        SignUpError.motDePasseFaible,
      );
    });

    test('over_email_send_rate_limit → tropDeTentatives', () {
      expect(
        classify(api('over_email_send_rate_limit', '429')),
        SignUpError.tropDeTentatives,
      );
    });

    test('status 429 without a known code → tropDeTentatives', () {
      expect(
        classify(const AuthApiException('x', statusCode: '429')),
        SignUpError.tropDeTentatives,
      );
    });

    test('transport failures → reseau', () {
      for (final e in <Object>[
        const SocketException('down'),
        TimeoutException('slow'),
        http.ClientException('reset'),
        AuthRetryableFetchException(message: 'ClientException: reset'),
      ]) {
        expect(classify(e), SignUpError.reseau, reason: '$e');
      }
    });

    test('server error 5xx → inconnue, not reseau', () {
      expect(
        classify(AuthRetryableFetchException(message: 'x', statusCode: '500')),
        SignUpError.inconnue,
      );
    });

    test('other codes → inconnue', () {
      expect(classify(api('signup_disabled', '422')), SignUpError.inconnue);
    });

    test('StateError → inconnue', () {
      expect(classify(StateError('bug')), SignUpError.inconnue);
    });
  });

  group('signUpOutcomeOf', () {
    test('session → connecte', () {
      final session = Session(
        accessToken: 't',
        tokenType: 'bearer',
        user: _user(identities: [_identity]),
      );
      expect(
        signUpOutcomeOf(AuthResponse(session: session)),
        SignUpOutcome.connecte,
      );
    });

    test('no session, user with identity → confirmationEmail', () {
      expect(
        signUpOutcomeOf(AuthResponse(user: _user(identities: [_identity]))),
        SignUpOutcome.confirmationEmail,
      );
    });

    test('no session, user without identities → compte existant', () {
      expect(
        () => signUpOutcomeOf(AuthResponse(user: _user(identities: []))),
        throwsA(
          isA<SignUpException>().having(
            (e) => e.error,
            'error',
            SignUpError.compteExistant,
          ),
        ),
      );
    });
  });

  group('Tunisian phone', () {
    test('accepts 8 digits with optional +216, spaces and dots', () {
      for (final v in [
        '98123456',
        '98 123 456',
        '+21698123456',
        '+216 98 123 456',
        '71.234.567',
      ]) {
        expect(isValidTunisianPhone(v), isTrue, reason: v);
      }
    });

    test('rejects other formats', () {
      for (final v in [
        '',
        '9812345',
        '981234567',
        '216 98123456',
        '+33612345678',
        '98a23456',
        '+216',
      ]) {
        expect(isValidTunisianPhone(v), isFalse, reason: v);
      }
    });

    test('normalizes to +216 and 8 digits', () {
      expect(normalizeTunisianPhone('98 123 456'), '+21698123456');
      expect(normalizeTunisianPhone('+216 98-123-456'), '+21698123456');
    });
  });

  group('signup form', () {
    testWidgets('empty form: every field is required', (tester) async {
      final repo = await _pumpSignUp(tester);
      await _submit(tester);

      expect(find.text('Ce champ est obligatoire.'), findsNWidgets(6));
      expect(repo.signUpCalls, isEmpty);
    });

    testWidgets('format, length and matching errors', (tester) async {
      final repo = await _pumpSignUp(tester);
      await _fill(
        tester,
        telephone: '1234',
        email: 'pas-un-email',
        password: 'abc',
        confirmation: 'abd',
      );
      await _submit(tester);

      expect(
        find.text('Numéro invalide : 8 chiffres, +216 facultatif.'),
        findsOneWidget,
      );
      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
      expect(find.text('Au moins 6 caractères.'), findsOneWidget);
      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
      expect(repo.signUpCalls, isEmpty);
    });

    testWidgets('valid form sends trimmed data and shows "check e-mail"', (
      tester,
    ) async {
      final repo = await _pumpSignUp(tester);
      await _fill(tester, prenom: ' Amel ', email: ' amel@exemple.tn ');
      await _submit(tester);

      expect(repo.signUpCalls, hasLength(1));
      final call = repo.signUpCalls.single;
      expect(call.prenom, 'Amel');
      expect(call.nom, 'Ben Salah');
      expect(call.telephone, '+21698123456');
      expect(call.email, 'amel@exemple.tn');
      expect(call.password, 'secret1');

      expect(find.text('Vérifiez votre e-mail'), findsOneWidget);
      expect(find.text('amel@exemple.tn'), findsOneWidget);
      expect(find.text('Retour à la connexion'), findsOneWidget);
    });

    testWidgets('mapped error is shown under the form', (tester) async {
      final repo = await _pumpSignUp(tester);
      repo.signUpError = SignUpError.compteExistant;
      await _fill(tester);
      await _submit(tester);

      expect(
        find.text('Un compte existe déjà avec cet e-mail.'),
        findsOneWidget,
      );
      expect(find.text('Vérifiez votre e-mail'), findsNothing);
    });

    testWidgets('eye toggles show and hide the password', (tester) async {
      await _pumpSignUp(tester);
      EditableText field(int i) => tester.widget<EditableText>(
        find.descendant(
          of: find.byType(TextFormField).at(i),
          matching: find.byType(EditableText),
        ),
      );
      expect(field(4).obscureText, isTrue);

      final eye = find.byTooltip('Afficher le mot de passe').first;
      await tester.ensureVisible(eye);
      await tester.tap(eye);
      await tester.pump();
      expect(field(4).obscureText, isFalse);
      expect(field(5).obscureText, isTrue);
    });
  });
}
