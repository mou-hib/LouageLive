import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/role_home_scaffold.dart';

class ChauffeurHomeScreen extends StatelessWidget {
  const ChauffeurHomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      RoleHomeScaffold(title: AppLocalizations.of(context).chauffeurHomeTitle);
}
