import 'package:flutter/foundation.dart';

/// The physical vehicle driven by the current chauffeur.
@immutable
class Louage {
  const Louage({
    required this.id,
    required this.immatriculation,
    required this.capacite,
  });

  /// From a `louages` row (`id, immatriculation, capacite`).
  factory Louage.fromRow(Map<String, dynamic> row) => switch (row) {
    {
      'id': final String id,
      'immatriculation': final String immatriculation,
      'capacite': final int capacite,
    } =>
      Louage(id: id, immatriculation: immatriculation, capacite: capacite),
    _ => throw FormatException('Malformed louages row: $row'),
  };

  final String id;
  final String immatriculation;
  final int capacite;

  @override
  bool operator ==(Object other) =>
      other is Louage &&
      other.id == id &&
      other.immatriculation == immatriculation &&
      other.capacite == capacite;

  @override
  int get hashCode => Object.hash(id, immatriculation, capacite);
}
