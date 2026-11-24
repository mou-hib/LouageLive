import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'locale_provider.dart';

/// App bar action that switches French <-> Arabic.
class LanguageSwitchButton extends ConsumerWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.translate),
      tooltip: AppLocalizations.of(context).changeLanguage,
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
    );
  }
}
