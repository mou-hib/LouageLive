import 'package:flutter/foundation.dart';

/// A line leaving the scanned station (departure city = station city).
@immutable
class Ligne {
  const Ligne({
    required this.id,
    required this.villeArrivee,
    required this.tarif,
  });

  /// From a `lignes` row (`id, ville_arrivee, tarif`). `tarif` is in TND.
  factory Ligne.fromRow(Map<String, dynamic> row) => switch (row) {
    {
      'id': final String id,
      'ville_arrivee': final String villeArrivee,
      'tarif': final num tarif,
    } =>
      Ligne(id: id, villeArrivee: villeArrivee, tarif: tarif.toDouble()),
    _ => throw FormatException('Malformed lignes row: $row'),
  };

  final String id;
  final String villeArrivee;

  /// Official fare in TND (3 decimals = millimes).
  final double tarif;
}

/// A station found from its QR code, with its active lines.
@immutable
class Station {
  const Station({
    required this.id,
    required this.nom,
    required this.ville,
    required this.lignes,
  });

  /// From a `stations` row with embedded `lignes`.
  factory Station.fromRow(Map<String, dynamic> row) => switch (row) {
    {
      'id': final String id,
      'nom': final String nom,
      'ville': final String ville,
      'lignes': final List<dynamic> lignes,
    } =>
      Station(
        id: id,
        nom: nom,
        ville: ville,
        lignes: [
          for (final l in lignes) Ligne.fromRow(l as Map<String, dynamic>),
        ],
      ),
    _ => throw FormatException('Malformed stations row: $row'),
  };

  final String id;
  final String nom;
  final String ville;

  /// Active lines, sorted by arrival city.
  final List<Ligne> lignes;
}
