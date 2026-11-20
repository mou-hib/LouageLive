import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/l10n/locale_provider.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final overrides = [sharedPreferencesProvider.overrideWithValue(prefs)];

  if (!Env.isConfigured) {
    runApp(ProviderScope(overrides: overrides, child: const ConfigErrorApp()));
    return;
  }

  await initSupabase();
  runApp(ProviderScope(overrides: overrides, child: const LouageLiveApp()));
}
