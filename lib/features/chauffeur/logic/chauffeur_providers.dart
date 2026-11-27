import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/notifications/head_of_queue_alert.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../l10n/app_localizations.dart';
import '../data/chauffeur_repository.dart';
import '../data/file_error.dart';
import '../data/louage.dart';
import '../data/passage.dart';

final chauffeurRepositoryProvider = Provider<ChauffeurRepository>(
  (ref) => ChauffeurRepository(ref.watch(supabaseClientProvider)),
);

/// The LiveBadge turns stale when nothing (event, heartbeat, fetch) came
/// for this long.
const liveStaleAfter = Duration(seconds: 30);

/// C8 is shown for a removal younger than this; an older one is history
/// and the chauffeur lands on C1.
const retraitVisiblePendant = Duration(hours: 6);

/// Everything the chauffeur home shows, refreshed live.
@immutable
class ChauffeurAccueil {
  const ChauffeurAccueil({
    required this.louage,
    required this.passage,
    this.prenom,
    this.file = const [],
    this.reservationsAScanner = const [],
    this.retraitVuId,
    required this.chargeA,
    this.abonne = false,
    this.dernierSigne,
  });

  /// Null = no louage assigned to this chauffeur.
  final Louage? louage;

  /// The latest passage of my louage, whatever its state (null = never
  /// queued). Active, or the PARTI / RETIRE that ended the last stay.
  final Passage? passage;
  final String? prenom;

  /// My line's queue, head first (empty when I am in no queue).
  final List<FileEntree> file;

  /// Expiry of each reservation of my passage not scanned yet, soonest
  /// first (C4).
  final List<DateTime> reservationsAScanner;

  /// The RETIRE passage the chauffeur already acknowledged on C8.
  final String? retraitVuId;

  /// When the fetch that produced this snapshot started.
  final DateTime chargeA;

  /// The Realtime channel is subscribed.
  final bool abonne;

  /// Last sign of life: Realtime event, heartbeat, or successful fetch.
  final DateTime? dernierSigne;

  /// My row in [file].
  FileEntree? get maPlace {
    final id = passage?.id;
    for (final e in file) {
      if (e.passageId == id) return e;
    }
    return null;
  }

  /// Louages ahead of mine.
  int get devant => switch (maPlace) {
    final p? => p.rang - 1,
    null => 0,
  };

  /// Live = subscribed and heard from in the last [liveStaleAfter].
  bool enDirect(DateTime now) =>
      abonne &&
      dernierSigne != null &&
      now.difference(dernierSigne!) < liveStaleAfter;

  ChauffeurAccueil copyWith({
    bool? abonne,
    DateTime? dernierSigne,
    String? retraitVuId,
  }) => ChauffeurAccueil(
    louage: louage,
    passage: passage,
    prenom: prenom,
    file: file,
    reservationsAScanner: reservationsAScanner,
    retraitVuId: retraitVuId ?? this.retraitVuId,
    chargeA: chargeA,
    abonne: abonne ?? this.abonne,
    dernierSigne: dernierSigne ?? this.dernierSigne,
  );
}

/// The one screen the chauffeur home shows.
enum ChauffeurEcran {
  /// No louage assigned: contact the agent.
  aucunLouage,

  /// C1 — in no queue.
  horsFile,

  /// C3 — waiting in a queue.
  enAttente,

  /// C4 — head of the queue, filling.
  remplissage,

  /// C6 (Step 3e) — full, ready to leave.
  complet,

  /// C8 — just removed from the queue by an agent.
  retire,
}

/// State → screen.
ChauffeurEcran ecranPour(ChauffeurAccueil a, {DateTime? now}) {
  if (a.louage == null) return ChauffeurEcran.aucunLouage;
  final p = a.passage;
  if (p == null) return ChauffeurEcran.horsFile;
  return switch (p.etat) {
    EtatPassage.enAttente => ChauffeurEcran.enAttente,
    EtatPassage.enRemplissage => ChauffeurEcran.remplissage,
    EtatPassage.complet => ChauffeurEcran.complet,
    // Left by himself: straight back to C1 (C8 is for an agent's removal).
    EtatPassage.parti || EtatPassage.quitte => ChauffeurEcran.horsFile,
    EtatPassage.retire
        when p.id != a.retraitVuId &&
            (p.heureRetrait == null ||
                (now ?? DateTime.now()).difference(p.heureRetrait!) <
                    retraitVisiblePendant) =>
      ChauffeurEcran.retire,
    EtatPassage.retire => ChauffeurEcran.horsFile,
  };
}

/// Live chauffeur home: one fetch, then a Realtime subscription on my
/// passage, my line's passages (the source of `file_attente`) and my
/// reservations. Every event, every (re)subscription and every return of
/// the network refetches the snapshot; refetches are coalesced (one in
/// flight, at most one queued).
///
/// Auto-disposed so the next chauffeur signing in on the same phone never
/// sees the previous one's data. No automatic retry on the first load:
/// the screen has its own "Réessayer" button. Later failures keep the last
/// known snapshot (offline: last numbers stay visible).
class ChauffeurAccueilNotifier extends AsyncNotifier<ChauffeurAccueil> {
  static const _retraitVuKey = 'chauffeur.retrait_vu';

  StreamSubscription<FileSignal>? _sub;
  String? _subKey;
  bool _abonne = false;
  DateTime? _dernierSigne;
  Future<void>? _enCours;
  bool _encore = false;
  bool _alertePreparee = false;

  @override
  Future<ChauffeurAccueil> build() async {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      _sub = null;
      _subKey = null;
    });
    _abonne = false;
    _enCours = null;
    _encore = false;
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous?.value == false && next.value == true) {
        unawaited(rafraichir());
      }
    });
    final data = await _charger();
    _dernierSigne = DateTime.now();
    _ecouter(data);
    _apresChargement(null, data);
    return data.copyWith(abonne: _abonne, dernierSigne: _dernierSigne);
  }

  /// Refetches now (pull-to-refresh, after an RPC, Realtime event).
  Future<void> rafraichir() {
    if (_enCours case final running?) {
      _encore = true;
      return running;
    }
    final run = _boucle();
    _enCours = run;
    return run.whenComplete(() => _enCours = null);
  }

  /// C8 acknowledged: back to C1 (remembered across restarts).
  Future<void> marquerRetraitVu() async {
    final id = state.value?.passage?.id;
    if (id == null) return;
    if (state.value case final v?) {
      state = AsyncData(v.copyWith(retraitVuId: id));
    }
    await ref.read(sharedPreferencesProvider).setString(_retraitVuKey, id);
  }

  Future<void> _boucle() async {
    do {
      _encore = false;
      try {
        final data = await _charger();
        if (!ref.mounted) return;
        final avant = state.value;
        _dernierSigne = DateTime.now();
        _ecouter(data);
        state = AsyncData(
          data.copyWith(abonne: _abonne, dernierSigne: _dernierSigne),
        );
        _apresChargement(avant, data);
      } on FileAttenteException catch (e, st) {
        if (!ref.mounted) return;
        // Keep the last known snapshot; only a first load shows the error.
        if (state.value == null) state = AsyncError(e, st);
      }
    } while (_encore && ref.mounted);
  }

  Future<ChauffeurAccueil> _charger() async {
    final repo = ref.read(chauffeurRepositoryProvider);
    final debut = DateTime.now();
    final retraitVuId = ref
        .read(sharedPreferencesProvider)
        .getString(_retraitVuKey);
    final louage = await repo.monLouage();
    if (louage == null) {
      return ChauffeurAccueil(louage: null, passage: null, chargeA: debut);
    }
    final first = await Future.wait<Object?>([
      repo.monPrenom(),
      repo.dernierPassage(louage.id),
    ]);
    final prenom = first[0] as String?;
    final passage = first[1] as Passage?;
    var file = const <FileEntree>[];
    var reservations = const <DateTime>[];
    if (passage != null && EtatPassage.actifs.contains(passage.etat)) {
      final enTete = passage.etat != EtatPassage.enAttente;
      final second = await Future.wait<Object?>([
        repo.fileDeLigne(passage.ligneId),
        if (enTete) repo.reservationsAScanner(passage.id),
      ]);
      file = second[0] as List<FileEntree>;
      if (enTete) reservations = second[1] as List<DateTime>;
    }
    return ChauffeurAccueil(
      louage: louage,
      passage: passage,
      prenom: prenom,
      file: file,
      reservationsAScanner: reservations,
      retraitVuId: retraitVuId,
      chargeA: debut,
    );
  }

  /// (Re)subscribes when what I must listen to changes (joined a line,
  /// reached the head, left the queue).
  void _ecouter(ChauffeurAccueil data) {
    final louage = data.louage;
    if (louage == null) {
      unawaited(_sub?.cancel());
      _sub = null;
      _subKey = null;
      return;
    }
    final p = data.passage;
    final actif = p != null && EtatPassage.actifs.contains(p.etat);
    final enTete = actif && p.etat != EtatPassage.enAttente;
    final ligneId = actif ? p.ligneId : null;
    final passageId = enTete ? p.id : null;
    final key = '${louage.id}|$ligneId|$passageId';
    if (key == _subKey) return;
    unawaited(_sub?.cancel());
    _subKey = key;
    _sub = ref
        .read(chauffeurRepositoryProvider)
        .ecouter(louageId: louage.id, ligneId: ligneId, passageId: passageId)
        .listen(
          _onSignal,
          onError: (Object _) => _onSignal(FileSignal.deconnecte),
        );
  }

  void _onSignal(FileSignal signal) {
    if (!ref.mounted) return;
    switch (signal) {
      case FileSignal.connecte:
        _abonne = true;
        _dernierSigne = DateTime.now();
        _publierLive();
        unawaited(rafraichir()); // events may have been missed meanwhile
      case FileSignal.changement:
        _dernierSigne = DateTime.now();
        unawaited(rafraichir());
      case FileSignal.vivant:
        if (!_abonne) return;
        _dernierSigne = DateTime.now();
        _publierLive();
      case FileSignal.deconnecte:
        _abonne = false;
        _publierLive();
    }
  }

  void _publierLive() {
    if (state.value case final v?) {
      state = AsyncData(
        v.copyWith(abonne: _abonne, dernierSigne: _dernierSigne),
      );
    }
  }

  void _apresChargement(ChauffeurAccueil? avant, ChauffeurAccueil apres) {
    final p = apres.passage;
    if (p == null) return;
    final alert = ref.read(headOfQueueAlertProvider);
    if (p.etat == EtatPassage.enAttente && !_alertePreparee) {
      _alertePreparee = true;
      unawaited(alert.prepare());
    }
    final q = avant?.passage;
    final devientTete =
        q != null &&
        q.id == p.id &&
        q.etat == EtatPassage.enAttente &&
        (p.etat == EtatPassage.enRemplissage || p.etat == EtatPassage.complet);
    if (devientTete) {
      final l10n = lookupAppLocalizations(ref.read(localeProvider));
      unawaited(
        alert.ring(
          title: l10n.headAlertTitle,
          body: l10n.headAlertBody(
            l10n.ligneLabel(p.stationVille, p.villeArrivee),
          ),
          channelName: l10n.headAlertChannel,
        ),
      );
    }
  }
}

final chauffeurAccueilProvider =
    AsyncNotifierProvider.autoDispose<
      ChauffeurAccueilNotifier,
      ChauffeurAccueil
    >(ChauffeurAccueilNotifier.new, retry: (_, _) => null);

/// The screen to show, derived from [chauffeurAccueilProvider].
final chauffeurEcranProvider = Provider.autoDispose<AsyncValue<ChauffeurEcran>>(
  (ref) => ref.watch(chauffeurAccueilProvider).whenData(ecranPour),
);

/// C4 seat counter state: [optimiste] is shown instead of the snapshot
/// while +1/−1 calls are in flight or until a fresher snapshot arrives.
@immutable
class PlacesState {
  const PlacesState({this.optimiste, this.erreur});

  final int? optimiste;

  /// Last RPC failure (shown in an LLBanner until dismissed or next tap).
  final FileError? erreur;
}

/// +1 / −1 on C4, optimistic: the count moves at once, the
/// `modifier_places` calls run one at a time in tap order. On a failure
/// the queued taps are dropped and the count rolls back to the last value
/// the database accepted.
class PlacesController extends Notifier<PlacesState> {
  final _file = <int>[];
  bool _enCours = false;
  int _confirme = 0;
  DateTime? _finLot;

  @override
  PlacesState build() {
    ref.listen(chauffeurAccueilProvider, (_, next) {
      final data = next.value;
      if (data == null || _enCours || state.optimiste == null) return;
      final fin = _finLot;
      // Only a snapshot fetched after the last call can replace it.
      if (fin == null || !data.chargeA.isBefore(fin)) {
        state = PlacesState(erreur: state.erreur);
      }
    });
    return const PlacesState();
  }

  /// Seats shown for [passage].
  int affiche(Passage passage) => state.optimiste ?? passage.placesOccupees;

  void modifier(int delta) {
    final p = ref.read(chauffeurAccueilProvider).value?.passage;
    if (p == null) return;
    final actuel = affiche(p);
    final cible = actuel + delta;
    if (cible < 0 || cible > p.capacite) return;
    if (!_enCours) _confirme = actuel;
    _file.add(delta);
    state = PlacesState(optimiste: cible);
    if (!_enCours) unawaited(_vider(p.id));
  }

  void effacerErreur() => state = PlacesState(optimiste: state.optimiste);

  Future<void> _vider(String passageId) async {
    _enCours = true;
    final repo = ref.read(chauffeurRepositoryProvider);
    try {
      while (_file.isNotEmpty) {
        try {
          final places = await repo.modifierPlaces(passageId, _file.first);
          if (!ref.mounted) return;
          _confirme = places;
          _file.removeAt(0);
        } on FileAttenteException catch (e) {
          if (!ref.mounted) return;
          _file.clear();
          state = PlacesState(optimiste: _confirme, erreur: e.error);
          return;
        }
      }
      state = PlacesState(optimiste: _confirme);
    } finally {
      _enCours = false;
      if (ref.mounted) {
        _finLot = DateTime.now();
        unawaited(ref.read(chauffeurAccueilProvider.notifier).rafraichir());
      }
    }
  }
}

final placesControllerProvider =
    NotifierProvider.autoDispose<PlacesController, PlacesState>(
      PlacesController.new,
    );
