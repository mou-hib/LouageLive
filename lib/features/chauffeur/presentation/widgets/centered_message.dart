import 'package:material_ui/material_ui.dart';

import '../../../../core/widgets/status_view.dart';

/// Centered icon + text (+ optional action), scrollable on small screens.
/// Kept for the existing chauffeur screens; it is a [StatusView] underneath.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.tone = StatusTone.neutral,
  });

  final IconData icon;
  final String text;
  final Widget? action;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) =>
      StatusView(icon: icon, tone: tone, title: text, primary: action);
}
