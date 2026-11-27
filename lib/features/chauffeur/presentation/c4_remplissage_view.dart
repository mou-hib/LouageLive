import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_banner.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/plate_text.dart';
import '../../../core/widgets/seat_indicator.dart';
import '../../../core/widgets/seat_stepper.dart';
import '../../../l10n/app_localizations.dart';
import '../logic/chauffeur_providers.dart';
import 'chauffeur_home_screen.dart';
import 'file_error_message.dart';
import 'widgets/chauffeur_scaffold.dart';

/// C4 — my louage is at the head and filling (EN_REMPLISSAGE): count the
/// passengers with +1 / −1 (`modifier_places`, optimistic).
class RemplissageView extends ConsumerWidget {
  const RemplissageView({super.key, required this.accueil});

  final ChauffeurAccueil accueil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final passage = accueil.passage!;
    final plate = accueil.louage!.immatriculation;
    final online = ref.isOnline;
    final places = ref.watch(placesControllerProvider);
    final controller = ref.read(placesControllerProvider.notifier);
    final occupees = places.optimiste ?? passage.placesOccupees;
    final libres = passage.capacite - occupees;
    final reservations = accueil.reservationsAScanner;
    return ChauffeurScaffold(
      title: ligneDe(l10n, passage),
      subtitle: l10n.headOfQueueSubtitle(PlateText.isolate(plate)),
      board: true,
      live: accueil,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(chauffeurAccueilProvider.notifier).rafraichir(),
        child: ListView(
          padding: const EdgeInsetsDirectional.all(LLSpace.s16),
          children: [
            if (places.erreur case final erreur?) ...[
              LLBanner(
                key: const ValueKey('c4-erreur'),
                kind: LLBannerKind.error,
                message: fileErrorMessage(l10n, erreur),
                actionLabel: l10n.close,
                onAction: controller.effacerErreur,
              ),
              const SizedBox(height: LLSpace.s16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(LLSpace.s16),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SeatIndicator(
                        occupied: occupees,
                        capacity: passage.capacite,
                        size: SeatIndicatorSize.large,
                      ),
                    ),
                    const SizedBox(height: LLSpace.s24),
                    SeatStepper(
                      value: occupees,
                      max: passage.capacite,
                      valueStyle: LLText.boardCount,
                      onChanged: online
                          ? (v) => controller.modifier(v - occupees)
                          : null,
                    ),
                    const SizedBox(height: LLSpace.s16),
                    Text(
                      l10n.seatsFree(libres),
                      key: const ValueKey('c4-libres'),
                      textAlign: TextAlign.center,
                      style: LLText.title3.copyWith(color: c.ink),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LLSpace.s16),
            if (reservations.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.qr_code_2, color: c.ink),
                  const SizedBox(width: LLSpace.s12),
                  Expanded(
                    child: Text(
                      l10n.reservationsToScan(
                        reservations.length,
                        reservations.first.toLocal(),
                      ),
                      style: LLText.bodyLg.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LLSpace.s16),
            ],
            LLButton(
              driver: true,
              variant: LLButtonVariant.outline,
              icon: Icons.qr_code_scanner,
              label: l10n.scanReservation,
              onPressed: online
                  ? () => context.push(AppRoutes.chauffeurScanReservation)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
