import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_banner.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/ll_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../data/change_password_error.dart';
import '../logic/auth_providers.dart';
import '../logic/auth_validators.dart';
import 'widgets/auth_layout.dart';

/// A8 — forced password change after the first sign-in with the temporary
/// password created by the admin (`profils.doit_changer_mdp`).
///
/// The router keeps the user here until it is done: no back button, no way
/// around it except signing out.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  NewPasswordRules get _rules =>
      newPasswordRules(_password.text, _confirmation.text);

  void _onChanged(String _) => setState(() => _error = null);

  Future<void> _save() async {
    if (_saving || !_rules.allPass) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // updateUser → RPC marquer_mdp_change → profile reload; the router
      // then leaves this screen for the role home.
      await ref.read(authSessionProvider).changePassword(_password.text);
    } on ChangePasswordException catch (e) {
      if (mounted) {
        setState(() => _error = changePasswordErrorMessage(l10n, e.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final online = ref.isOnline;
    final rules = _rules;
    final email = ref.watch(authRepositoryProvider).currentUserEmail;

    return PopScope(
      canPop: false,
      child: AuthLayout(
        offline: !online,
        offlineMessage: l10n.loginOfflineBanner,
        body: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.changePasswordTitle,
                style: LLText.title1.copyWith(color: c.ink),
              ),
              if (email != null) ...[
                const SizedBox(height: LLSpace.s8),
                // FSI … PDI: the address stays LTR inside Arabic text.
                Text(
                  l10n.signedInAs('\u2068$email\u2069'),
                  style: LLText.body.copyWith(color: c.inkMuted),
                ),
              ],
              const SizedBox(height: LLSpace.s24),
              LLBanner(
                kind: LLBannerKind.warn,
                message: l10n.changePasswordTempBanner,
              ),
              const SizedBox(height: LLSpace.s16),
              if (_error case final error?) ...[
                LLBanner(kind: LLBannerKind.error, message: error),
                const SizedBox(height: LLSpace.s16),
              ],
              LLTextField(
                label: l10n.newPasswordLabel,
                controller: _password,
                obscure: true,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: _onChanged,
              ),
              const SizedBox(height: LLSpace.s16),
              LLTextField(
                label: l10n.confirmShort,
                controller: _confirmation,
                obscure: true,
                enabled: !_saving,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: _onChanged,
                onFieldSubmitted: (_) => online ? _save() : null,
              ),
              const SizedBox(height: LLSpace.s16),
              PasswordChecklist(rules: rules),
            ],
          ),
        ),
        bottom: [
          LLButton(
            label: _saving ? l10n.saving : l10n.saveAndContinue,
            loading: _saving,
            onPressed: rules.allPass && online ? _save : null,
          ),
          const SizedBox(height: LLSpace.s8),
          LLButton(
            variant: LLButtonVariant.text,
            icon: Icons.logout,
            label: l10n.logout,
            onPressed: _saving
                ? null
                : () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

/// The live A8 checklist: one row per rule, success when met, seatFull
/// when not (icon changes too, colour is never the only signal).
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.rules});

  final NewPasswordRules rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Rule(
          key: const ValueKey('rule-length'),
          met: rules.longEnough,
          text: l10n.ruleMinLength(minNewPasswordLength),
        ),
        _Rule(
          key: const ValueKey('rule-digit'),
          met: rules.hasDigit,
          text: l10n.ruleDigit,
        ),
        _Rule(
          key: const ValueKey('rule-match'),
          met: rules.matches,
          text: l10n.ruleMatch,
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({super.key, required this.met, required this.text});

  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final l10n = AppLocalizations.of(context);
    final color = met ? c.success : c.seatFull;
    return Semantics(
      label: met ? l10n.ruleMetA11y(text) : l10n.ruleNotMetA11y(text),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: LLSpace.s4),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle : Icons.cancel_outlined,
              color: color,
              size: LLSize.checklistIcon,
            ),
            const SizedBox(width: LLSpace.s8),
            Expanded(
              child: Text(text, style: LLText.body.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// User-facing text of a [ChangePasswordError].
String changePasswordErrorMessage(
  AppLocalizations l10n,
  ChangePasswordError error,
) => switch (error) {
  ChangePasswordError.motDePasseFaible => l10n.changePwdErrWeak,
  ChangePasswordError.memeMotDePasse => l10n.changePwdErrSame,
  ChangePasswordError.sessionExpiree => l10n.changePwdErrSession,
  ChangePasswordError.tropDeTentatives => l10n.loginTooManyAttempts,
  ChangePasswordError.reseau => l10n.loginNetworkError,
  ChangePasswordError.inconnue => l10n.genericError,
};
