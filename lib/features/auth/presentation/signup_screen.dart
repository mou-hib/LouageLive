import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/language_switch_button.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../data/sign_up_error.dart';
import '../logic/auth_providers.dart';
import '../logic/auth_validators.dart';

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
  bool _hidePassword = true;
  bool _hideConfirmation = true;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sentTo = _confirmationSentTo;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
        actions: const [LanguageSwitchButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: sentTo == null
                  ? _buildForm(context, l10n)
                  : _CheckEmail(email: sentTo),
            ),
          ),
        ),
      ),
    );
  }

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

    Widget eye(bool hidden, VoidCallback toggle) => IconButton(
      icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
      tooltip: hidden ? l10n.showPassword : l10n.hidePassword,
      onPressed: toggle,
    );

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _prenom,
              decoration: InputDecoration(labelText: l10n.firstName),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nom,
              decoration: InputDecoration(labelText: l10n.lastName),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telephone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                helperText: l10n.phoneHint,
              ),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ .\-]')),
              ],
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: l10n.password,
                suffixIcon: eye(
                  _hidePassword,
                  () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: password,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmation,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                suffixIcon: eye(
                  _hideConfirmation,
                  () => setState(() => _hideConfirmation = !_hideConfirmation),
                ),
              ),
              obscureText: _hideConfirmation,
              textInputAction: TextInputAction.done,
              validator: confirmation,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Text(l10n.createAccount),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _submitting ? null : () => context.go(AppRoutes.login),
              child: Text(l10n.alreadyHaveAccount),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.checkEmailTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(l10n.checkEmailSentTo, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        // An address is always left-to-right, even inside Arabic text.
        Text(
          email,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(l10n.checkEmailNextStep, textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(l10n.backToLogin),
        ),
      ],
    );
  }
}

/// User-facing text of a [SignUpError].
String signUpErrorMessage(AppLocalizations l10n, SignUpError error) =>
    switch (error) {
      SignUpError.compteExistant => l10n.signUpEmailExists,
      SignUpError.motDePasseFaible => l10n.signUpWeakPassword,
      SignUpError.tropDeTentatives => l10n.signUpTooManyAttempts,
      SignUpError.reseau => l10n.loginNetworkError,
      SignUpError.inconnue => l10n.genericError,
    };
