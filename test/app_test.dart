import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louage_live/core/l10n/app_localizations_delegates.dart';
import 'package:louage_live/core/l10n/locale_provider.dart';
import 'package:louage_live/core/router/app_router.dart';
import 'package:louage_live/features/auth/data/user_role.dart';
import 'package:louage_live/features/auth/logic/auth_providers.dart';
import 'package:louage_live/features/auth/presentation/login_screen.dart';
import 'package:louage_live/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(redirectFor(AuthStatus.signedOut, null, '/login'), isNull);
    });

    test('loading goes to splash', () {
      expect(redirectFor(AuthStatus.loading, null, '/login'), '/chargement');
    });

    test('signed in goes to the home of the role only', () {
      for (final role in UserRole.values) {
        expect(redirectFor(AuthStatus.signedIn, role, '/login'), role.homePath);
        expect(redirectFor(AuthStatus.signedIn, role, role.homePath), isNull);
      }
      expect(
        redirectFor(AuthStatus.signedIn, UserRole.voyageur, '/admin'),
        '/voyageur',
      );
    });

    test('unknown role value falls back to voyageur', () {
      expect(UserRole.fromValue('hacker'), UserRole.voyageur);
      expect(UserRole.fromValue(null), UserRole.voyageur);
    });
  });
}
