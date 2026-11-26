import 'package:flutter/foundation.dart';

/// `etat_passage` in Supabase.
enum EtatPassage {
  enAttente('EN_ATTENTE'),
  enRemplissage('EN_REMPLISSAGE'),
  complet('COMPLET'),
  parti('PARTI'),
  retire('RETIRE');

  const EtatPassage(this.value);

  final String value;

  /// States of a louage still in a queue.
  static const actifs = [enAttente, enRemplissage, complet];

  static EtatPassage fromValue(Object? value) => values.firstWhere(
    (e) => e.value == value,
    orElse: () => throw FormatException('Unknown etat_passage: $value'),
  );
}

/// One stay of the chauffeur's louage in a line's queue (C1 summary; the
/// full queue view C3 comes with US-06).
@immutable
class Passage {
  const Passage({
    required this.id,
    required this.etat,
    required this.placesOccupees,
    required this.capacite,
    required this.stationNom,
    required this.villeArrivee,
  });

  /// From a `passages` row with embedded `lignes(ville_arrivee, stations(nom))`.
  factory Passage.fromRow(Map<String, dynamic> row) => switch (row) {
    {
      'id': final String id,
      'etat': final String etat,
      'places_occupees': final int placesOccupees,
      'capacite': final int capacite,
      'lignes': {
        'ville_arrivee': final String villeArrivee,
        'stations': {'nom': final String stationNom},
      },
    } =>
      Passage(
        id: id,
        etat: EtatPassage.fromValue(etat),
        placesOccupees: placesOccupees,
        capacite: capacite,
        stationNom: stationNom,
        villeArrivee: villeArrivee,
      ),
    _ => throw FormatException('Malformed passages row: $row'),
  };

  final String id;
  final EtatPassage etat;
  final int placesOccupees;
  final int capacite;
  final String stationNom;
  final String villeArrivee;
}
