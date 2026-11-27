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

/// Fixed prefix of the phone field (B1).
const tunisianDialCode = '+216';

/// A8 minimum length. Stricter than the Supabase Auth minimum (which only
/// has to be <= this value), so a password that passes the checklist is
/// never refused as too short by Supabase.
const minNewPasswordLength = 8;

/// State of the A8 checklist for a new password and its confirmation.
typedef NewPasswordRules = ({bool longEnough, bool hasDigit, bool matches});

NewPasswordRules newPasswordRules(String password, String confirmation) => (
  longEnough: password.length >= minNewPasswordLength,
  hasDigit: password.contains(RegExp(r'[0-9]')),
  matches: password.isNotEmpty && password == confirmation,
);

extension NewPasswordRulesX on NewPasswordRules {
  bool get allPass => longEnough && hasDigit && matches;
}
