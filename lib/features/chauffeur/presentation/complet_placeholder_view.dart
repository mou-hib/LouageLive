import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/plate_text.dart';
import '../../../core/widgets/status_view.dart';
import '../../../l10n/app_localizations.dart';
import '../logic/chauffeur_providers.dart';
import 'chauffeur_home_screen.dart';
import 'widgets/chauffeur_scaffold.dart';

/// COMPLET — placeholder until C6 (departure) is built in Step 3e.
class CompletPlaceholderView extends StatelessWidget {
  const CompletPlaceholderView({super.key, required this.accueil});

  final ChauffeurAccueil accueil;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final passage = accueil.passage!;
    return ChauffeurScaffold(
      title: ligneDe(l10n, passage),
      subtitle: l10n.headOfQueueSubtitle(
        PlateText.isolate(accueil.louage!.immatriculation),
      ),
      board: true,
      live: accueil,
      body: StatusView(
        icon: Icons.check_circle_outline,
        tone: StatusTone.success,
        title: l10n.completTitle,
        message: l10n.completPlaceholder,
      ),
    );
  }
}
