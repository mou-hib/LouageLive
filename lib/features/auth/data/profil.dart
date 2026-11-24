import 'package:flutter/foundation.dart';

import 'profil_exception.dart';
import 'user_role.dart';

/// The part of `public.profils` the app needs to route the current user.
@immutable
class Profil {
  const Profil({
    required this.id,
    required this.role,
    required this.doitChangerMdp,
  });

  /// Builds a [Profil] from a `profils` row (`id, role, doit_changer_mdp`).
  ///
  /// Throws [ProfilInvalide] if a column is missing or has the wrong type.
  factory Profil.fromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final role = row['role'];
    final doitChangerMdp = row['doit_changer_mdp'];
    if (id is! String || role is! String? || doitChangerMdp is! bool) {
      throw ProfilInvalide('Malformed profils row: $row');
    }
    return Profil(
      id: id,
      role: UserRole.fromValue(role),
      doitChangerMdp: doitChangerMdp,
    );
  }

  final String id;
  final UserRole role;
  final bool doitChangerMdp;

  @override
  bool operator ==(Object other) =>
      other is Profil &&
      other.id == id &&
      other.role == role &&
      other.doitChangerMdp == doitChangerMdp;

  @override
  int get hashCode => Object.hash(id, role, doitChangerMdp);

  @override
  String toString() =>
      'Profil(id: $id, role: ${role.name}, doitChangerMdp: $doitChangerMdp)';
}
