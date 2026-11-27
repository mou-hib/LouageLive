import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

enum StatusTone { neutral, error, success }

/// Full-screen status template (empty, error, success…): toned icon, title,
/// optional message, then up to two actions stacked full width.
/// Scrolls on small screens.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    this.tone = StatusTone.neutral,
    required this.title,
    this.message,
    this.primary,
    this.secondary,
  });

  final IconData icon;
  final StatusTone tone;
  final String title;
  final String? message;

  /// Usually an LLButton (primary variant).
  final Widget? primary;

  /// Usually an LLButton (outline or text variant).
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.neutral => (c.neutralTint, c.inkMuted),
      StatusTone.error => (c.seatFullTint, c.seatFull),
      StatusTone.success => (c.successTint, c.success),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(LLSpace.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LLSize.contentMaxW),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 36, color: fg),
                ),
              ),
              const SizedBox(height: LLSpace.s24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: LLText.title2.copyWith(color: c.ink),
              ),
              if (message case final message?) ...[
                const SizedBox(height: LLSpace.s8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: LLText.bodyLg.copyWith(color: c.inkMuted),
                ),
              ],
              if (primary case final primary?) ...[
                const SizedBox(height: LLSpace.s32),
                primary,
              ],
              if (secondary case final secondary?) ...[
                const SizedBox(height: LLSpace.s12),
                secondary,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
