/// Form checks for login and sign-up. Deliberately simple: Supabase Auth
/// remains the real validation.
library;

/// Supabase's default minimum password length.
const minPasswordLength = 6;

/// something@something.tld, no spaces.
final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// 8 digits, optionally prefixed by +216 (spaces, dots and dashes ignored).
final _tunisianPhonePattern = RegExp(r'^(\+216)?\d{8}$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

bool isValidTunisianPhone(String value) =>
    _tunisianPhonePattern.hasMatch(_compactPhone(value));

/// `98 123 456` or `+216 98.123.456` → `+21698123456`.
///
/// Only call on a value accepted by [isValidTunisianPhone].
String normalizeTunisianPhone(String value) {
  final compact = _compactPhone(value);
  return compact.startsWith('+216') ? compact : '+216$compact';
}

String _compactPhone(String value) => value.replaceAll(RegExp(r'[\s.\-]'), '');
