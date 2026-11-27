import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/language_switch_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ll_app_bar.dart';
import '../../../core/widgets/ll_banner.dart';
import '../../../core/widgets/ll_button.dart';
import '../../../core/widgets/ll_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../data/sign_up_error.dart';
import '../logic/auth_providers.dart';
import '../logic/auth_validators.dart';
import 'widgets/auth_layout.dart';

/// B1 — voyageur self sign-up. Chauffeurs and agents are created by the
/// admin; the database trigger always gives this account the `voyageur` role.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// Set when the account was created but e-mail confirmation is required.
  String? _confirmationSentTo;

  @override
  void dispose() {
    for (final c in [
      _prenom,
      _nom,
      _telephone,
      _email,
      _password,
      _confirmation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: email,
            password: _password.text,
            nom: _nom.text.trim(),
            prenom: _prenom.text.trim(),
            telephone: normalizeTunisianPhone(_telephone.text),
          );
      // connecte: the signedIn event makes the router open /voyageur.
      if (outcome == SignUpOutcome.confirmationEmail && mounted) {
        setState(() => _confirmationSentTo = email);
      }
    } on SignUpException catch (e) {
      if (mounted) setState(() => _error = signUpErrorMessage(l10n, e.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _back() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sentTo = _confirmationSentTo;
    // Reached with `go` from the login: nothing to pop, so the app bar
    // arrow and the system back both lead back to /login.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: sentTo == null
          ? _buildForm(context, l10n)
          : Scaffold(
              appBar: _appBar(l10n),
              body: SafeArea(child: _CheckEmail(email: sentTo)),
            ),
    );
  }

  LLAppBar _appBar(AppLocalizations l10n) => LLAppBar(
    title: l10n.createAccount,
    leading: IconButton(
      icon: const BackButtonIcon(),
      tooltip: l10n.back,
      onPressed: _submitting ? null : _back,
    ),
    trailing: const [LanguageSwitchButton()],
  );

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null;
    String? email(String? v) =>
        required(v) ?? (isValidEmail(v!) ? null : l10n.emailInvalid);
    String? phone(String? v) =>
        required(v) ?? (isValidTunisianPhone(v!) ? null : l10n.phoneInvalid);
    String? password(String? v) =>
        required(v) ??
        (v!.length < minPasswordLength
            ? l10n.passwordTooShort(minPasswordLength)
            : null);
    String? confirmation(String? v) =>
        required(v) ?? (v == _password.text ? null : l10n.passwordsDontMatch);
    final enabled = !_submitting;

    return Form(
      key: _formKey,
      child: AuthLayout(
        appBar: _appBar(l10n),
        body: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error case final error?) ...[
                LLBanner(kind: LLBannerKind.error, message: error),
                const SizedBox(height: LLSpace.s16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LLTextField(
                      label: l10n.firstName,
                      controller: _prenom,
                      enabled: enabled,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      validator: required,
                    ),
                  ),
                  const SizedBox(width: LLSpace.s12),
                  Expanded(
                    child: LLTextField(
                      label: l10n.lastName,
                      controller: _nom,
                      enabled: enabled,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      validator: required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LLSpace.s16),
              LLTextField(
                label: l10n.phone,
                controller: _telephone,
                enabled: enabled,
                ltr: true,
                prefixText: tunisianDialCode,
                hint: l10n.phoneHint,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ .\-]')),
                ],
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: phone,
              ),
              const SizedBox(height: LLSpace.s16),
              LLTextField(
                label: l10n.email,
                controller: _email,
                enabled: enabled,
                ltr: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: email,
              ),
              const SizedBox(height: LLSpace.s16),
              LLTextField(
                label: l10n.password,
                controller: _password,
                enabled: enabled,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: password,
              ),
              const SizedBox(height: LLSpace.s16),
              LLTextField(
                label: l10n.confirmPassword,
                controller: _confirmation,
                enabled: enabled,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: confirmation,
                onFieldSubmitted: (_) => _submitting ? null : _submit(),
              ),
            ],
          ),
        ),
        bottom: [
          LLButton(
            label: l10n.createMyAccount,
            loading: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: LLSpace.s8),
          AuthSwitchLink(
            question: l10n.alreadyHaveAccountQuestion,
            action: l10n.signIn,
            onPressed: _submitting ? null : _back,
          ),
        ],
      ),
    );
  }
}

/// Shown after sign-up when Supabase requires e-mail confirmation.
class _CheckEmail extends StatelessWidget {
  const _CheckEmail({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = LLColors.of(context);
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
                  width: LLSize.statusIcon,
                  height: LLSize.statusIcon,
                  decoration: BoxDecoration(
                    color: c.successTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: LLSize.statusGlyph,
                    color: c.success,
                  ),
                ),
              ),
              const SizedBox(height: LLSpace.s24),
              Text(
                l10n.checkEmailTitle,
                textAlign: TextAlign.center,
                style: LLText.title2.copyWith(color: c.ink),
              ),
              const SizedBox(height: LLSpace.s16),
              Text(
                l10n.checkEmailSentTo,
                textAlign: TextAlign.center,
                style: LLText.bodyLg.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: LLSpace.s4),
              // An address is always left-to-right, even inside Arabic text.
              Text(
                email,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: LLText.title3.copyWith(color: c.ink),
              ),
              const SizedBox(height: LLSpace.s16),
              Text(
                l10n.checkEmailNextStep,
                textAlign: TextAlign.center,
                style: LLText.bodyLg.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: LLSpace.s32),
              LLButton(
                label: l10n.backToLogin,
                onPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User-facing text of a [SignUpError].
String signUpErrorMessage(AppLocalizations l10n, SignUpError error) =>
    switch (error) {
      SignUpError.compteExistant => l10n.signUpEmailExists,
      SignUpError.motDePasseFaible => l10n.signUpWeakPassword(
        minPasswordLength,
      ),
      SignUpError.tropDeTentatives => l10n.signUpTooManyAttempts,
      SignUpError.reseau => l10n.loginNetworkError,
      SignUpError.inconnue => l10n.genericError,
    };
