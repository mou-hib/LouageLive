import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Text field with its label above the box (not floating inside), error in
/// seatFull, and an eye toggle when [obscure].
///
/// [ltr] keeps the input left-to-right in Arabic too (phone, e-mail);
/// [prefixText] is a fixed, non-editable prefix such as `+216`.
class LLTextField extends StatefulWidget {
  const LLTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.helperText,
    this.prefixText,
    this.ltr = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final String? helperText;
  final String? prefixText;
  final bool ltr;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  State<LLTextField> createState() => _LLTextFieldState();
}

class _LLTextFieldState extends State<LLTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Visual label; the field itself carries it for screen readers.
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: LLText.label.copyWith(
              color: widget.enabled ? c.ink : c.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: LLSpace.s8),
        Semantics(
          label: widget.label,
          child: _maybeLtr(
            TextFormField(
              controller: widget.controller,
              enabled: widget.enabled,
              obscureText: _hidden,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onFieldSubmitted,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              style: LLText.bodyLg.copyWith(
                color: widget.enabled ? c.ink : c.inkMuted,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                helperText: widget.helperText,
                helperMaxLines: 3,
                // A prefixIcon, not prefixText: always visible, even empty.
                prefixIcon: switch (widget.prefixText) {
                  final prefix? => Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: LLSpace.s16,
                      end: LLSpace.s8,
                    ),
                    child: Text(
                      prefix,
                      style: LLText.bodyLg.copyWith(color: c.inkMuted),
                    ),
                  ),
                  null => null,
                },
                prefixIconConstraints: const BoxConstraints(),
                errorText: widget.errorText,
                errorMaxLines: 3,
                errorStyle: LLText.caption.copyWith(color: c.seatFull),
                suffixIcon: widget.obscure
                    ? IconButton(
                        tooltip: _hidden
                            ? l10n.showPassword
                            : l10n.hidePassword,
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: widget.enabled
                            ? () => setState(() => _hidden = !_hidden)
                            : null,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _maybeLtr(Widget field) => widget.ltr
      ? Directionality(textDirection: TextDirection.ltr, child: field)
      : field;
}
