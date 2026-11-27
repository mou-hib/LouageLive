import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/ll_app_bar.dart';
import '../../../core/widgets/status_view.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder routes of the chauffeur space ("Mes départs", the
/// reservation scanner of Step 3e).
class ChauffeurPlaceholderScreen extends StatelessWidget {
  const ChauffeurPlaceholderScreen({super.key, required this.title});

  /// Already translated.
  final String Function(AppLocalizations l10n) title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: LLAppBar(title: title(l10n)),
      body: SafeArea(
        child: StatusView(
          icon: Icons.hourglass_empty,
          title: l10n.comingSoonTitle,
          message: l10n.comingSoon,
        ),
      ),
    );
  }
}
