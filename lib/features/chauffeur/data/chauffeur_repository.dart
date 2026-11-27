import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'file_error.dart';
import 'louage.dart';
import 'passage.dart';
import 'station.dart';

/// What the Realtime subscription of [ChauffeurRepository.ecouter] reports.
enum FileSignal {
  /// The channel is (re)subscribed: refetch, events may have been missed.
  connecte,

  /// A row of my passage, my line's queue or my reservations changed.
  changement,

  /// The socket answered a heartbeat: the connection is alive.
  vivant,

  /// The channel or the socket failed; Supabase reconnects by itself.
  deconnecte,
}

/// Chauffeur data: their louage, their current passage, and joining a
/// queue. Every write goes through an RPC (`rejoindre_file`,
/// `quitter_file`, `modifier_places`), never a direct write (rule 1).
class ChauffeurRepository {
  ChauffeurRepository(this._client);

  final SupabaseClient _client;

  /// Makes every channel topic unique: a new subscription never collides
  /// with the one being removed.
  static int _channelSeq = 0;

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
        .select('${Passage.columns}, louages!inner(chauffeur_id, actif)')
        .eq('louages.chauffeur_id', _uid)
        .eq('louages.actif', true)
        .inFilter('etat', [for (final e in EtatPassage.actifs) e.value])
        .maybeSingle();
    return row == null ? null : Passage.fromRow(row);
  });

  /// First name of `auth.uid()` (greeting of C1), or null if not filled in.
  Future<String?> monPrenom() => _guard(() async {
    final row = await _client
        .from('profils')
        .select('prenom')
        .eq('id', _uid)
        .maybeSingle();
    return switch (row?['prenom']) {
      final String p when p.trim().isNotEmpty => p.trim(),
      _ => null,
    };
  });

  /// The latest passage of [louageId], whatever its state (an active one,
  /// or the PARTI / RETIRE that ended the last stay), or null if none.
  Future<Passage?> dernierPassage(String louageId) => _guard(() async {
    final row = await _client
        .from('passages')
        .select(Passage.columns)
        .eq('louage_id', louageId)
        .order('heure_entree', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Passage.fromRow(row);
  });

  /// The queue of [ligneId], head first.
  Future<List<FileEntree>> fileDeLigne(String ligneId) => _guard(() async {
    final rows = await _client
        .from('file_attente')
        .select(FileEntree.columns)
        .eq('ligne_id', ligneId)
        .order('rang', ascending: true);
    return [for (final r in rows) FileEntree.fromRow(r)];
  });

  /// Expiry times of the reservations of [passageId] not scanned yet,
  /// soonest first.
  Future<List<DateTime>> reservationsAScanner(String passageId) =>
      _guard(() async {
        final rows = await _client
            .from('reservations')
            .select('date_expiration')
            .eq('passage_id', passageId)
            .eq('etat', 'EN_ATTENTE')
            .order('date_expiration', ascending: true);
        return [
          for (final r in rows)
            if (r['date_expiration'] case final String t) ?DateTime.tryParse(t),
        ];
      });

  /// +1 / −1 passenger (`modifier_places` RPC). Returns the seats occupied
  /// after the change, as stored by the database.
  Future<int> modifierPlaces(String passageId, int delta) => _guard(() async {
    final result = await _client.rpc<dynamic>(
      'modifier_places',
      params: {'p_passage_id': passageId, 'p_delta': delta},
    );
    final row = result is List ? result.firstOrNull : result;
    return switch (row) {
      {'places_occupees': final int places} => places,
      _ => throw FormatException('Malformed modifier_places result: $row'),
    };
  });

  /// Leaves the queue (`quitter_file` RPC): only my own passage, only while
  /// EN_ATTENTE (QUITTER_IMPOSSIBLE_EN_TETE at the head).
  Future<void> quitterFile(String passageId) => _guard(() async {
    await _client.rpc<dynamic>(
      'quitter_file',
      params: {'p_passage_id': passageId},
    );
  });

  /// Realtime changes that matter to the chauffeur's home:
  /// - passages of [louageId] (an agent adds or removes my louage),
  /// - passages of [ligneId] (my rank moves; `file_attente` is a view, so
  ///   the subscription is on its source table),
  /// - reservations of [passageId] (seats to scan).
  ///
  /// RLS filters the events like the selects. The channel is removed when
  /// the stream is cancelled.
  Stream<FileSignal> ecouter({
    required String louageId,
    String? ligneId,
    String? passageId,
  }) {
    RealtimeChannel? channel;
    StreamSubscription<RealtimeHeartbeatStatus>? heartbeat;
    late final StreamController<FileSignal> out;
    void emit(FileSignal s) {
      if (!out.isClosed) out.add(s);
    }

    void changed(PostgresChangePayload _) => emit(FileSignal.changement);
    PostgresChangeFilter eq(String column, String value) =>
        PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: value,
        );

    out = StreamController<FileSignal>(
      onListen: () {
        final c = _client.channel('chauffeur:$louageId:${_channelSeq++}')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'passages',
            filter: eq('louage_id', louageId),
            callback: changed,
          );
        if (ligneId != null) {
          c.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'passages',
            filter: eq('ligne_id', ligneId),
            callback: changed,
          );
        }
        if (passageId != null) {
          c.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'reservations',
            filter: eq('passage_id', passageId),
            callback: changed,
          );
        }
        c.subscribe(
          (status, _) => emit(
            status == RealtimeSubscribeStatus.subscribed
                ? FileSignal.connecte
                : FileSignal.deconnecte,
          ),
        );
        channel = c;
        heartbeat = _client.realtime.onHeartbeat.listen(
          (s) => switch (s) {
            RealtimeHeartbeatStatus.ok => emit(FileSignal.vivant),
            RealtimeHeartbeatStatus.error ||
            RealtimeHeartbeatStatus.timeout => emit(FileSignal.deconnecte),
            RealtimeHeartbeatStatus.sent => null,
          },
          onError: (Object _) {},
        );
      },
      onCancel: () async {
        await heartbeat?.cancel();
        if (channel case final c?) await _client.removeChannel(c);
        await out.close();
      },
    );
    return out.stream;
  }

  /// The station whose QR code is [codeQr], with its active lines sorted by
  /// arrival city and how many louages wait on each.
  /// Throws [FileError.qrStationInvalide] for an unknown code.
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
    final station = Station.fromRow(row);
    if (station.lignes.isEmpty) return station;
    final enFile = await _client
        .from('file_attente')
        .select('ligne_id')
        .inFilter('ligne_id', [for (final l in station.lignes) l.id]);
    final counts = <String, int>{};
    for (final r in enFile) {
      if (r['ligne_id'] case final String id) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return station.withLignes([
      for (final l in station.lignes) l.withLouagesEnFile(counts[l.id] ?? 0),
    ]);
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
