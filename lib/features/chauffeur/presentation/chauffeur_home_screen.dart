import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/role_home_scaffold.dart';
import '../data/louage.dart';
import '../data/passage.dart';
import '../logic/chauffeur_providers.dart';
import 'file_error_message.dart';
import '../../../core/widgets/status_view.dart';
import 'widgets/centered_message.dart';

/// C1 — chauffeur home: my louage, and either my current queue or the
/// button to join one by scanning the station QR code.
class ChauffeurHomeScreen extends ConsumerWidget {
  const ChauffeurHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final accueil = ref.watch(chauffeurAccueilProvider);
    return RoleHomeScaffold(
      title: l10n.chauffeurHomeTitle,
      body: switch (accueil) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(chauffeurAccueilProvider.future),
          child: _Accueil(accueil: value),
        ),
        AsyncError(:final error) => CenteredMessage(
          icon: Icons.error_outline,
          tone: StatusTone.error,
          text: fileErrorMessage(l10n, fileErrorOf(error)),
          action: FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
            onPressed: () => ref.invalidate(chauffeurAccueilProvider),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Accueil extends ConsumerWidget {
  const _Accueil({required this.accueil});

  final ChauffeurAccueil accueil;

  Future<void> _scanner(BuildContext context, WidgetRef ref) async {
    final joined = await context.push<bool>(AppRoutes.chauffeurScanner);
    if (!context.mounted) return;
    ref.invalidate(chauffeurAccueilProvider);
    if (joined ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).joinedQueue)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final louage = accueil.louage;
    final passage = accueil.passage;
    if (louage == null) {
      return CenteredMessage(
        icon: Icons.no_transfer_outlined,
        text: l10n.chauffeurNoLouage,
      );
    }
    // A ListView so pull-to-refresh works even when the content is short.
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      children: [
        _LouageCard(louage: louage),
        const SizedBox(height: AppSpacing.lg),
        if (passage != null)
          _PassageCard(passage: passage)
        else
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.scanStationQr),
            onPressed: () => _scanner(context, ref),
          ),
      ],
    );
  }
}

class _LouageCard extends StatelessWidget {
  const _LouageCard({required this.louage});

  final Louage louage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.airport_shuttle),
        // A plate number reads left-to-right, also in Arabic.
        title: Text(
          louage.immatriculation,
          style: text.titleLarge,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
        ),
        subtitle: Text(l10n.louageCapacite(louage.capacite)),
      ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  const _PassageCard({required this.passage});

  final Passage passage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.format_list_numbered,
          color: scheme.onPrimaryContainer,
        ),
        title: Text(
          l10n.chauffeurInQueue(passage.stationNom, passage.villeArrivee),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
