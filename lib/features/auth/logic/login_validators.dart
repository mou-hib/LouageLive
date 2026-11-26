/// Deliberately simple e-mail check (something@something.tld, no spaces).
/// Supabase Auth remains the real validation.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());
