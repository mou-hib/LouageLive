/// Configuration injected at build time with
/// `flutter run --dart-define-from-file=config/env.json`.
///
/// Only the public (anon / publishable) key belongs here.
/// The service_role / secret key must NEVER be used in the app.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// False when the values are missing or still the placeholders
  /// from `config/env.example.json`.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR-PROJECT') &&
      !supabaseAnonKey.startsWith('YOUR-');
}
