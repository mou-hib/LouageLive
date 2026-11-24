import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main.dart` with the instance loaded before `runApp`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

const supportedLanguageCodes = ['fr', 'ar'];
const defaultLocale = Locale('fr');

/// Current app language. French by default, saved across launches.
class LocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'locale';

  @override
  Locale build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_prefsKey);
    return supportedLanguageCodes.contains(code)
        ? Locale(code!)
        : defaultLocale;
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, locale.languageCode);
  }

  /// Switches between French and Arabic.
  Future<void> toggle() =>
      setLocale(Locale(state.languageCode == 'fr' ? 'ar' : 'fr'));
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
