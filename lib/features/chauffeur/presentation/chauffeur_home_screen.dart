import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/plate_text.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/status_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/louage.dart';
import '../data/passage.dart';
import '../logic/chauffeur_providers.dart';
import 'c3_file_attente_view.dart';
import 'c4_remplissage_view.dart';
import 'c8_retire_view.dart';
import 'complet_placeholder_view.dart';
import 'file_error_message.dart';
import 'widgets/centered_message.dart';
import 'widgets/chauffeur_scaffold.dart';
import 'widgets/qr_frame_illustration.dart';

/// Chauffeur home: ONE screen chosen by the live state of my louage
/// ([ecranPour]), cross-faded in 300 ms.
class ChauffeurHomeScreen extends ConsumerWidget {
  const ChauffeurHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accueil = ref.watch(chauffeurAccueilProvider);
    final (ChauffeurEcran? ecran, Widget child) = switch (accueil) {
      AsyncData(:final value) => (
        ecranPour(value),
        _ecranWidget(ecranPour(value), value),
      ),
      AsyncError(:final error) => (
        null,
        ChauffeurScaffold(
          key: const ValueKey('chauffeur-erreur'),
          title: l10n.chauffeurHomeTitle,
          accountActions: true,
          body: CenteredMessage(
            icon: Icons.error_outline,
            tone: StatusTone.error,
            text: fileErrorMessage(l10n, fileErrorOf(error)),
            action: LLButton(
              driver: true,
              icon: Icons.refresh,
              label: l10n.retry,
              onPressed: () => ref.invalidate(chauffeurAccueilProvider),
            ),
          ),
        ),
      ),
      _ => (
        null,
        ChauffeurScaffold(
          key: const ValueKey('chauffeur-chargement'),
          title: l10n.chauffeurHomeTitle,
          accountActions: true,
          body: const Center(child: CircularProgressIndicator()),
        ),
      ),
    };
    return AnimatedSwitcher(
      duration: LLMotion.screen(context),
      switchInCurve: LLMotion.decel,
      switchOutCurve: LLMotion.accel,
      child: KeyedSubtree(key: ValueKey(ecran ?? child.key), child: child),
    );
  }

  Widget _ecranWidget(ChauffeurEcran ecran, ChauffeurAccueil a) =>
      switch (ecran) {
        ChauffeurEcran.aucunLouage => const _AucunLouage(),
        ChauffeurEcran.horsFile => _HorsFile(accueil: a),
        ChauffeurEcran.enAttente => FileAttenteView(accueil: a),
        ChauffeurEcran.remplissage => RemplissageView(accueil: a),
        ChauffeurEcran.complet => CompletPlaceholderView(accueil: a),
        ChauffeurEcran.retire => RetireView(accueil: a),
      };
}

/// Opens C2; the home refreshes when it closes (the Realtime event usually
/// got there first).
Future<void> ouvrirScanner(BuildContext context, WidgetRef ref) async {
  final joined = await context.push<bool>(AppRoutes.chauffeurScanner);
  if (!context.mounted) return;
  await ref.read(chauffeurAccueilProvider.notifier).rafraichir();
  if ((joined ?? false) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).joinedQueue)),
    );
  }
}

/// "Tunis → Sousse" (mirrored arrow in Arabic).
String ligneDe(AppLocalizations l10n, Passage p) =>
    l10n.ligneLabel(p.stationVille, p.villeArrivee);

class _AucunLouage extends StatelessWidget {
  const _AucunLouage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ChauffeurScaffold(
      title: l10n.chauffeurHomeTitle,
      accountActions: true,
      body: CenteredMessage(
        icon: Icons.no_transfer_outlined,
        text: l10n.chauffeurNoLouage,
      ),
    );
  }
}

/// C1 — my louage is in no queue: greeting, my louage, join a queue.
class _HorsFile extends ConsumerWidget {
  const _HorsFile({required this.accueil});

  final ChauffeurAccueil accueil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final online = ref.isOnline;
    final louage = accueil.louage!;
    return ChauffeurScaffold(
      title: l10n.chauffeurHomeTitle,
      accountActions: true,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(chauffeurAccueilProvider.notifier).rafraichir(),
        // A ListView so pull-to-refresh works even when the content is short.
        child: ListView(
          padding: const EdgeInsetsDirectional.all(LLSpace.s16),
          children: [
            Text(switch (accueil.prenom) {
              final p? => l10n.chauffeurGreeting(p),
              null => l10n.chauffeurGreetingNoName,
            }, style: LLText.title1.copyWith(color: c.ink)),
            const SizedBox(height: LLSpace.s16),
            _MonLouageCard(louage: louage),
            const SizedBox(height: LLSpace.s32),
            const Center(child: QrFrameIllustration()),
            const SizedBox(height: LLSpace.s24),
            Text(
              l10n.arrivedAtStation,
              textAlign: TextAlign.center,
              style: LLText.title2.copyWith(color: c.ink),
            ),
            const SizedBox(height: LLSpace.s8),
            Text(
              l10n.arrivedAtStationHint,
              textAlign: TextAlign.center,
              style: LLText.bodyLg.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: LLSpace.s24),
            LLButton(
              driver: true,
              icon: Icons.qr_code_scanner,
              label: l10n.joinTheQueue,
              onPressed: online ? () => ouvrirScanner(context, ref) : null,
            ),
            const SizedBox(height: LLSpace.s8),
            LLButton(
              driver: true,
              variant: LLButtonVariant.text,
              label: l10n.myDepartures,
              onPressed: () => context.push(AppRoutes.chauffeurDeparts),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonLouageCard extends StatelessWidget {
  const _MonLouageCard({required this.louage});

  final Louage louage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(LLSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LLText.overlineCase(context, l10n.myLouage),
              style: LLText.overline.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: LLSpace.s4),
            PlateText(
              louage.immatriculation,
              style: LLText.title1.copyWith(color: c.ink),
            ),
            const SizedBox(height: LLSpace.s12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.louagePlaces(louage.capacite),
                    style: LLText.bodyLg.copyWith(color: c.ink),
                  ),
                ),
                const StatusChip(state: ChipState.horsFile),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
