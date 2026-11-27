import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/plate_text.dart';
import '../../../core/widgets/status_view.dart';
import '../../../l10n/app_localizations.dart';
import '../logic/chauffeur_providers.dart';
import 'chauffeur_home_screen.dart';
import 'widgets/chauffeur_scaffold.dart';

/// C8 — an agent removed my louage from the queue (RETIRE).
class RetireView extends ConsumerWidget {
  const RetireView({super.key, required this.accueil});

  final ChauffeurAccueil accueil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final passage = accueil.passage!;
    final plate = PlateText.isolate(accueil.louage!.immatriculation);
    final ligne = ligneDe(l10n, passage);
    final notifier = ref.read(chauffeurAccueilProvider.notifier);
    final online = ref.isOnline;
    return ChauffeurScaffold(
      title: l10n.chauffeurHomeTitle,
      accountActions: true,
      body: StatusView(
        icon: Icons.remove_circle_outline,
        tone: StatusTone.error,
        title: l10n.retireTitle,
        message: switch (passage.heureRetrait) {
          final h? => l10n.retireMessage(
            passage.stationNom,
            plate,
            ligne,
            h.toLocal(),
          ),
          null => l10n.retireMessageNoTime(passage.stationNom, plate, ligne),
        },
        primary: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoBox(icon: Icons.support_agent, text: l10n.retireTalkToAgent),
            const SizedBox(height: LLSpace.s24),
            LLButton(
              driver: true,
              icon: Icons.qr_code_scanner,
              label: l10n.joinAQueue,
              onPressed: online
                  ? () async {
                      await notifier.marquerRetraitVu();
                      if (context.mounted) await ouvrirScanner(context, ref);
                    }
                  : null,
            ),
          ],
        ),
        secondary: LLButton(
          driver: true,
          variant: LLButtonVariant.text,
          label: l10n.backToHome,
          onPressed: notifier.marquerRetraitVu,
        ),
      ),
    );
  }
}
