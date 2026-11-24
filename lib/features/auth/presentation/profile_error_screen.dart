import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/language_switch_button.dart';
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                    onPressed: session.retry,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.logout),
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
