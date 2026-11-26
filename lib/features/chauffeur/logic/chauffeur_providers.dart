import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/chauffeur_repository.dart';
import '../data/louage.dart';
import '../data/passage.dart';

final chauffeurRepositoryProvider = Provider<ChauffeurRepository>(
  (ref) => ChauffeurRepository(ref.watch(supabaseClientProvider)),
);

/// What C1 shows: my louage (null = none assigned) and my current passage.
@immutable
class ChauffeurAccueil {
  const ChauffeurAccueil({required this.louage, required this.passage});

  final Louage? louage;
  final Passage? passage;
}

/// Auto-disposed so the next chauffeur signing in on the same phone never
/// sees the previous one's data. Invalidate it to reload C1.
///
/// No automatic retry: C1 has its own "Réessayer" button.
final chauffeurAccueilProvider = FutureProvider.autoDispose<ChauffeurAccueil>(
  retry: (_, _) => null,
  (ref) async {
    final repository = ref.watch(chauffeurRepositoryProvider);
    final louage = await repository.monLouage();
    if (louage == null) {
      return const ChauffeurAccueil(louage: null, passage: null);
    }
    return ChauffeurAccueil(
      louage: louage,
      passage: await repository.monPassageActif(),
    );
  },
);
