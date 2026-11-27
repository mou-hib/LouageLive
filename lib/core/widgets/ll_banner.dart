import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

enum LLBannerKind { offline, error, warn, ok }

/// Inline banner: always an icon + a message, optional action.
/// offline = ink panel with surface text; others use the tint pairs.
class LLBanner extends StatelessWidget {
  const LLBanner({
    super.key,
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final LLBannerKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final (bg, fg, icon) = switch (kind) {
      LLBannerKind.offline => (c.ink, c.surface, Icons.wifi_off),
      LLBannerKind.error => (c.seatFullTint, c.seatFull, Icons.error_outline),
      LLBannerKind.warn => (
        c.seatFewTint,
        c.seatFew,
        Icons.warning_amber_rounded,
      ),
      LLBannerKind.ok => (c.successTint, c.success, Icons.check_circle_outline),
    };
    final textColor = kind == LLBannerKind.offline ? fg : c.ink;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: LLSize.tapMin),
        padding: const EdgeInsetsDirectional.fromSTEB(
          LLSpace.s16,
          LLSpace.s12,
          LLSpace.s8,
          LLSpace.s12,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(LLRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: LLSpace.s12),
            Expanded(
              child: Text(
                message,
                style: LLText.body.copyWith(color: textColor),
              ),
            ),
            if (actionLabel case final label? when onAction != null) ...[
              const SizedBox(width: LLSpace.s8),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: textColor),
                onPressed: onAction,
                child: Text(label),
              ),
            ] else
              const SizedBox(width: LLSpace.s8),
          ],
        ),
      ),
    );
  }
}
