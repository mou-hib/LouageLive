import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/language_switch_button.dart';
import '../../../../core/network/connectivity.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../../core/widgets/ll_app_bar.dart';
import '../../../../core/widgets/ll_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/logic/auth_providers.dart';
import '../../logic/chauffeur_providers.dart';

/// Layout of every chauffeur home state: app bar, the offline banner right
/// under it, then [body]. No bottom tab bar for the chauffeur.
///
/// - [live]: shows the LiveBadge of that snapshot (C3, C4, complet).
/// - [accountActions]: debug gallery + logout (C1, C8, loading, error).
class ChauffeurScaffold extends ConsumerWidget {
  const ChauffeurScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.board = false,
    this.live,
    this.accountActions = false,
    required this.body,
  });

  final String title;
  final String? subtitle;
  final bool board;
  final ChauffeurAccueil? live;
  final bool accountActions;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final online = ref.isOnline;
    return Scaffold(
      appBar: LLAppBar(
        title: title,
        subtitle: subtitle,
        board: board,
        trailing: [
          if (live case final live?)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: LLSpace.s4),
              child: Center(
                // Leaves room for the line name on a small phone.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.32,
                  ),
                  child: ChauffeurLiveBadge(accueil: live),
                ),
              ),
            ),
          if (accountActions && kDebugMode)
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: l10n.galleryOpen,
              onPressed: () => context.push(AppRoutes.devGallery),
            ),
          const LanguageSwitchButton(),
          if (accountActions)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.logout,
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!online)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  LLSpace.s16,
                  LLSpace.s8,
                  LLSpace.s16,
                  0,
                ),
                child: LLBanner(
                  kind: LLBannerKind.offline,
                  message: l10n.chauffeurOfflineBanner,
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// [LiveBadge] for a chauffeur snapshot: live while online, subscribed and
/// heard from in the last [liveStaleAfter]; re-evaluated every second so it
/// goes stale on its own when events stop.
class ChauffeurLiveBadge extends ConsumerStatefulWidget {
  const ChauffeurLiveBadge({super.key, required this.accueil});

  final ChauffeurAccueil accueil;

  @override
  ConsumerState<ChauffeurLiveBadge> createState() => _ChauffeurLiveBadgeState();
}

class _ChauffeurLiveBadgeState extends ConsumerState<ChauffeurLiveBadge> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.isOnline && widget.accueil.enDirect(DateTime.now());
    return LiveBadge(connected: live, lastUpdate: widget.accueil.dernierSigne);
  }
}

/// Neutral information box (icon + bodyLg text).
class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(LLSpace.s16),
      decoration: BoxDecoration(
        color: c.neutralTint,
        borderRadius: BorderRadius.circular(LLRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.ink),
          const SizedBox(width: LLSpace.s12),
          Expanded(
            child: Text(text, style: LLText.bodyLg.copyWith(color: c.ink)),
          ),
        ],
      ),
    );
  }
}
