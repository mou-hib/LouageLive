import 'profil_exception.dart';

/// Application roles (BNF-6). Values match the `role_utilisateur` enum
/// used by `public.profils.role` in Supabase.
enum UserRole {
  voyageur,
  chauffeur,
  agent,
  admin;

  /// Home route of the role, e.g. `/chauffeur`.
  String get homePath => '/$name';

  /// Parses a `profils.role` value.
  ///
  /// Throws [ProfilInvalide] for null or unknown values: there is no
  /// default role.
  static UserRole fromValue(String? value) {
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    throw ProfilInvalide('Unknown role: $value');
  }
}
