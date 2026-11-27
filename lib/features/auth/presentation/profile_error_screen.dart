import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/language_switch_button.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/status_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/profil_exception.dart';
import '../logic/auth_providers.dart';

/// Shown when the user is signed in but their profile (role) could not be
/// loaded. No default role is assumed: the user retries or signs out.
class ProfileErrorScreen extends ConsumerWidget {
  const ProfileErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);
    final message = session.error is ProfilErreurReseau
        ? l10n.profileErrorNetwork
        : l10n.profileErrorGeneric;

    return Scaffold(
      appBar: AppBar(actions: const [LanguageSwitchButton()]),
      body: SafeArea(
        child: StatusView(
          icon: Icons.error_outline,
          tone: StatusTone.error,
          title: l10n.profileErrorTitle,
          message: message,
          primary: LLButton(
            icon: Icons.refresh,
            label: l10n.retry,
            onPressed: session.retry,
          ),
          secondary: LLButton(
            variant: LLButtonVariant.outline,
            icon: Icons.logout,
            label: l10n.logout,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ),
      ),
    );
  }
}
