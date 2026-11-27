import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/language_switch_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ll_banner.dart';
import '../../../../core/widgets/ll_logo.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared frame of the auth screens (A2 login, B1 sign-up, A8 password):
/// a header (small logo + name + language pill, or the given [appBar]),
/// an optional offline banner under it, the scrollable [body], and the
/// [bottom] area (primary button + secondary link) pinned above the
/// keyboard.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.body,
    required this.bottom,
    this.appBar,
    this.offline = false,
    this.offlineMessage,
  });

  final Widget body;
  final List<Widget> bottom;

  /// Replaces the brand header (B1 uses a plain app bar with back).
  final PreferredSizeWidget? appBar;
  final bool offline;
  final String? offlineMessage;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LLSize.contentMaxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (appBar == null) const _BrandHeader(),
                if (offline && offlineMessage != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      LLSpace.s24,
                      LLSpace.s8,
                      LLSpace.s24,
                      0,
                    ),
                    child: LLBanner(
                      kind: LLBannerKind.offline,
                      message: offlineMessage!,
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      LLSpace.s24,
                      LLSpace.s24,
                      LLSpace.s24,
                      LLSpace.s16,
                    ),
                    child: body,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: BorderDirectional(top: BorderSide(color: c.border)),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      LLSpace.s24,
                      LLSpace.s16,
                      LLSpace.s24,
                      LLSpace.s16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: bottom,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        LLSpace.s24,
        LLSpace.s12,
        LLSpace.s16,
        0,
      ),
      child: Row(
        children: [
          const LLLogo(),
          const SizedBox(width: LLSpace.s12),
          Expanded(
            child: Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LLText.title3.copyWith(color: c.ink),
            ),
          ),
          const LanguageSwitchButton(pill: true),
        ],
      ),
    );
  }
}

/// "Question ? Action" on one line (wraps on small screens), the action
/// being a text button.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: LLText.body.copyWith(color: c.inkMuted)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: LLSpace.s4,
            ),
            textStyle: LLText.body.copyWith(
              fontWeight: LLText.label.fontWeight,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}
