import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/role_home_scaffold.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      RoleHomeScaffold(title: AppLocalizations.of(context).adminHomeTitle);
}
