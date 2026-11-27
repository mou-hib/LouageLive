import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Driver seat counter: two 112px keys, −1 (outlined) on the start side and
/// +1 (action) on the end side, the value between them. One tap = one step
/// with a haptic tick; no long-press auto-repeat (on purpose: a driver
/// counts passengers one by one).
class SeatStepper extends StatelessWidget {
  const SeatStepper({
    super.key,
    required this.value,
    this.min = 0,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;

  /// Null disables both keys.
  final ValueChanged<int>? onChanged;

  void _step(int delta) {
    HapticFeedback.lightImpact();
    onChanged!((value + delta).clamp(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final l10n = AppLocalizations.of(context);
    final canDec = onChanged != null && value > min;
    final canInc = onChanged != null && value < max;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Key(
          key: const ValueKey('seat-stepper-minus'),
          label: '−1',
          semanticsLabel: l10n.seatStepperRemove,
          filled: false,
          onTap: canDec ? () => _step(-1) : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: l10n.seatStepperValueA11y(value),
            child: ExcludeSemantics(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: LLText.boardXl.copyWith(color: c.ink),
              ),
            ),
          ),
        ),
        _Key(
          key: const ValueKey('seat-stepper-plus'),
          label: '+1',
          semanticsLabel: l10n.seatStepperAdd,
          filled: true,
          onTap: canInc ? () => _step(1) : null,
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final enabled = onTap != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LLRadius.lg),
    );
    final style = ButtonStyle(
      fixedSize: const WidgetStatePropertyAll(
        Size.square(LLSize.stepperDriver),
      ),
      minimumSize: const WidgetStatePropertyAll(
        Size.square(LLSize.stepperDriver),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(LLText.boardLg),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final text = Text(label, textDirection: TextDirection.ltr);
    final button = filled
        ? FilledButton(
            style: style.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => !enabled
                    ? c.neutralTint
                    : s.contains(WidgetState.pressed)
                    ? c.actionPressed
                    : c.action,
              ),
              foregroundColor: WidgetStatePropertyAll(
                enabled ? c.onAction : c.inkMuted,
              ),
            ),
            onPressed: onTap,
            child: text,
          )
        : OutlinedButton(
            style: style.copyWith(
              foregroundColor: WidgetStatePropertyAll(
                enabled ? c.ink : c.inkMuted,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: enabled ? c.borderStrong : c.border,
                  width: 1.5,
                ),
              ),
            ),
            onPressed: onTap,
            child: text,
          );
    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      enabled: enabled,
      onTap: onTap,
      child: button,
    );
  }
}
