import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum LLButtonVariant { primary, secondary, outline, text, destructive }

/// The app button. [driver] = the large one-hand variant used by chauffeurs
/// (72px high, 20px label, 24px radius).
///
/// While [loading], the button keeps its width, shows a spinner next to the
/// label and ignores taps.
class LLButton extends StatefulWidget {
  const LLButton({
    super.key,
    this.variant = LLButtonVariant.primary,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.driver = false,
    this.icon,
  });

  final LLButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool driver;
  final IconData? icon;

  @override
  State<LLButton> createState() => _LLButtonState();
}

class _LLButtonState extends State<LLButton> {
  bool _pressed = false;

  bool get _interactive => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _handlePressed() {
    if (_interactive) widget.onPressed!();
  }

  @override
  void didUpdateWidget(LLButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) _pressed = false;
  }

  ButtonStyle _style(LLColors c) {
    final height = widget.driver ? LLSize.buttonHDriver : LLSize.buttonH;
    final radius = widget.driver ? LLRadius.lg : LLRadius.md;
    final textStyle = widget.driver
        ? LLText.label.copyWith(fontSize: 20, height: 24 / 20)
        : LLText.label;
    final base = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(LLSize.tapMin, height)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      textStyle: WidgetStatePropertyAll(textStyle),
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(horizontal: LLSpace.s24),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    WidgetStateProperty<Color> fill(Color normal, Color pressed) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) && !widget.loading
              ? c.neutralTint
              : s.contains(WidgetState.pressed)
              ? pressed
              : normal,
        );
    WidgetStateProperty<Color> fg(Color normal) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) && !widget.loading
              ? c.inkMuted
              : normal,
        );
    return switch (widget.variant) {
      LLButtonVariant.primary => base.copyWith(
        backgroundColor: fill(c.action, c.actionPressed),
        foregroundColor: fg(c.onAction),
      ),
      LLButtonVariant.secondary => base.copyWith(
        backgroundColor: fill(c.neutralTint, c.border),
        foregroundColor: fg(c.ink),
      ),
      LLButtonVariant.destructive => base.copyWith(
        backgroundColor: fill(LLColors.destructive, LLColors.destructive),
        foregroundColor: fg(LLColors.onDestructive),
      ),
      LLButtonVariant.outline => base.copyWith(
        foregroundColor: fg(c.ink),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.disabled) && !widget.loading
                ? c.border
                : c.borderStrong,
            width: 1.5,
          ),
        ),
      ),
      LLButtonVariant.text => base.copyWith(foregroundColor: fg(c.ink)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = LLColors.of(context);
    final style = _style(c);
    final onPressed = widget.onPressed == null ? null : _handlePressed;
    // While loading the button stays "enabled" (normal colours), taps are
    // dropped by IgnorePointer and by _handlePressed for the keyboard.
    final child = _Content(
      label: widget.label,
      icon: widget.icon,
      loading: widget.loading,
      iconSize: widget.driver ? 28 : 20,
    );
    final button = switch (widget.variant) {
      LLButtonVariant.outline => OutlinedButton(
        style: style,
        onPressed: onPressed,
        child: child,
      ),
      LLButtonVariant.text => TextButton(
        style: style,
        onPressed: onPressed,
        child: child,
      ),
      _ => FilledButton(style: style, onPressed: onPressed, child: child),
    };
    return Semantics(
      label: widget.loading ? AppLocalizations.of(context).loading : null,
      child: IgnorePointer(
        ignoring: widget.loading,
        child: Listener(
          onPointerDown: _interactive ? (_) => _setPressed(true) : null,
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: LLMotion.tap(context),
            curve: LLMotion.standard,
            child: button,
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.icon,
    required this.loading,
    required this.iconSize,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final double iconSize;

  Widget _row(Widget? leading) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (leading != null) ...[leading, const SizedBox(width: LLSpace.s8)],
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final iconWidget = icon == null ? null : Icon(icon, size: iconSize);
    final normal = _row(iconWidget);
    if (!loading) return normal;
    final color = DefaultTextStyle.of(context).style.color;
    // The idle content (invisible) sets the size, so the width never jumps;
    // the spinner + label sit on top, scaled down if they would not fit.
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: normal,
        ),
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _row(
              SizedBox.square(
                dimension: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
