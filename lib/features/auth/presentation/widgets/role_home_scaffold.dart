import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/language_switch_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ll_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../logic/auth_providers.dart';

/// Common layout of the role home placeholders: title, language switch,
/// logout. Feature screens will replace [body] sprint by sprint.
class RoleHomeScaffold extends ConsumerWidget {
  const RoleHomeScaffold({super.key, required this.title, this.body});

  final String title;
  final Widget? body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: LLAppBar(
        title: title,
        trailing: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: l10n.galleryOpen,
              onPressed: () => context.push(AppRoutes.devGallery),
            ),
          const LanguageSwitchButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child:
            body ??
            Padding(
              padding: const EdgeInsetsDirectional.all(LLSpace.s24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.comingSoon,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: LLSpace.s32),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.logout),
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
