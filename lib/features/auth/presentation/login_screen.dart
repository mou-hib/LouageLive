import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_banner.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/ll_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../data/login_error.dart';
import '../logic/auth_providers.dart';
import '../logic/auth_validators.dart';
import 'widgets/auth_layout.dart';

/// A2 — sign-in. States: normal, loading (fields read-only, button
/// "Connexion…"), error (banner + field), offline (banner, button disabled).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// Kind of the last failure, to mark the field concerned.
  LoginError? _errorKind;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Keyboard "done" can fire while a request is running: no double submit.
    if (_submitting || !(ref.read(isOnlineProvider).value ?? true)) return;
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _errorKind = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text.trim(), password: _password.text);
      // Redirect is handled by the router (onAuthStateChange).
    } on LoginException catch (e) {
      if (mounted) {
        setState(() {
          _error = loginErrorMessage(l10n, e.error);
          _errorKind = e.error;
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Editing a field clears the server error it was showing.
  void _clearError(String _) {
    if (_error != null) {
      setState(() {
        _error = null;
        _errorKind = null;
      });
    }
  }

  void _forgotPassword() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.forgotPasswordInfo)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
    final online = ref.isOnline;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null;
    String? email(String? v) =>
        required(v) ?? (isValidEmail(v!) ? null : l10n.emailInvalid);

    final emailFieldError = _errorKind == LoginError.emailNonConfirme
        ? l10n.loginFieldEmailNotConfirmed
        : null;
    final passwordFieldError = _errorKind == LoginError.identifiantsInvalides
        ? l10n.loginFieldCheckCredentials
        : null;

    return Form(
      key: _formKey,
      child: AuthLayout(
        offline: !online,
        offlineMessage: l10n.loginOfflineBanner,
        body: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.login, style: LLText.title1.copyWith(color: c.ink)),
              const SizedBox(height: LLSpace.s8),
              Text(
                l10n.loginSubtitle,
                style: LLText.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: LLSpace.s24),
              if (_error case final error?) ...[
                LLBanner(kind: LLBannerKind.error, message: error),
                const SizedBox(height: LLSpace.s16),
              ],
              LLTextField(
                label: l10n.email,
                controller: _email,
                enabled: !_submitting,
                ltr: true,
                errorText: emailFieldError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: email,
                onChanged: _clearError,
              ),
              const SizedBox(height: LLSpace.s16),
              LLTextField(
                label: l10n.password,
                controller: _password,
                obscure: true,
                enabled: !_submitting,
                errorText: passwordFieldError,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: required,
                onChanged: _clearError,
                onFieldSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _submitting ? null : _forgotPassword,
                  child: Text(l10n.forgotPassword),
                ),
              ),
            ],
          ),
        ),
        bottom: [
          LLButton(
            label: _submitting ? l10n.signingIn : l10n.signIn,
            loading: _submitting,
            onPressed: online ? _submit : null,
          ),
          const SizedBox(height: LLSpace.s8),
          AuthSwitchLink(
            question: l10n.noAccountYet,
            action: l10n.createTravelerAccount,
            onPressed: _submitting ? null : () => context.go(AppRoutes.signUp),
          ),
          Text(
            l10n.staffAccountNote,
            textAlign: TextAlign.center,
            style: LLText.caption.copyWith(color: c.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// User-facing text of a [LoginError].
String loginErrorMessage(AppLocalizations l10n, LoginError error) =>
    switch (error) {
      LoginError.identifiantsInvalides => l10n.loginFailed,
      LoginError.emailNonConfirme => l10n.loginEmailNotConfirmed,
      LoginError.tropDeTentatives => l10n.loginTooManyAttempts,
      LoginError.reseau => l10n.loginNetworkError,
      LoginError.inconnue => l10n.genericError,
    };
