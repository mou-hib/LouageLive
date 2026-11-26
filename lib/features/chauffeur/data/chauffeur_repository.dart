import 'package:supabase_flutter/supabase_flutter.dart';

import 'file_error.dart';
import 'louage.dart';
import 'passage.dart';
import 'station.dart';

/// Chauffeur data: their louage, their current passage, and joining a
/// queue. Joining goes through the `rejoindre_file` RPC, never a direct
/// write (rule 1).
class ChauffeurRepository {
  ChauffeurRepository(this._client);

  final SupabaseClient _client;

  /// Same bound as auth requests: a dead 3G link ends on an error message.
  static const requestTimeout = Duration(seconds: 15);

  String get _uid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('No signed-in user');
    return uid;
  }

  /// The active louage of `auth.uid()`, or null if none is assigned.
  Future<Louage?> monLouage() => _guard(() async {
    final row = await _client
        .from('louages')
        .select('id, immatriculation, capacite')
        .eq('chauffeur_id', _uid)
        .eq('actif', true)
        .maybeSingle();
    return row == null ? null : Louage.fromRow(row);
  });

  /// The passage of my active louage that is still in a queue
  /// (EN_ATTENTE / EN_REMPLISSAGE / COMPLET), or null.
  Future<Passage?> monPassageActif() => _guard(() async {
    final row = await _client
        .from('passages')
        .select(
          'id, etat, places_occupees, capacite, '
          'lignes(ville_arrivee, stations(nom)), '
          'louages!inner(chauffeur_id, actif)',
        )
        .eq('louages.chauffeur_id', _uid)
        .eq('louages.actif', true)
        .inFilter('etat', [for (final e in EtatPassage.actifs) e.value])
        .maybeSingle();
    return row == null ? null : Passage.fromRow(row);
  });

  /// The station whose QR code is [codeQr], with its active lines sorted by
  /// arrival city. Throws [FileError.qrStationInvalide] for an unknown code.
  Future<Station> lignesDeStation(String codeQr) => _guard(() async {
    final row = await _client
        .from('stations')
        .select('id, nom, ville, lignes(id, ville_arrivee, tarif)')
        .eq('code_qr', codeQr.trim())
        .eq('actif', true)
        .eq('lignes.actif', true)
        .order('ville_arrivee', referencedTable: 'lignes', ascending: true)
        .maybeSingle();
    if (row == null) {
      throw const FileAttenteException(FileError.qrStationInvalide);
    }
    return Station.fromRow(row);
  });

  /// Puts my louage at the end of [ligneId]'s queue (`rejoindre_file` RPC).
  Future<void> rejoindreFile(String codeQr, String ligneId) => _guard(() async {
    await _client.rpc<void>(
      'rejoindre_file',
      params: {'p_code_station': codeQr.trim(), 'p_ligne_id': ligneId},
    );
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(requestTimeout);
    } catch (e, st) {
      Error.throwWithStackTrace(
        FileAttenteException(classifyFileError(e, st), e),
        st,
      );
    }
  }
}
