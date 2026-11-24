/// Application roles (BNF-6). Values match `profiles.role` in Supabase.
enum UserRole {
  voyageur,
  chauffeur,
  agent,
  admin;

  /// Home route of the role, e.g. `/chauffeur`.
  String get homePath => '/$name';

  /// Unknown or null values fall back to [UserRole.voyageur]
  /// (least privileged role).
  static UserRole fromValue(String? value) => UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.voyageur,
  );
}
