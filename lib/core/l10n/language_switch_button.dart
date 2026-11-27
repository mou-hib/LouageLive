import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'locale_provider.dart';

/// Switches French <-> Arabic.
///
/// Default: an app bar icon. [pill]: an outlined pill with the icon and the
/// name of the other language (header of the auth screens).
class LanguageSwitchButton extends ConsumerWidget {
  const LanguageSwitchButton({super.key, this.pill = false});

  final bool pill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void toggle() => ref.read(localeProvider.notifier).toggle();
    if (!pill) {
      return IconButton(
        icon: const Icon(Icons.translate),
        tooltip: l10n.changeLanguage,
        onPressed: toggle,
      );
    }
    final c = LLColors.of(context);
    return Tooltip(
      message: l10n.changeLanguage,
      child: OutlinedButton.icon(
        onPressed: toggle,
        icon: const Icon(Icons.translate, size: LLSize.checklistIcon),
        label: Text(l10n.otherLanguageName),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(LLSize.tapMin, LLSize.tapMin),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: LLSpace.s16,
          ),
          shape: const StadiumBorder(),
          side: BorderSide(color: c.border, width: 1.5),
          foregroundColor: c.ink,
          textStyle: LLText.caption,
        ),
      ),
    );
  }
}
