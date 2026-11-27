import 'package:flutter/foundation.dart';

/// `etat_passage` in Supabase.
enum EtatPassage {
  enAttente('EN_ATTENTE'),
  enRemplissage('EN_REMPLISSAGE'),
  complet('COMPLET'),
  parti('PARTI'),
  retire('RETIRE'),

  /// The chauffeur left the queue himself (`quitter_file`).
  quitte('QUITTE');

  const EtatPassage(this.value);

  final String value;

  /// States of a louage still in a queue.
  static const actifs = [enAttente, enRemplissage, complet];

  static EtatPassage fromValue(Object? value) => values.firstWhere(
    (e) => e.value == value,
    orElse: () => throw FormatException('Unknown etat_passage: $value'),
  );
}

/// One stay of the chauffeur's louage in a line's queue.
@immutable
class Passage {
  const Passage({
    required this.id,
    required this.etat,
    required this.placesOccupees,
    required this.capacite,
    required this.ligneId,
    required this.stationNom,
    required this.stationVille,
    required this.villeArrivee,
    this.heureRetrait,
  });

  /// Columns [Passage.fromRow] reads.
  static const columns =
      'id, etat, places_occupees, capacite, ligne_id, heure_retrait, '
      'lignes(ville_arrivee, stations(nom, ville))';

  /// From a `passages` row with embedded
  /// `lignes(ville_arrivee, stations(nom, ville))`.
  factory Passage.fromRow(Map<String, dynamic> row) => switch (row) {
    {
      'id': final String id,
      'etat': final String etat,
      'places_occupees': final int placesOccupees,
      'capacite': final int capacite,
      'ligne_id': final String ligneId,
      'lignes': {
        'ville_arrivee': final String villeArrivee,
        'stations': {
          'nom': final String stationNom,
          'ville': final String ville,
        },
      },
    } =>
      Passage(
        id: id,
        etat: EtatPassage.fromValue(etat),
        placesOccupees: placesOccupees,
        capacite: capacite,
        ligneId: ligneId,
        stationNom: stationNom,
        stationVille: ville,
        villeArrivee: villeArrivee,
        heureRetrait: switch (row['heure_retrait']) {
          final String t => DateTime.tryParse(t),
          _ => null,
        },
      ),
    _ => throw FormatException('Malformed passages row: $row'),
  };

  final String id;
  final EtatPassage etat;
  final int placesOccupees;
  final int capacite;
  final String ligneId;
  final String stationNom;

  /// Departure city (the station's city).
  final String stationVille;
  final String villeArrivee;

  /// When the louage left the queue: taken out by an agent (RETIRE) or by
  /// the chauffeur (QUITTE).
  final DateTime? heureRetrait;

  int get placesLibres => capacite - placesOccupees;

  @override
  bool operator ==(Object other) =>
      other is Passage &&
      other.id == id &&
      other.etat == etat &&
      other.placesOccupees == placesOccupees &&
      other.capacite == capacite &&
      other.ligneId == ligneId &&
      other.stationNom == stationNom &&
      other.stationVille == stationVille &&
      other.villeArrivee == villeArrivee &&
      other.heureRetrait == heureRetrait;

  @override
  int get hashCode => Object.hash(
    id,
    etat,
    placesOccupees,
    capacite,
    ligneId,
    stationNom,
    stationVille,
    villeArrivee,
    heureRetrait,
  );
}

/// One louage of a line's queue (`file_attente` view, rank 1 = head).
@immutable
class FileEntree {
  const FileEntree({
    required this.passageId,
    required this.immatriculation,
    required this.etat,
    required this.placesOccupees,
    required this.capacite,
    required this.rang,
  });

  static const columns =
      'passage_id, immatriculation, etat, places_occupees, capacite, rang';

  factory FileEntree.fromRow(Map<String, dynamic> row) => switch (row) {
    {
      'passage_id': final String passageId,
      'immatriculation': final String immatriculation,
      'etat': final String etat,
      'places_occupees': final int placesOccupees,
      'capacite': final int capacite,
      'rang': final int rang,
    } =>
      FileEntree(
        passageId: passageId,
        immatriculation: immatriculation,
        etat: EtatPassage.fromValue(etat),
        placesOccupees: placesOccupees,
        capacite: capacite,
        rang: rang,
      ),
    _ => throw FormatException('Malformed file_attente row: $row'),
  };

  final String passageId;
  final String immatriculation;
  final EtatPassage etat;
  final int placesOccupees;
  final int capacite;
  final int rang;

  @override
  bool operator ==(Object other) =>
      other is FileEntree &&
      other.passageId == passageId &&
      other.immatriculation == immatriculation &&
      other.etat == etat &&
      other.placesOccupees == placesOccupees &&
      other.capacite == capacite &&
      other.rang == rang;

  @override
  int get hashCode => Object.hash(
    passageId,
    immatriculation,
    etat,
    placesOccupees,
    capacite,
    rang,
  );
}
