import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_banner.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/ll_skeleton.dart';
import '../../../core/widgets/plate_text.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../data/file_error.dart';
import '../data/passage.dart';
import '../logic/chauffeur_providers.dart';
import 'chauffeur_home_screen.dart';
import 'file_error_message.dart';
import 'widgets/chauffeur_scaffold.dart';

/// C3 — my louage waits in a queue (EN_ATTENTE): my rank, the queue, and
/// leaving it.
class FileAttenteView extends ConsumerWidget {
  const FileAttenteView({super.key, required this.accueil});

  final ChauffeurAccueil accueil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final passage = accueil.passage!;
    final plate = accueil.louage!.immatriculation;
    final online = ref.isOnline;
    return ChauffeurScaffold(
      title: ligneDe(l10n, passage),
      subtitle: passage.stationNom,
      board: true,
      live: accueil,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(chauffeurAccueilProvider.notifier).rafraichir(),
        child: ListView(
          padding: const EdgeInsetsDirectional.all(LLSpace.s16),
          children: [
            _RangCard(
              rang: accueil.maPlace?.rang,
              devant: accueil.devant,
              plate: plate,
            ),
            const SizedBox(height: LLSpace.s24),
            Text(l10n.queueTitle, style: LLText.title3.copyWith(color: c.ink)),
            const SizedBox(height: LLSpace.s12),
            for (final e in accueil.file) ...[
              QueueRow(entree: e, mine: e.passageId == passage.id),
              const SizedBox(height: LLSpace.s8),
            ],
            const SizedBox(height: LLSpace.s16),
            InfoBox(
              icon: Icons.notifications_active_outlined,
              text: l10n.queueStayNear,
            ),
            const SizedBox(height: LLSpace.s24),
            LLButton(
              driver: true,
              variant: LLButtonVariant.outline,
              icon: Icons.logout,
              label: l10n.leaveQueue,
              onPressed: online
                  ? () => _confirmerSortie(context, passage.id, plate)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerSortie(
    BuildContext context,
    String passageId,
    String plate,
  ) async {
    final left = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _QuitterSheet(passageId: passageId, plate: plate),
    );
    if ((left ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).leftQueue)),
      );
    }
  }
}

/// "Quitter la file ?" — confirm calls `quitter_file`; the sheet pops `true`
/// once done (the home switches to C1 on the refetch). A refusal (e.g. the
/// louage just reached the head) stays in the sheet as an error banner.
class _QuitterSheet extends ConsumerStatefulWidget {
  const _QuitterSheet({required this.passageId, required this.plate});

  final String passageId;
  final String plate;

  @override
  ConsumerState<_QuitterSheet> createState() => _QuitterSheetState();
}

class _QuitterSheetState extends ConsumerState<_QuitterSheet> {
  bool _busy = false;
  FileError? _error;

  Future<void> _quitter() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(chauffeurRepositoryProvider).quitterFile(widget.passageId);
      // Refetch now rather than wait for the Realtime event.
      await ref.read(chauffeurAccueilProvider.notifier).rafraichir();
      if (mounted) Navigator.of(context).pop(true);
    } on FileAttenteException catch (e) {
      if (mounted) setState(() => _error = e.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final online = ref.isOnline;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          LLSpace.s24,
          0,
          LLSpace.s24,
          LLSpace.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.leaveQueueConfirmTitle,
              style: LLText.title2.copyWith(color: c.ink),
            ),
            const SizedBox(height: LLSpace.s8),
            Text(
              l10n.leaveQueueConfirmBody(PlateText.isolate(widget.plate)),
              style: LLText.bodyLg.copyWith(color: c.inkMuted),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: LLSpace.s16),
              LLBanner(
                key: const ValueKey('c3-quitter-erreur'),
                kind: LLBannerKind.error,
                message: fileErrorMessage(l10n, error),
              ),
            ],
            const SizedBox(height: LLSpace.s24),
            LLButton(
              key: const ValueKey('c3-quitter-confirmer'),
              driver: true,
              variant: LLButtonVariant.destructive,
              label: l10n.leaveQueue,
              loading: _busy,
              onPressed: online ? _quitter : null,
            ),
            const SizedBox(height: LLSpace.s8),
            LLButton(
              driver: true,
              variant: LLButtonVariant.text,
              label: l10n.cancel,
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangCard extends StatelessWidget {
  const _RangCard({
    required this.rang,
    required this.devant,
    required this.plate,
  });

  /// Null until my row is in the loaded queue.
  final int? rang;
  final int devant;
  final String plate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(LLSpace.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LLText.overlineCase(context, l10n.queueYourPlace),
              style: LLText.overline.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: LLSpace.s8),
            if (rang case final rang?)
              Semantics(
                label: l10n.queueRankA11y(rang),
                child: ExcludeSemantics(
                  child: Text(
                    l10n.queueRankOrdinal(rang),
                    key: const ValueKey('c3-rang'),
                    textDirection: TextDirection.ltr,
                    style: LLText.boardRank.copyWith(color: c.ink),
                  ),
                ),
              )
            else
              const LLSkeleton(
                width: LLSize.qrIllustration,
                height: LLSize.stepperDriver,
              ),
            const SizedBox(height: LLSpace.s12),
            Text(
              l10n.louagesAhead(devant),
              style: LLText.title3.copyWith(color: c.ink),
            ),
            const SizedBox(height: LLSpace.s4),
            Text(
              l10n.yourLouage(PlateText.isolate(plate)),
              style: LLText.bodyLg.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One louage of the queue. The head gets a brandRed rank badge; my row a
/// 4px ink edge on the start side.
class QueueRow extends StatelessWidget {
  const QueueRow({super.key, required this.entree, required this.mine});

  final FileEntree entree;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final head = entree.rang == 1;
    final radius = BorderRadius.circular(LLRadius.md);
    return Semantics(
      container: true,
      label: l10n.queueRankA11y(entree.rang),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: radius,
          border: Border.all(color: mine ? c.borderStrong : c.border),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mine)
                  Container(
                    key: const ValueKey('queue-row-mine'),
                    width: LLSize.highlightEdge,
                    color: c.ink,
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(LLSpace.s12),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: LLSize.rankBadge,
                            height: LLSize.rankBadge,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: head ? c.brandRed : c.neutralTint,
                              borderRadius: BorderRadius.circular(LLRadius.sm),
                            ),
                            child: Text(
                              '${entree.rang}',
                              textDirection: TextDirection.ltr,
                              style: LLText.title3.copyWith(
                                color: head ? LLColors.onBrandRed : c.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: LLSpace.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlateText(
                                entree.immatriculation,
                                style: LLText.title3.copyWith(color: c.ink),
                              ),
                              if (mine)
                                Text(
                                  l10n.queueYou,
                                  style: LLText.bodyLg.copyWith(
                                    color: c.inkMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: LLSpace.s8),
                        Flexible(
                          child: StatusChip.passage(
                            entree.etat.value,
                            occupied: entree.placesOccupees,
                            capacity: entree.capacite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
